import 'package:flutter/material.dart';
import 'package:moradabad_news/features/admin/presentation/admin_screen.dart';
import 'package:moradabad_news/features/bookmarks/presentation/bookmarks_screen.dart';
import 'package:moradabad_news/features/home/domain/news_article.dart';
import 'package:moradabad_news/features/home/presentation/article_screen.dart';
import 'package:moradabad_news/features/home/presentation/home_screen.dart';
import 'package:moradabad_news/features/weather/presentation/weather_screen.dart';

class AppRoutes {
  static const home = '/';
  static const article = '/article';
  static const bookmarks = '/bookmarks';
  static const weather = '/weather';
  static const admin = '/admin';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) {
        switch (settings.name) {
          case AppRoutes.article:
            return ArticleScreen(article: settings.arguments! as NewsArticle);
          case AppRoutes.bookmarks:
            return const BookmarksScreen();
          case AppRoutes.weather:
            return const WeatherScreen();
          case AppRoutes.admin:
            return const AdminScreen();
          case AppRoutes.home:
          default:
            return const HomeScreen();
        }
      },
    );
  }
}
