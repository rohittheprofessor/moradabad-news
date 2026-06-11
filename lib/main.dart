import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moradabad_news/core/routing/app_router.dart';
import 'package:moradabad_news/core/theme/app_theme.dart';
import 'package:moradabad_news/core/theme/theme_controller.dart';
import 'package:moradabad_news/features/auth/data/auth_repository.dart';
import 'package:moradabad_news/features/language/presentation/language_controller.dart';
import 'package:moradabad_news/features/notifications/data/notification_service.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: MoradabadNewsApp()));
}

class MoradabadNewsApp extends ConsumerWidget {
  const MoradabadNewsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationBootstrapProvider);
    ref.watch(authStateSyncProvider);

    final locale = ref.watch(languageControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'Moradabad News',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('hi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.home,
    );
  }
}
