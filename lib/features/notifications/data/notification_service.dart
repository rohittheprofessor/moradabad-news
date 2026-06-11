import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationBootstrapProvider = FutureProvider<void>((ref) async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  await messaging.subscribeToTopic('breaking-news');
  await messaging.subscribeToTopic('daily-digest');
  await messaging.subscribeToTopic('weather-alerts');
});
