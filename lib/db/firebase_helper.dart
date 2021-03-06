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

  static Future<List<User>> getOfflineUsers() async {
    final user = await getCurrentUser();
    if (user == null) return [];

    final result = await FirebaseFirestore.instance.collection('users').doc(user.id).collection('offline_players').get();

    return result.docs.map((e) => User.fromJson(e.data())).toList();
  }

  static Future<bool> addOfflineUserToMatch(User offlineUser, String matchId) {
    getCurrentUser().then((user) {
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .collection('offline_players')
            .doc(offlineUser.id)
            .set(offlineUser.toJson());
      }
    });

    return addUserToMatch(offlineUser, matchId);
  }

  static Future<bool> addUserToMatch(User user, String matchId) async {
    print('adding user "${user.id}" to match "$matchId"');

    final matchDocRef =
        FirebaseFirestore.instance.collection('matches').doc(matchId);

    final matchDocSnapshot = await matchDocRef.get();
    final matchDocData = matchDocSnapshot.data();

    // Only add users to matches that exist
    if (!matchDocSnapshot.exists || matchDocData == null) return false;

    matchDocData['id'] = matchId;
    final match = Match.fromJson(matchDocData);

    // Don't add users to matches they are already in
    if (match.players.contains(user.id)) return false;

    await Future.wait([
      // Add player to players list
      matchDocRef.update({
        'players': FieldValue.arrayUnion([user.id]),
      }),

      // Add player to scorecard
      matchDocRef.collection('scorecard').doc(user.id).set({
        'strokes': List.generate(match.course.numHoles, (index) => 0),
        'user': user.toJson(),
      }),

      // Add course to user's courses
      addCourseToUser(match.course),
    ]);

    return true;
  }

  static Future updateStartingOrder(Match match) async {
    // Update the course in the current match.
    final matchUpdateFuture =
        FirebaseFirestore.instance.collection('matches').doc(match.id).update({
      'players': match.players,
    });

    return matchUpdateFuture;
  }

  /// This function updates for pars for a match and all copies of that course
  /// for each user.
  static Future syncParsForMatch(Match match) async {
    // Update all users' copies of that course for each user playing in the
    // match.
    final usersUpdateFutures = match.players.map((playerId) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(playerId)
          .collection('courses')
          .doc(match.course.id)
          .update({
        'pars': match.course.pars,
      });
    });

    // Update the course in the current match.
    final matchUpdateFuture =
        FirebaseFirestore.instance.collection('matches').doc(match.id).update({
      'course.pars': match.course.pars,
    });

    return Future.wait([
      matchUpdateFuture,
      ...usersUpdateFutures,
    ]);
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

  static Stream<List<Match>> getAllMatches() {
    return FirebaseFirestore.instance
        .collection('matches')
        .where(
          'players',
          arrayContains: FirebaseHelper.getUserId() ?? '<unknown>',
        )
        .orderBy(
          'datetime',
          descending: true,
        )
        .snapshots()
        .map((event) {
      return event.docs.map((e) {
        final matchData = e.data();
        matchData['id'] = e.id;
        return Match.fromJson(matchData);
      }).toList();
    });
  }

  static Stream<Iterable<UserStrokes>> getUserStrokesForMatch(String matchId) {
    final query = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('scorecard')
        .snapshots();

    return query.map((event) {
      final userStrokes = event.docs.map((e) {
        return UserStrokes.fromJson(e.data());
      }).toList();

      /*
      // Sort alphabetically
      userStrokes.sort((a, b) => a.user.username.compareTo(b.user.username));

      // Put the current player first
      final indexOfMe = userStrokes.indexWhere(
          (element) => element.user.id == FirebaseHelper.getUserId());
      if (indexOfMe > 0) {
        final me = userStrokes.removeAt(indexOfMe);
        userStrokes.insert(0, me);
      }
      // */

      return userStrokes;
    });
  }
}
