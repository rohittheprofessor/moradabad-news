import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(FirebaseFunctions.instanceFor(region: 'asia-south1'));
});

class AdminService {
  AdminService(this._functions);

  final FirebaseFunctions _functions;

  Future<void> sendNotification({
    required String title,
    required String message,
    required String topic,
  }) async {
    await _functions.httpsCallable('sendBreakingNotification').call({
      'title': title,
      'message': message,
      'topic': topic,
    });
  }
}
