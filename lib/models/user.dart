import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

const OFFLINE_PREFIX = 'offlinePlayer:';

@freezed
class User with _$User {
  const User._();

  factory User({
    required String id,
    required String? email,
    @JsonKey(name: 'image_url')
    required Uri? imageUri,
    required String username,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  bool isOfflinePlayer() => id.startsWith(OFFLINE_PREFIX);
}
