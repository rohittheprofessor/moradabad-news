import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moradabad_news/features/bookmarks/presentation/bookmarks_controller.dart';
import 'package:moradabad_news/features/home/domain/news_article.dart';
import 'package:moradabad_news/features/home/presentation/news_card.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleScreen extends ConsumerWidget {
  const ArticleScreen({required this.article, super.key});

  final NewsArticle article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkIdsProvider).valueOrNull ?? <String>{};
    final bookmarked = bookmarks.contains(article.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(article.city),
        actions: [
          IconButton(
            tooltip: 'शेयर',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share('${article.title}\n${article.articleUrl}'),
          ),
          IconButton(
            tooltip: 'बुकमार्क',
            icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_outline),
            onPressed: () => ref.read(bookmarkControllerProvider).toggle(article.id, bookmarked),
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: NewsImage(url: article.image)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text(
                  '${article.source} • ${DateFormat('d MMMM y, h:mm a', 'hi').format(article.publishedAt)}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 20),
                _Section(title: 'AI सारांश', body: article.fiftyWordSummary.isNotEmpty ? article.fiftyWordSummary : article.twoLineSummary),
                const SizedBox(height: 18),
                _Section(title: '1 मिनट वॉयस स्क्रिप्ट', body: article.voiceScript),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('पूरी खबर पढ़ें'),
                  onPressed: () => launchUrl(Uri.parse(article.articleUrl), mode: LaunchMode.externalApplication),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(body.isEmpty ? 'सारांश तैयार हो रहा है।' : body, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
