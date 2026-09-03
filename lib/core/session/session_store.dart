import 'package:shared_preferences/shared_preferences.dart';

import 'app_user.dart';

/// Where the app gets the current user from.
///
/// Today it reads a locally saved profile, because there is no auth service to
/// ask. That is the honest position: the app cannot show a "logged in" name
/// until someone logs in.
///
/// When the API lands, [load] becomes a call to `GET /api/auth/me` with the
/// stored access token, and [save] disappears in favour of the login response.
/// Nothing above this class has to change — screens already read the user from
/// here rather than from fixture data.
class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  static const _key = 'fintrak.session.user';

  AppUser? _current;

  AppUser? get current => _current;
  bool get hasUser => _current != null;

  Future<AppUser?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _current = AppUser.decode(prefs.getString(_key));
    } catch (_) {
      _current = null;
    }
    return _current;
  }

  Future<AppUser> save(String name, {String? email}) async {
    final user = AppUser(
      id: _current?.id ?? 'local-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email ?? _current?.email,
      currency: _current?.currency ?? 'INR',
    );
    _current = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, user.encode());
    } catch (_) {
      // Persisting failed; the in-memory user still works for this session.
    }
    return user;
  }

  Future<void> clear() async {
    _current = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
