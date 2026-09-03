import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/navigation/app_shell.dart';
import 'core/session/app_user.dart';
import 'core/session/session_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'dev/preview_data.dart';
import 'features/activity/presentation/activity_screen.dart';
import 'features/goals/presentation/goals_screen.dart';
import 'features/home/domain/home_summary.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/insights/presentation/insights_screen.dart';
import 'features/onboarding/presentation/name_sheet.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/transactions/presentation/add_transaction_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Read the stored profile and theme before the first frame, so neither the
  // greeting nor the background flashes the wrong value on launch.
  await Future.wait([
    SessionStore.instance.load(),
    ThemeController.instance.load(),
  ]);

  runApp(const FintrakApp());
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
            // Status bar icons have to follow the resolved theme, not the
            // stored preference — "system" can resolve either way.
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
          home: const RootShell(),
        );
      },
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  HomeSummary? _summary;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _user = SessionStore.instance.current;
    _load();

    if (_user == null) {
      // Nobody has identified themselves yet. Ask once, after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _askForName());
    }
  }

  Future<void> _load() async {
    // TODO(api): replace with DashboardRepository.fetch(), which calls
    // GET /api/analytics/dashboard and falls back to the local cache offline.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _summary = PreviewData.dashboard());
  }

  Future<void> _refresh() async {
    setState(() => _summary = null);
    await _load();
  }

  Future<void> _askForName() async {
    final name = await showNameSheet(context, initial: _user?.name);
    if (name == null || !mounted) return;
    final saved = await SessionStore.instance.save(name);
    if (!mounted) return;
    setState(() => _user = saved);
  }

  void _go(int index) {
    // Guard against the screen count, not the destination count: Profile is a
    // screen without a bar slot, so those two numbers are deliberately
    // different now. Using the wrong one is how the original RangeError
    // happened.
    if (index < 0 || index >= kScreenCount) return;
    setState(() => _index = index);
  }

  Future<void> _add({String? categoryId}) async {
    final amount = await showAddTransactionSheet(
      context,
      initialCategoryId: categoryId,
    );
    if (amount == null || !mounted) return;
    _toast('Added ${amount.format()}. Saving arrives with the API.');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _soon(String what) => _toast('$what is not built yet.');

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final user = _user;

    return AppShell(
      currentIndex: _index,
      onDestinationSelected: _go,
      onAdd: _add,
      child: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            // The greeting reads from the session, never from dashboard data.
            // Who you are and what you spent are two different questions.
            userName: user?.firstName,
            summary: summary,
            onRefresh: _refresh,
            onQuickAdd: (categoryId) => _add(categoryId: categoryId),
            onOpenBudgets: () => _go(2),
            onOpenTransactions: () => _go(1),
            onOpenGoals: () => _go(3),
            onOpenProfile: () => _go(kProfileIndex),
          ),
          ActivityScreen(onAdd: _add),
          const InsightsScreen(),
          GoalsScreen(
            goals: summary?.goals ?? const <GoalProgress>[],
            onCreate: () => _soon('Creating a goal'),
          ),
          ProfileScreen(
            user: user,
            onEditName: _askForName,
            onNotImplemented: _soon,
            onBack: () => _go(0),
          ),
        ],
      ),
    );
  }
}
