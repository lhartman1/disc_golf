import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import '../models/match.dart';
import '../models/user.dart';

abstract class FirebaseHelper {
  static String? getUserId() => auth.FirebaseAuth.instance.currentUser?.uid;

  static Future<User?> getUser(String uid) async {
    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userSnapshot.data();
    if (userData != null) {
      userData['id'] = uid;
      return User.fromJson(userData);
    }
  }

  static void createMatch() {
    FirebaseFirestore.instance.collection('matches').doc()
      ..set({
        'course': {
          'id': '<id goes here>',
          'name': 'Beautiful new course!',
          'pars': [3, 3, 3, 4, 5, 3, 4, 3, 4],
        },
        'datetime': DateTime.now(),
        'players': [getUserId() ?? '<unknown>'],
      })
      ..collection('scorecard').doc().set({
        'user': {
          'email': 'doesitmatter@noitdoesnt.com',
        },
      });
  }

  static Future updateScore(String userId, List<int> strokes, String matchId) {
    return FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('scorecard')
        .doc(userId)
        .update({
      'strokes': strokes,
    });
  }

  static Future<bool> addUserToMatch(String userId, String matchId) async {
    print('adding user "$userId" to match "$matchId"');

    final matchDocRef =
        FirebaseFirestore.instance.collection('matches').doc(matchId);

    final matchDocSnapshot = await matchDocRef.get();
    final matchDocData = matchDocSnapshot.data();

    // Only add users to matches that exist
    if (!matchDocSnapshot.exists || matchDocData == null) return false;

    matchDocData['id'] = matchId;
    final match = Match.fromJson(matchDocData);

    // Don't add users to matches they are already in
    if (match.players.contains(userId)) return false;

    // Make sure the user data is accessible
    final user = await getUser(userId);
    if (user == null) return false;

    await Future.wait([
      // Add player to players list
      matchDocRef.update({
        'players': FieldValue.arrayUnion([userId]),
      }),

      // Add player to scorecard
      matchDocRef.collection('scorecard').doc(userId).set({
        'strokes': List.generate(match.course.numHoles, (index) => 0),
        'user': user.toJson(),
      })
    ]);

    return true;
  }

  static Future removeUserFromMatch(String userId, String matchId) {
    return Future.wait([
      // Remove from players list
      FirebaseFirestore.instance.collection('matches').doc(matchId).update({
        'players': FieldValue.arrayRemove([userId]),
      }),

      // Remove from scorecard collection
      FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .collection('scorecard')
          .doc(userId)
          .delete(),
    ]);
  }

  static void updateMatch() {
    FirebaseFirestore.instance
        .collection('matches')
        .doc('XDSWtmGFowU6cweuPiGK')
        .update({
      // 'didit.other.stuff': 'hur',
      'didit.other.stuff': FieldValue.delete(),
      // 'didit': {
      //   'work': 'yea',
      //   'other': {
      //     'stuff': 'here',
      //   },
      // }
    });
  }
}
