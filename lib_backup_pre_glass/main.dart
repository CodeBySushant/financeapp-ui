import 'package:flutter/material.dart';

import 'core/navigation/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'dev/preview_data.dart';
import 'features/home/domain/home_summary.dart';
import 'features/home/presentation/home_screen.dart';

void main() => runApp(const FintrakApp());

class FintrakApp extends StatelessWidget {
  const FintrakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Product name lives in one place so renaming is a one-line change.
      title: 'Fintrak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // TODO(api): replace with DashboardRepository.fetch(), which calls
    // GET /api/analytics/dashboard and falls back to the local cache offline.
    // Until then the screen renders against dev fixtures.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _summary = PreviewData.dashboard());
  }

  Future<void> _refresh() async {
    setState(() => _summary = null);
    await _load();
  }

  void _notImplemented(String what) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('$what is not built yet.')));
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      onAdd: () => _notImplemented('Add transaction'),
      child: switch (_index) {
        0 => HomeScreen(
            summary: _summary,
            onRefresh: _refresh,
            onQuickAdd: (category) => _notImplemented('Quick add'),
            onOpenBudgets: () => _notImplemented('Budgets'),
            onOpenTransactions: () => _notImplemented('Transactions'),
            onOpenGoals: () => _notImplemented('Goals'),
            onAskMyMoney: () => _notImplemented('Ask my money'),
          ),
        _ => Center(
            child: Text(
              '${shellDestinations[_index].label} is not built yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      },
    );
  }
}
