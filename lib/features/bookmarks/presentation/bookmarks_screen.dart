import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moradabad_news/features/bookmarks/presentation/bookmarks_controller.dart';
import 'package:moradabad_news/features/home/domain/news_article.dart';
import 'package:moradabad_news/features/home/presentation/news_card.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkIdsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('बुकमार्क')),
      body: bookmarks.when(
        data: (ids) {
          if (ids.isEmpty) return const Center(child: Text('अभी कोई बुकमार्क नहीं है।'));
          return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('news')
                .where(FieldPath.documentId, whereIn: ids.take(30).toList())
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final articles = snapshot.data!.docs.map(NewsArticle.fromFirestore).toList();
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: articles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, index) => NewsCard(article: articles[index]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
