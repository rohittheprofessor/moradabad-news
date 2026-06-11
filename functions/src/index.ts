import { createHash } from 'crypto';
import * as admin from 'firebase-admin';
import { onCall, onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger, setGlobalOptions } from 'firebase-functions/v2';
import OpenAI from 'openai';

setGlobalOptions({ region: 'asia-south1', memory: '512MiB', timeoutSeconds: 300 });

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

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

const cityPatterns: Array<[string, RegExp]> = [
  ['Moradabad', /moradabad|मुरादाबाद/i],
  ['Rampur', /rampur|रामपुर/i],
  ['Sambhal', /sambhal|संभल/i],
  ['Amroha', /amroha|अमरोहा/i],
  ['Bareilly', /bareilly|बरेली/i],
];

const categoryPatterns: Array<[string, RegExp]> = [
  ['Crime', /crime|police|fir|murder|theft|arrest|अपराध|पुलिस|हत्या|चोरी|गिरफ्तार/i],
  ['Education', /school|college|exam|university|education|स्कूल|कॉलेज|परीक्षा|शिक्षा/i],
  ['Politics', /election|bjp|congress|sp|politics|minister|चुनाव|राजनीति|मंत्री/i],
  ['Sports', /sports|cricket|football|खेल|क्रिकेट|फुटबॉल/i],
  ['Weather', /weather|rain|temperature|मौसम|बारिश|तापमान/i],
  ['Jobs', /job|vacancy|recruitment|नौकरी|भर्ती|रोजगार/i],
];

type RawArticle = {
  title: string;
  description?: string;
  content?: string;
  url: string;
  image?: string;
  source: string;
  publishedAt: string;
};

type Summary = {
  twoLine: string;
  fiftyWords: string;
  voiceScript: string;
};

export const fetchNewsHourly = onSchedule(
  { schedule: 'every 60 minutes', timeZone: 'Asia/Kolkata' },
  async () => {
    const articles = await fetchAllNews();
    let saved = 0;

    for (const article of articles) {
      if (!matchesLocalKeyword(article)) continue;
      const id = articleId(article.url);
      const ref = db.collection('news').doc(id);
      if ((await ref.get()).exists) continue;

      const summary = await summarizeArticle(article);
      await ref.set({
        id,
        title: article.title,
        image: article.image ?? '',
        source: article.source,
        category: detectCategory(article),
        city: detectCity(article),
        summary: summary.twoLine,
        summary_50_words: summary.fiftyWords,
        voice_script: summary.voiceScript,
        article_url: article.url,
        published_at: admin.firestore.Timestamp.fromDate(new Date(article.publishedAt)),
        is_breaking: isBreaking(article),
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      saved++;
    }

    logger.info(`Fetched ${articles.length} articles, saved ${saved}`);
  },
);

export const sendDailyDigest = onSchedule(
  { schedule: '0 8 * * *', timeZone: 'Asia/Kolkata' },
  async () => {
    const snapshot = await db.collection('news').orderBy('published_at', 'desc').limit(10).get();
    const titles = snapshot.docs.map((doc, index) => `${index + 1}. ${doc.data().title}`).join('\n');

    await messaging.send({
      topic: 'daily-digest',
      notification: {
        title: 'आज की मुरादाबाद खबरें',
        body: snapshot.docs[0]?.data().summary ?? 'सुबह 8 बजे का दैनिक समाचार सारांश तैयार है।',
      },
      data: { type: 'daily_digest' },
    });

    await db.collection('notifications').add({
      title: 'Daily digest sent',
      message: titles,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      topic: 'daily-digest',
    });
  },
);

export const sendBreakingNotification = onCall(async (request) => {
  await assertAdmin(request.auth?.uid);
  const { title, message, topic = 'breaking-news' } = request.data as {
    title: string;
    message: string;
    topic?: string;
  };

  await messaging.send({
    topic,
    notification: { title, body: message },
    data: { type: 'admin_notification' },
  });

  await db.collection('notifications').add({
    title,
    message,
    topic,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true };
});

export const generateDailyVideoScript = onRequest(async (request, response) => {
  if (request.method !== 'GET' && request.method !== 'POST') {
    response.status(405).send('Method not allowed');
    return;
  }

  const snapshot = await db.collection('news').orderBy('published_at', 'desc').limit(10).get();
  const items = snapshot.docs.map((doc, index) => `${index + 1}. ${doc.data().title}: ${doc.data().summary_50_words}`);
  const script = await generateVideoScript(items);
  const id = new Date().toISOString().slice(0, 10);

  await db.collection('daily_video_scripts').doc(id).set({
    id,
    script,
    article_ids: snapshot.docs.map((doc) => doc.id),
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  response.json({ id, script });
});

async function fetchAllNews(): Promise<RawArticle[]> {
  const [newsApi, gnews] = await Promise.all([fetchNewsApi(), fetchGNews()]);
  const byUrl = new Map<string, RawArticle>();
  for (const article of [...newsApi, ...gnews]) {
    if (article.url) byUrl.set(article.url, article);
  }
  return [...byUrl.values()];
}

async function fetchNewsApi(): Promise<RawArticle[]> {
  const apiKey = process.env.NEWSAPI_KEY;
  if (!apiKey) return [];
  const query = encodeURIComponent(keywords.join(' OR '));
  const url = `https://newsapi.org/v2/everything?q=${query}&sortBy=publishedAt&pageSize=50&apiKey=${apiKey}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`NewsAPI failed ${res.status}`);
  const body = (await res.json()) as { articles?: Array<Record<string, unknown>> };
  return (body.articles ?? []).map((item) => ({
    title: String(item.title ?? ''),
    description: String(item.description ?? ''),
    content: String(item.content ?? ''),
    url: String(item.url ?? ''),
    image: String(item.urlToImage ?? ''),
    source: String((item.source as { name?: string } | undefined)?.name ?? 'NewsAPI'),
    publishedAt: String(item.publishedAt ?? new Date().toISOString()),
  }));
}

async function fetchGNews(): Promise<RawArticle[]> {
  const apiKey = process.env.GNEWS_API_KEY;
  if (!apiKey) return [];
  const query = encodeURIComponent(keywords.join(' OR '));
  const url = `https://gnews.io/api/v4/search?q=${query}&lang=hi&country=in&max=50&apikey=${apiKey}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`GNews failed ${res.status}`);
  const body = (await res.json()) as { articles?: Array<Record<string, unknown>> };
  return (body.articles ?? []).map((item) => ({
    title: String(item.title ?? ''),
    description: String(item.description ?? ''),
    content: String(item.content ?? ''),
    url: String(item.url ?? ''),
    image: String(item.image ?? ''),
    source: String((item.source as { name?: string } | undefined)?.name ?? 'GNews'),
    publishedAt: String(item.publishedAt ?? new Date().toISOString()),
  }));
}

async function summarizeArticle(article: RawArticle): Promise<Summary> {
  const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  const model = process.env.OPENAI_MODEL ?? 'gpt-4o-mini';
  const content = [article.title, article.description, article.content].filter(Boolean).join('\n');

  const completion = await client.chat.completions.create({
    model,
    response_format: { type: 'json_object' },
    messages: [
      {
        role: 'system',
        content:
          'You are a careful Hindi local-news editor. Return JSON with keys twoLine, fiftyWords, voiceScript. Keep facts grounded only in the supplied article text.',
      },
      {
        role: 'user',
        content:
          `Article:\n${content}\n\nCreate: 1) 2-line Hindi summary, 2) 50-word Hindi summary, 3) 1-minute Hindi voice-news script.`,
      },
    ],
  });

  const raw = completion.choices[0]?.message.content ?? '{}';
  const parsed = JSON.parse(raw) as Partial<Summary>;
  return {
    twoLine: parsed.twoLine ?? article.description ?? article.title,
    fiftyWords: parsed.fiftyWords ?? parsed.twoLine ?? article.description ?? article.title,
    voiceScript: parsed.voiceScript ?? parsed.fiftyWords ?? parsed.twoLine ?? article.title,
  };
}

async function generateVideoScript(items: string[]): Promise<string> {
  const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  const model = process.env.OPENAI_MODEL ?? 'gpt-4o-mini';
  const completion = await client.chat.completions.create({
    model,
    messages: [
      {
        role: 'system',
        content: 'Write a natural Hindi news-anchor script for a short local news video.',
      },
      {
        role: 'user',
        content: `Top 10 stories:\n${items.join('\n')}\n\nCreate a 3-4 minute Hindi video script with intro and outro.`,
      },
    ],
  });
  return completion.choices[0]?.message.content ?? '';
}

function articleId(url: string): string {
  return createHash('sha256').update(url).digest('hex').slice(0, 32);
}

function matchesLocalKeyword(article: RawArticle): boolean {
  const text = `${article.title} ${article.description ?? ''} ${article.content ?? ''}`;
  return keywords.some((keyword) => text.toLowerCase().includes(keyword.toLowerCase()));
}

function detectCity(article: RawArticle): string {
  const text = `${article.title} ${article.description ?? ''} ${article.content ?? ''}`;
  return cityPatterns.find(([, pattern]) => pattern.test(text))?.[0] ?? 'Moradabad';
}

function detectCategory(article: RawArticle): string {
  const text = `${article.title} ${article.description ?? ''} ${article.content ?? ''}`;
  return categoryPatterns.find(([, pattern]) => pattern.test(text))?.[0] ?? 'Local';
}

function isBreaking(article: RawArticle): boolean {
  const text = `${article.title} ${article.description ?? ''}`;
  return /breaking|ताजा|ब्रेकिंग|alert|अलर्ट/i.test(text);
}

async function assertAdmin(uid?: string): Promise<void> {
  if (!uid) throw new Error('Authentication required');
  const adminDoc = await db.collection('admins').doc(uid).get();
  if (!adminDoc.exists) throw new Error('Admin access required');
}
