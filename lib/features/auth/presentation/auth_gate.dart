import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/auth_controller.dart';
import '../../../core/theme/glass.dart';
import '../../../root_shell.dart';
import 'sign_in_screen.dart';

/// Decides what the app shows: a brief check, the sign-in screen, or the app.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return switch (auth.status) {
      AuthStatus.checking => const _Booting(),
      AuthStatus.signedOut => SignInScreen(
          // A new key when the notice changes, so a session that expires while
          // the user is signed in rebuilds the form with the message rather
          // than reusing a stale one.
          key: ValueKey(auth.notice ?? 'signed-out'),
          notice: auth.notice,
        ),
      AuthStatus.signedIn => const RootShell(),
    };
  }
}

class _Booting extends StatelessWidget {
  const _Booting();

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: g.textMuted),
          ),
        ),
      ),
    );
  }
}
