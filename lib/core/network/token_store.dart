import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where credentials live.
///
/// Secure storage, not SharedPreferences. A refresh token is a bearer
/// credential valid for 30 days; in plain preferences it sits in app-private
/// storage that any backup extraction or rooted device can read. This routes
/// through the Android Keystore instead.
class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccess = 'fintrak.token.access';
  static const _kRefresh = 'fintrak.token.refresh';
  static const _kUser = 'fintrak.session.user';

  String? _accessCache;

  /// Held in memory so the bearer header does not hit the keystore on every
  /// request. Cleared on sign-out.
  String? get cachedAccessToken => _accessCache;

  Future<String?> readAccess() async {
    _accessCache ??= await _storage.read(key: _kAccess);
    return _accessCache;
  }

  Future<String?> readRefresh() => _storage.read(key: _kRefresh);

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    _accessCache = access;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> saveAccess(String access) async {
    _accessCache = access;
    await _storage.write(key: _kAccess, value: access);
  }

  /// The user object from login. `GET /api/auth/me` does not return `name`, so
  /// without this the greeting would lose the person's name on every relaunch.
  Future<void> saveUser(Map<String, dynamic> json) =>
      _storage.write(key: _kUser, value: jsonEncode(json));

  Future<Map<String, dynamic>?> readUser() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    _accessCache = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
  }
}
