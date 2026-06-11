import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.image,
    required this.source,
    required this.category,
    required this.city,
    required this.twoLineSummary,
    required this.fiftyWordSummary,
    required this.voiceScript,
    required this.articleUrl,
    required this.publishedAt,
    this.isBreaking = false,
  });

  final String id;
  final String title;
  final String image;
  final String source;
  final String category;
  final String city;
  final String twoLineSummary;
  final String fiftyWordSummary;
  final String voiceScript;
  final String articleUrl;
  final DateTime publishedAt;
  final bool isBreaking;

  factory NewsArticle.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NewsArticle(
      id: doc.id,
      title: data['title'] as String? ?? '',
      image: data['image'] as String? ?? '',
      source: data['source'] as String? ?? '',
      category: data['category'] as String? ?? 'Local',
      city: data['city'] as String? ?? 'Moradabad',
      twoLineSummary: data['summary'] as String? ?? '',
      fiftyWordSummary: data['summary_50_words'] as String? ?? '',
      voiceScript: data['voice_script'] as String? ?? '',
      articleUrl: data['article_url'] as String? ?? '',
      publishedAt: (data['published_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isBreaking: data['is_breaking'] as bool? ?? false,
    );
  }
}
