import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The signed-in person.
///
/// This mirrors the `user` object the API returns from `POST /api/auth/login`
/// and `GET /api/auth/me`, so when the network layer lands this class does not
/// change — only where it is filled from does.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    this.email,
    this.currency = 'INR',
  });

  final String id;
  final String name;
  final String? email;
  final String currency;

  /// What the greeting uses. A full name in a greeting reads like a form
  /// letter, so only the first word is shown.
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final space = trimmed.indexOf(' ');
    return space == -1 ? trimmed : trimmed.substring(0, space);
  }

  String get initial =>
      name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();

  AppUser copyWith({String? name, String? email, String? currency}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        currency: currency ?? this.currency,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'currency': currency,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? 'local',
        name: json['name'] as String? ?? '',
        email: json['email'] as String?,
        currency: json['currency'] as String? ?? 'INR',
      );

  String encode() => jsonEncode(toJson());

  static AppUser? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      final user = AppUser.fromJson(map);
      return user.name.trim().isEmpty ? null : user;
    } catch (_) {
      // A corrupt record is treated as no record. Better to ask the person
      // their name again than to crash on launch.
      return null;
    }
  }
}
