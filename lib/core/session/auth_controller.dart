import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import 'app_user.dart';
import 'auth_repository.dart';

enum AuthStatus { checking, signedOut, signedIn }

class AuthState {
  const AuthState({required this.status, this.user, this.notice});

  const AuthState.checking() : status = AuthStatus.checking, user = null, notice = null;

  final AuthStatus status;
  final AppUser? user;

  /// A one-off message to surface on the sign-in screen, e.g. after a session
  /// was revoked mid-use.
  final String? notice;
}

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authRepositoryProvider))..bootstrap();
});

/// Convenience for widgets that only care who is signed in.
final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authControllerProvider).user,
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState.checking()) {
    // The client revokes the whole token family if a rotated refresh token is
    // replayed. When that happens there is nothing to recover, so the app has
    // to return to sign-in and say why rather than silently emptying.
    _sub = ApiClient.instance.onSessionExpired.listen((_) {
      if (state.status == AuthStatus.signedIn) {
        state = const AuthState(
          status: AuthStatus.signedOut,
          notice: 'Your session ended. Please sign in again.',
        );
      }
    });
  }

  final AuthRepository _repo;
  StreamSubscription<void>? _sub;

  Future<void> bootstrap() async {
    final user = await _repo.restore();
    if (!mounted) return;
    state = user == null
        ? const AuthState(status: AuthStatus.signedOut)
        : AuthState(status: AuthStatus.signedIn, user: user);
  }

  Future<void> signIn(String email, String password) async {
    final user = await _repo.signIn(email: email, password: password);
    if (!mounted) return;
    state = AuthState(status: AuthStatus.signedIn, user: user);
  }

  Future<void> register(
    String email,
    String password,
    String? name, {
    String? currency,
  }) async {
    final user = await _repo.register(
      email: email,
      password: password,
      name: name,
      currency: currency,
    );
    if (!mounted) return;
    state = AuthState(status: AuthStatus.signedIn, user: user);
  }

  Future<void> signOut({bool everywhere = false}) async {
    if (everywhere) {
      await _repo.signOutEverywhere();
    } else {
      await _repo.signOut();
    }
    if (!mounted) return;
    state = const AuthState(status: AuthStatus.signedOut);
  }

  /// The dashboard carries a `displayName` the `/me` endpoint does not, so it
  /// backfills the name once real data arrives.
  void adoptDisplayName(String name) {
    final user = state.user;
    if (user == null || name.trim().isEmpty) return;
    if ((user.name ?? '').trim().isNotEmpty) return;
    state = AuthState(status: state.status, user: user.copyWith(name: name));
  }

  void clearNotice() {
    if (state.notice == null) return;
    state = AuthState(status: state.status, user: state.user);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
