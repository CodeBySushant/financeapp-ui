import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../layout/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

@immutable
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const shellDestinations = <ShellDestination>[
  ShellDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  ShellDestination(
    label: 'Activity',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
  ),
  ShellDestination(
    label: 'Insights',
    icon: Icons.donut_small_outlined,
    selectedIcon: Icons.donut_small_rounded,
  ),
  ShellDestination(
    label: 'Goals',
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag_rounded,
  ),
  ShellDestination(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
];

/// Wraps the five top-level sections.
///
/// Phones get a bottom bar with a centred add action. From 600px up the bar
/// becomes a side rail — a bottom bar on a tablet wastes the width and puts the
/// primary action an inconvenient distance from where the eye already is.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onAdd,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAdd;

  void _select(int index) {
    HapticFeedback.selectionClick();
    onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return context.windowSize.isAtLeastMedium
        ? _RailShell(
            currentIndex: currentIndex,
            onSelect: _select,
            onAdd: onAdd,
            child: child,
          )
        : _BottomBarShell(
            currentIndex: currentIndex,
            onSelect: _select,
            onAdd: onAdd,
            child: child,
          );
  }
}

class _BottomBarShell extends StatelessWidget {
  const _BottomBarShell({
    required this.child,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onAdd();
        },
        tooltip: 'Add transaction',
        child: const Icon(Icons.add_rounded, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onSelect,
          destinations: [
            for (var i = 0; i < shellDestinations.length; i++) ...[
              NavigationDestination(
                icon: Icon(shellDestinations[i].icon),
                selectedIcon: Icon(shellDestinations[i].selectedIcon),
                label: shellDestinations[i].label,
              ),
              // Reserve the centre slot for the docked add button.
              if (i == 1)
                const NavigationDestination(
                  icon: SizedBox(width: 40),
                  label: '',
                  enabled: false,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RailShell extends StatelessWidget {
  const _RailShell({
    required this.child,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final extended = context.windowSize.isExpanded;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onSelect,
            extended: extended,
            minExtendedWidth: 188,
            backgroundColor: c.canvas,
            indicatorColor: c.surface,
            labelType: extended ? null : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xl,
                bottom: AppSpacing.sm,
              ),
              child: extended
                  ? FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add'),
                    )
                  : FloatingActionButton.small(
                      onPressed: onAdd,
                      tooltip: 'Add transaction',
                      child: const Icon(Icons.add_rounded),
                    ),
            ),
            destinations: [
              for (final d in shellDestinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          VerticalDivider(width: 1, thickness: 1, color: c.line),
          Expanded(child: child),
        ],
      ),
    );
  }
}
