import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/navigation/app_shell.dart';
import 'core/session/app_user.dart';
import 'core/session/session_store.dart';
import 'core/theme/app_theme.dart';
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
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Read the stored profile before the first frame so the greeting is correct
  // on the very first paint rather than flashing a placeholder.
  await SessionStore.instance.load();

  runApp(const FintrakApp());
}

class FintrakApp extends StatelessWidget {
  const FintrakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fintrak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.glass(),
      home: const RootShell(),
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
    final existing = _user?.name;
    final name = await showNameSheet(context, initial: existing);
    if (name == null || !mounted) return;
    final saved = await SessionStore.instance.save(name);
    if (!mounted) return;
    setState(() => _user = saved);
  }

  void _go(int index) {
    // Guard rather than trust: an index that outruns the destination list is
    // exactly the bug this navigation replaced.
    if (index < 0 || index >= shellDestinations.length) return;
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
            onOpenProfile: () => _go(4),
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
          ),
        ],
      ),
    );
  }
}
