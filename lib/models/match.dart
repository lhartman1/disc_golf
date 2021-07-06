import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import 'course.dart';

part 'match.g.dart';

// _TimestampConverter credit is to https://stackoverflow.com/a/62462178
class _TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const _TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) {
    return timestamp.toDate();
  }

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}

@JsonSerializable(explicitToJson: true)
class Match {
  const Match({
    required this.id,
    required this.course,
    required this.datetime,
    required this.players,
  });

  final String id;
  final Course course;
  @_TimestampConverter()
  final DateTime datetime;
  final List<String> players;

  Match copyWith({
    String? id,
    Course? course,
    DateTime? datetime,
    List<String>? players,
  }) =>
      Match(
        id: id ?? this.id,
        course: course ?? this.course,
        datetime: datetime ?? this.datetime,
        players: players ?? this.players,
      );

  factory Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);

  Map<String, dynamic> toJson() => _$MatchToJson(this);
}
