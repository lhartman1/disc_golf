import 'package:json_annotation/json_annotation.dart';

part 'course.g.dart';

@JsonSerializable()
class Course {
  const Course(this.id, this.name, this.pars);

  final String id;
  final String name;
  final List<int> pars;

  int get numHoles => pars.length;

  int get parTotal => pars.fold(0, (prev, curr) => prev + curr);

  Course copyWith({
    String? id,
    String? name,
    List<int>? pars,
  }) =>
      Course(
        id ?? this.id,
        name ?? this.name,
        pars ?? this.pars,
      );

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  Map<String, dynamic> toJson() => _$CourseToJson(this);
}
