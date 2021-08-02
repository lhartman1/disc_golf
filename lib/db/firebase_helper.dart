import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:tuple/tuple.dart';

import '../models/course.dart';
import '../models/match.dart';
import '../models/user.dart';
import '../models/user_strokes.dart';

abstract class FirebaseHelper {
  static String? getUserId() => auth.FirebaseAuth.instance.currentUser?.uid;

  static Future<User?> getCurrentUser() {
    final userId = getUserId();
    if (userId != null) {
      return getUser(userId);
    }
    return Future.value();
  }

  static Future<User?> getUser(String uid) async {
    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userSnapshot.data();
    if (userData != null) {
      userData['id'] = uid;
      return User.fromJson(userData);
    }
  }

  // This assumes that course comes in with a placeholder id
  static Tuple2<Course, Future> createCourse(Course course) {
    final courseDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(getUserId())
        .collection('courses')
        .doc();

    // The id will be the document id in Firebase
    final courseJson = course.toJson()..remove('id');

    // But still update the course
    course = course.copyWith(id: courseDoc.id);

    return Tuple2(
      course,
      courseDoc.set(courseJson),
    );
  }

  // This assumes that match comes in with a placeholder id
  static Tuple2<Match, Future> createMatch(Match match) {
    final matchDoc = FirebaseFirestore.instance.collection('matches').doc();

    // The id will be the document id in Firebase
    final matchJson = match.toJson()..remove('id');

    // But still update the match
    match = match.copyWith(id: matchDoc.id);

    // This is kind of ugly, but it allows for not required the Tuple to be
    // wrapped in a Future
    return Tuple2(
      match,
      getCurrentUser().then((user) {
        final userStrokes =
            UserStrokes(user!, List.generate(match.course.numHoles, (_) => 0));
        return Future.wait([
          matchDoc.set(matchJson),
          matchDoc
              .collection('scorecard')
              .doc(user.id)
              .set(userStrokes.toJson()),
        ]);
      }),
    );
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
      }),

      // Add course to user's courses
      addCourseToUser(match.course),
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

  static Future addCourseToUser(Course course) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(getUserId())
        .collection('courses')
        .doc(course.id)
        .set(course.toJson());
  }

  static Stream<Iterable<Course>> getCourses() {
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(getUserId())
        .collection('courses')
        .snapshots();

    return query.map((event) {
      return event.docs.map((e) {
        final data = e.data();
        data['id'] = e.id;
        return Course.fromJson(data);
      });
    });
  }

  static Stream<Match> getMatch(String matchId) {
    final query = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .snapshots();

    return query.map((event) {
      final data = event.data()!;
      data['id'] = event.id;
      return Match.fromJson(data);
    });
  }

  static Stream<Iterable<UserStrokes>> getUserStrokesForMatch(String matchId) {
    final query = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('scorecard')
        .snapshots();

    return query.map((event) {
      return event.docs.map((e) {
        return UserStrokes.fromJson(e.data());
      });
    });
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
