import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/security/app_lock.dart';
import 'core/security/lock_gate.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Theme is read before the first frame so the app never flashes the wrong
  // background. The session is restored inside AuthController instead, because
  // it needs a network round trip and must not block startup.
  await Future.wait([
    ThemeController.instance.load(),
    AppLock.instance.load(),
  ]);

  runApp(const ProviderScope(child: FintrakApp()));
}

class FintrakApp extends StatelessWidget {
  const FintrakApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Fintrak',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: controller.mode,
          builder: (context, child) {
            // Status bar icons follow the resolved theme, not the stored
            // preference — "system" can resolve either way.
            final dark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    dark ? Brightness.light : Brightness.dark,
                statusBarBrightness: dark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness:
                    dark ? Brightness.light : Brightness.dark,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          // The lock sits above the auth gate: a locked app must not reveal
          // whether anyone is even signed in.
          home: const LockGate(child: AuthGate()),
        );
      },
    );
  }
}
