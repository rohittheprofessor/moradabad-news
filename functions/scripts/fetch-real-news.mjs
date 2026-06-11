import { createHash } from 'crypto';
import { existsSync, readFileSync } from 'fs';
import admin from 'firebase-admin';
import OpenAI from 'openai';

loadEnv();

const serviceAccountPath =
  process.env.SERVICE_ACCOUNT_PATH || process.env.GOOGLE_APPLICATION_CREDENTIALS;

if (!serviceAccountPath || !existsSync(serviceAccountPath)) {
  console.error('Missing SERVICE_ACCOUNT_PATH in functions/.env');
  console.error('Create a Firebase service account key and set SERVICE_ACCOUNT_PATH=C:\\path\\to\\key.json');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(readFileSync(serviceAccountPath, 'utf8'))),
});

const db = admin.firestore();
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

const keywords = [
  'Moradabad',
  'मुरादाबाद',
  'Rampur',
  'रामपुर',
  'Sambhal',
  'संभल',
  'Amroha',
  'अमरोहा',
  'Bareilly',
  'बरेली',
];

const cityPatterns = [
  ['Moradabad', /moradabad|मुरादाबाद/i],
  ['Rampur', /rampur|रामपुर/i],
  ['Sambhal', /sambhal|संभल/i],
  ['Amroha', /amroha|अमरोहा/i],
  ['Bareilly', /bareilly|बरेली/i],
];

const categoryPatterns = [
  ['Crime', /crime|police|fir|murder|theft|arrest|अपराध|पुलिस|हत्या|चोरी|गिरफ्तार/i],
  ['Education', /school|college|exam|university|education|स्कूल|कॉलेज|परीक्षा|शिक्षा/i],
  ['Politics', /election|bjp|congress|sp|politics|minister|चुनाव|राजनीति|मंत्री/i],
  ['Sports', /sports|cricket|football|खेल|क्रिकेट|फुटबॉल/i],
  ['Weather', /weather|rain|temperature|मौसम|बारिश|तापमान/i],
  ['Jobs', /job|vacancy|recruitment|नौकरी|भर्ती|रोजगार/i],
];

const articles = await fetchAllNews();
let saved = 0;

for (const article of articles.slice(0, 30)) {
  if (!matchesLocalKeyword(article)) continue;
  const id = createHash('sha256').update(article.url).digest('hex').slice(0, 32);
  const ref = db.collection('news').doc(id);
  if ((await ref.get()).exists) continue;

  const summary = await summarize(article);
  await ref.set({
    id,
    title: article.title,
    image: article.image || '',
    source: article.source,
    category: detect(categoryPatterns, article, 'Local'),
    city: detect(cityPatterns, article, 'Moradabad'),
    summary: summary.twoLine,
    summary_50_words: summary.fiftyWords,
    voice_script: summary.voiceScript,
    article_url: article.url,
    published_at: admin.firestore.Timestamp.fromDate(new Date(article.publishedAt)),
    is_breaking: /breaking|ताजा|ब्रेकिंग|alert|अलर्ट/i.test(article.title),
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  saved += 1;
  console.log(`Saved: ${article.title}`);
}

console.log(`Done. Found ${articles.length}, saved ${saved} new articles.`);

async function fetchAllNews() {
  const results = await Promise.all([fetchGNews(), fetchNewsApi()]);
  const byUrl = new Map();
  for (const article of results.flat()) {
    if (article.url) byUrl.set(article.url, article);
  }
  return [...byUrl.values()];
}

async function fetchGNews() {
  if (!process.env.GNEWS_API_KEY) return [];
  const query = encodeURIComponent(keywords.join(' OR '));
  const url = `https://gnews.io/api/v4/search?q=${query}&lang=hi&country=in&max=50&apikey=${process.env.GNEWS_API_KEY}`;
  const response = await fetch(url);
  if (!response.ok) throw new Error(`GNews failed ${response.status}`);
  const body = await response.json();
  return (body.articles || []).map((item) => ({
    title: item.title || '',
    description: item.description || '',
    content: item.content || '',
    url: item.url || '',
    image: item.image || '',
    source: item.source?.name || 'GNews',
    publishedAt: item.publishedAt || new Date().toISOString(),
  }));
}

async function fetchNewsApi() {
  if (!process.env.NEWSAPI_KEY) return [];
  const query = encodeURIComponent(keywords.join(' OR '));
  const url = `https://newsapi.org/v2/everything?q=${query}&sortBy=publishedAt&pageSize=50&apiKey=${process.env.NEWSAPI_KEY}`;
  const response = await fetch(url);
  if (!response.ok) throw new Error(`NewsAPI failed ${response.status}`);
  const body = await response.json();
  return (body.articles || []).map((item) => ({
    title: item.title || '',
    description: item.description || '',
    content: item.content || '',
    url: item.url || '',
    image: item.urlToImage || '',
    source: item.source?.name || 'NewsAPI',
    publishedAt: item.publishedAt || new Date().toISOString(),
  }));
}

async function summarize(article) {
  if (!process.env.OPENAI_API_KEY) {
    const fallback = article.description || article.title;
    return { twoLine: fallback, fiftyWords: fallback, voiceScript: fallback };
  }

  try {
    const completion = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: 'Return JSON with keys twoLine, fiftyWords, voiceScript. Write in Hindi and stay factual.',
        },
        {
          role: 'user',
          content: `${article.title}\n${article.description || ''}\n${article.content || ''}`,
        },
      ],
    });
    const parsed = JSON.parse(completion.choices[0]?.message?.content || '{}');
    const fallback = article.description || article.title;
    return {
      twoLine: parsed.twoLine || fallback,
      fiftyWords: parsed.fiftyWords || parsed.twoLine || fallback,
      voiceScript: parsed.voiceScript || parsed.fiftyWords || fallback,
    };
  } catch (error) {
    const fallback = article.description || article.title;
    console.warn(`OpenAI summary skipped: ${error?.code || error?.message || error}`);
    return {
      twoLine: fallback,
      fiftyWords: fallback,
      voiceScript: `नमस्कार, आज की खबर: ${article.title}. ${fallback}`,
    };
  }
}

function matchesLocalKeyword(article) {
  const text = `${article.title} ${article.description || ''} ${article.content || ''}`;
  return keywords.some((keyword) => text.toLowerCase().includes(keyword.toLowerCase()));
}

function detect(patterns, article, fallback) {
  const text = `${article.title} ${article.description || ''} ${article.content || ''}`;
  return patterns.find(([, pattern]) => pattern.test(text))?.[0] || fallback;
}

function loadEnv() {
  const envPath = new URL('../.env', import.meta.url);
  if (!existsSync(envPath)) return;
  for (const line of readFileSync(envPath, 'utf8').split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const index = trimmed.indexOf('=');
    if (index === -1) continue;
    const key = trimmed.slice(0, index);
    const value = trimmed.slice(index + 1);
    process.env[key] = value;
  }
}
