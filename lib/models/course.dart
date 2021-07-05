import 'package:json_annotation/json_annotation.dart';

part 'course.g.dart';

@JsonSerializable()
class Course {
  const Course(this.id, this.name, this.pars);

  final String id;
  final String name;
  final List<int> pars;

  int get numHoles => pars.length;

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  Map<String, dynamic> toJson() => _$CourseToJson(this);
}
