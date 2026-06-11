import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moradabad_news/features/home/domain/news_article.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository(FirebaseFirestore.instance);
});

final headlinesProvider = StreamProvider<List<NewsArticle>>((ref) {
  return ref.watch(newsRepositoryProvider).watchTopHeadlines();
});

final breakingNewsProvider = StreamProvider<List<NewsArticle>>((ref) {
  return ref.watch(newsRepositoryProvider).watchBreakingNews();
});

final categoryNewsProvider =
    StreamProvider.family<List<NewsArticle>, String>((ref, category) {
  return ref.watch(newsRepositoryProvider).watchByCategory(category);
});

class NewsRepository {
  NewsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _news => _db.collection('news');

  Stream<List<NewsArticle>> watchTopHeadlines() {
    return _news
        .orderBy('published_at', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(NewsArticle.fromFirestore).toList());
  }

  Stream<List<NewsArticle>> watchBreakingNews() {
    return _news
        .where('is_breaking', isEqualTo: true)
        .orderBy('published_at', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(NewsArticle.fromFirestore).toList());
  }

  Stream<List<NewsArticle>> watchByCategory(String category) {
    return _news
        .where('category', isEqualTo: category)
        .orderBy('published_at', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(NewsArticle.fromFirestore).toList());
  }

  Future<void> deleteArticle(String id) => _news.doc(id).delete();
}
