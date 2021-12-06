import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

const OFFLINE_PREFIX = 'offlinePlayer:';

@JsonSerializable()
class User {
  const User({
    required this.id,
    required this.email,
    required this.imageUri,
    required this.username,
  });

  final String id;
  final String? email;
  @JsonKey(name: 'image_url')
  final Uri? imageUri;
  final String username;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool isOfflinePlayer() => id.startsWith(OFFLINE_PREFIX);
}
