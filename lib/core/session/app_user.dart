import 'package:flutter/foundation.dart';

/// The signed-in person.
///
/// Mirrors the `user` object returned by `POST /api/auth/login`. Note that
/// `GET /api/auth/me` returns a narrower object with no `name`, so the name is
/// carried forward from sign-in rather than refetched.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.currency = 'INR',
    this.timezone = 'Asia/Kolkata',
    this.isPremium = false,
    this.onboarded = false,
  });

  final String id;
  final String email;
  final String? name;
  final String currency;
  final String timezone;
  final bool isPremium;
  final bool onboarded;

  /// What the greeting uses. Falls back to the local part of the email so a
  /// Google account without a name still greets someone.
  String get firstName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) {
      final space = n.indexOf(' ');
      return space == -1 ? n : n.substring(0, space);
    }
    final local = email.split('@').first;
    return local.isEmpty ? 'there' : local;
  }

  String get displayName {
    final n = name?.trim();
    return (n != null && n.isNotEmpty) ? n : email.split('@').first;
  }

  String get initial =>
      displayName.isEmpty ? '?' : displayName.substring(0, 1).toUpperCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'currency': currency,
        'timezone': timezone,
        'isPremium': isPremium,
        'onboarded': onboarded,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        name: json['name'] as String?,
        currency: json['currency'] as String? ?? 'INR',
        timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
        isPremium: json['isPremium'] as bool? ?? false,
        onboarded: json['onboarded'] as bool? ?? false,
      );

  /// `/me` omits `name` and `onboarded`, so those are kept from what we already
  /// hold rather than being wiped on every launch.
  AppUser mergeFromMe(Map<String, dynamic> me) => AppUser(
        id: me['id'] as String? ?? id,
        email: me['email'] as String? ?? email,
        name: name,
        currency: me['currency'] as String? ?? currency,
        timezone: me['timezone'] as String? ?? timezone,
        isPremium: me['isPremium'] as bool? ?? isPremium,
        onboarded: onboarded,
      );

  AppUser copyWith({String? name}) => AppUser(
        id: id,
        email: email,
        name: name ?? this.name,
        currency: currency,
        timezone: timezone,
        isPremium: isPremium,
        onboarded: onboarded,
      );
}
