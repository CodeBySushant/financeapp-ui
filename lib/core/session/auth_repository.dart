import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../network/token_store.dart';
import 'app_user.dart';

/// Talks to `/api/auth`.
class AuthRepository {
  AuthRepository({ApiClient? client, TokenStore? tokens})
      : _api = client ?? ApiClient.instance,
        _tokens = tokens ?? TokenStore.instance;

  final ApiClient _api;
  final TokenStore _tokens;

  Future<AppUser> register({
    required String email,
    required String password,
    String? name,
    String? currency,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/auth/register',
      skipAuth: true,
      body: {
        'email': email.trim(),
        'password': password,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (currency != null) 'currency': currency,
      },
    );
    return _persist(data);
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/auth/login',
      skipAuth: true,
      body: {'email': email.trim(), 'password': password},
    );
    return _persist(data);
  }

  /// Validates a stored session on launch. Returns null when there is nothing
  /// to restore, or when the server has since rejected it.
  Future<AppUser?> restore() async {
    final stored = await _tokens.readUser();
    final refresh = await _tokens.readRefresh();
    if (stored == null || refresh == null) return null;

    var user = AppUser.fromJson(stored);
    try {
      final me = await _api.get<Map<String, dynamic>>('/api/auth/me');
      user = user.mergeFromMe(me);
      await _tokens.saveUser(user.toJson());
      return user;
    } on ApiException catch (e) {
      // Offline is not signed out. The cached session stands and the dashboard
      // falls back to its cache; anything else means the server rejected us.
      if (e.isOffline) return user;
      if (e.isAuthFailure) {
        await _tokens.clear();
        return null;
      }
      return user;
    }
  }

  Future<void> signOut() async {
    final refresh = await _tokens.readRefresh();
    if (refresh != null) {
      try {
        await _api.post<void>(
          '/api/auth/logout',
          skipAuth: true,
          body: {'refreshToken': refresh},
        );
      } on ApiException {
        // A failed server-side revoke must not trap someone in the app. The
        // local credentials go either way.
      }
    }
    await _tokens.clear();
  }

  Future<void> signOutEverywhere() async {
    try {
      await _api.post<void>('/api/auth/logout-all');
    } on ApiException {
      // Same reasoning as signOut.
    }
    await _tokens.clear();
  }

  Future<AppUser> _persist(Map<String, dynamic> data) async {
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    final userJson = data['user'];

    if (access == null || refresh == null || userJson is! Map<String, dynamic>) {
      throw const ApiException(
        ApiErrorCode.malformed,
        'Sign-in succeeded but the response was missing credentials.',
      );
    }

    await _tokens.saveTokens(access: access, refresh: refresh);
    await _tokens.saveUser(userJson);
    return AppUser.fromJson(userJson);
  }
}
