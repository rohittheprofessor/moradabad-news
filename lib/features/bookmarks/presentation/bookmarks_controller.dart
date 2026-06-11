import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookmarkIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(<String>{});
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().map((doc) {
    final ids = (doc.data()?['bookmarks'] as List<dynamic>? ?? []).cast<String>();
    return ids.toSet();
  });
});

final bookmarkControllerProvider = Provider<BookmarkController>((ref) {
  return BookmarkController(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class BookmarkController {
  BookmarkController(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<void> toggle(String articleId, bool isBookmarked) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Login required');
    await _db.collection('users').doc(user.uid).set({
      'bookmarks': isBookmarked
          ? FieldValue.arrayRemove([articleId])
          : FieldValue.arrayUnion([articleId]),
    }, SetOptions(merge: true));
  }
}
