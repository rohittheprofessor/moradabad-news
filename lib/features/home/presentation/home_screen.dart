import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moradabad_news/core/config/app_config.dart';
import 'package:moradabad_news/core/routing/app_router.dart';
import 'package:moradabad_news/core/theme/theme_controller.dart';
import 'package:moradabad_news/features/auth/data/auth_repository.dart';
import 'package:moradabad_news/features/home/data/news_repository.dart';
import 'package:moradabad_news/features/home/domain/news_article.dart';
import 'package:moradabad_news/features/home/presentation/news_card.dart';
import 'package:moradabad_news/features/language/presentation/language_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageControllerProvider);
    return DefaultTabController(
      length: AppConfig.newsCategories.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Moradabad News'),
          actions: [
            IconButton(
              tooltip: 'भाषा',
              icon: const Icon(Icons.translate),
              onPressed: () => ref.read(languageControllerProvider.notifier).toggle(),
            ),
            IconButton(
              tooltip: 'डार्क मोड',
              icon: const Icon(Icons.dark_mode_outlined),
              onPressed: () => ref.read(themeControllerProvider.notifier).toggleDarkMode(),
            ),
            IconButton(
              tooltip: 'बुकमार्क',
              icon: const Icon(Icons.bookmark_outline),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.bookmarks),
            ),
            IconButton(
              tooltip: 'मौसम',
              icon: const Icon(Icons.cloud_outlined),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.weather),
            ),
            IconButton(
              tooltip: 'एडमिन',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.admin),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: AppConfig.newsCategories
                .map((category) => Tab(text: AppConfig.categoryLabel(category, locale.languageCode)))
                .toList(),
          ),
        ),
        drawer: const _AccountDrawer(),
        body: Column(
          children: [
            const BreakingBanner(),
            Expanded(
              child: TabBarView(
                children: AppConfig.newsCategories
                    .map((category) => CategoryNewsList(category: category))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BreakingBanner extends ConsumerWidget {
  const BreakingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breaking = ref.watch(breakingNewsProvider);
    return breaking.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Material(
          color: Theme.of(context).colorScheme.errorContainer,
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 28),
              itemBuilder: (context, index) => Center(
                child: Text(
                  'ब्रेकिंग: ${items[index].title}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class CategoryNewsList extends ConsumerWidget {
  const CategoryNewsList({required this.category, super.key});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(categoryNewsProvider(category));
    return articles.when(
      data: (items) => CustomScrollView(
        slivers: [
          if (category == 'Local') const SliverToBoxAdapter(child: HeadlinesCarousel()),
          if (items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyNewsState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) => NewsCard(article: items[index]),
              ),
            ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('समाचार लोड नहीं हो पाए: $error')),
    );
  }
}

class _EmptyNewsState extends StatelessWidget {
  const _EmptyNewsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.newspaper_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'अभी खबरें उपलब्ध नहीं हैं',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Firebase में news collection जोड़ें या Cloud Functions deploy करें।',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class HeadlinesCarousel extends ConsumerWidget {
  const HeadlinesCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headlines = ref.watch(headlinesProvider);
    return headlines.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 260,
          child: PageView.builder(
            padEnds: false,
            controller: PageController(viewportFraction: 0.88),
            itemCount: items.take(8).length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsetsDirectional.only(
                start: index == 0 ? 16 : 8,
                end: 8,
                top: 16,
                bottom: 4,
              ),
              child: _HeadlineTile(article: items[index]),
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _HeadlineTile extends StatelessWidget {
  const _HeadlineTile({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.pushNamed(context, AppRoutes.article, arguments: article),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NewsImage(url: article.image),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.76)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountDrawer extends ConsumerWidget {
  const _AccountDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Drawer(
      child: SafeArea(
        child: user.when(
          data: (currentUser) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Moradabad News', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              if (currentUser == null)
                FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Google से लॉगिन'),
                  onPressed: () => ref.read(authRepositoryProvider).signInWithGoogle(),
                )
              else ...[
                Text(currentUser.displayName ?? 'User'),
                Text(currentUser.email ?? ''),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('साइन आउट'),
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                ),
              ],
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
        ),
      ),
    );
  }
}
