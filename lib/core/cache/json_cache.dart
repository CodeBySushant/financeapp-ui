import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A small on-device cache so the dashboard has something to show offline.
///
/// Deliberately not secure storage: this holds figures the user is already
/// looking at, it lives in app-private storage, and running every dashboard
/// read through the keystore would cost more than it protects. Credentials are
/// a different matter and live in [TokenStore].
class JsonCache {
  JsonCache._();

  static final JsonCache instance = JsonCache._();

  static const _prefix = 'fintrak.cache.';

  Future<void> write(String key, Map<String, dynamic> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefix$key',
        jsonEncode({
          'at': DateTime.now().toUtc().toIso8601String(),
          'value': value,
        }),
      );
    } catch (_) {
      // A cache that fails to write is not an error worth surfacing.
    }
  }

  Future<CachedJson?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map ||
          decoded['value'] is! Map ||
          decoded['at'] is! String) {
        return null;
      }
      final at = DateTime.tryParse(decoded['at'] as String);
      if (at == null) return null;
      return CachedJson(
        Map<String, dynamic>.from(decoded['value'] as Map),
        at.toLocal(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}

class CachedJson {
  const CachedJson(this.value, this.savedAt);

  final Map<String, dynamic> value;
  final DateTime savedAt;
}
