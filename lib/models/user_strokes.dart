import 'package:json_annotation/json_annotation.dart';

import 'match.dart';
import 'user.dart';

part 'user_strokes.g.dart';

@JsonSerializable()
class UserStrokes {
  const UserStrokes(this.user, this.strokes);

  final User user;
  final List<int> strokes;

  factory UserStrokes.fromJson(Map<String, dynamic> json) =>
      _$UserStrokesFromJson(json);

  Map<String, dynamic> toJson() => _$UserStrokesToJson(this);

  int get strokeSum =>
      strokes.fold(0, (previousValue, element) => previousValue + element);

  // Get the score only considering holes that have been played (strokes > 0)
  int getScore(Match match) {
    assert(match.course.numHoles == strokes.length);

    var parSum = 0;
    for (var i = 0; i < match.course.numHoles; i++) {
      if (strokes[i] > 0) {
        parSum += match.course.pars[i];
      }
    }

    return strokeSum - parSum;
  }

  bool get incompleteScore => strokes.any((element) => element == 0);
}
