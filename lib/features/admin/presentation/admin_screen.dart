import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moradabad_news/features/admin/presentation/admin_service.dart';
import 'package:moradabad_news/features/home/data/news_repository.dart';
import 'package:moradabad_news/features/home/presentation/news_card.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(headlinesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: articles.when(
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _Metric(label: 'Articles', value: '${items.length}'),
                const SizedBox(width: 12),
                _Metric(label: 'Breaking', value: '${items.where((item) => item.isBreaking).length}'),
              ],
            ),
            const SizedBox(height: 16),
            for (final item in items) ...[
              NewsCard(article: item),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('डुप्लिकेट/हटाएं'),
                  onPressed: () => ref.read(newsRepositoryProvider).deleteArticle(item.id),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _sendNotification(context, ref),
        icon: const Icon(Icons.notifications_active_outlined),
        label: const Text('Notification'),
      ),
    );
  }

  Future<void> _sendNotification(BuildContext context, WidgetRef ref) async {
    await ref.read(adminServiceProvider).sendNotification(
          title: 'Moradabad News',
          message: 'नई लोकल खबरें पढ़ें।',
          topic: 'breaking-news',
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification भेज दिया गया।')),
      );
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
