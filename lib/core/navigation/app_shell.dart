import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../layout/responsive.dart';
import '../theme/app_tokens.dart';
import '../theme/glass.dart';

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
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  ShellDestination(
    label: 'Activity',
    icon: Icons.swap_vert_rounded,
    selectedIcon: Icons.swap_vert_rounded,
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
/// The add action is a separate widget rather than a sixth entry in
/// [shellDestinations], so it can never emit an index into that list.
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
    assert(index >= 0 && index < shellDestinations.length);
    HapticFeedback.selectionClick();
    onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.windowSize.isAtLeastMedium;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: wide
            ? _Rail(
                currentIndex: currentIndex,
                onSelect: _select,
                onAdd: onAdd,
                child: child,
              )
            : child,
        bottomNavigationBar: wide
            ? null
            : _FloatingBar(
                currentIndex: currentIndex,
                onSelect: _select,
                onAdd: onAdd,
              ),
      ),
    );
  }
}

class _FloatingBar extends StatelessWidget {
  const _FloatingBar({
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final radius = BorderRadius.circular(26);

    Widget bar = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: g.isDark
                ? Colors.white.withValues(alpha: 0.09)
                : Colors.white.withValues(alpha: 0.82),
            border: Border.all(color: g.stroke),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < shellDestinations.length; i++)
                Expanded(
                  child: _BarItem(
                    destination: shellDestinations[i],
                    selected: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
              // Same width as one destination slot, so the row stays even.
              Expanded(child: _AddButton(onTap: onAdd)),
            ],
          ),
        ),
      ),
    );

    if (!g.isDark) {
      bar = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B2A52).withValues(alpha: 0.13),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: bar,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        bottomInset > 0 ? bottomInset * 0.5 + AppSpacing.sm : AppSpacing.lg,
      ),
      child: bar,
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final tone = selected ? g.accent : g.textMuted;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.emphasized,
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: selected
                  ? g.accent.withValues(alpha: g.isDark ? 0.20 : 0.12)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 21,
                  color: tone,
                ),
                const SizedBox(height: 2),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: tone,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return Semantics(
      button: true,
      label: 'Add transaction',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 9,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [g.accent, Color.lerp(g.accent, g.accentAlt, 0.45)!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: g.accent.withValues(alpha: 0.42),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              // No label. A labelled sixth slot would read as another tab; a
              // filled tile with a single glyph reads as an action.
              child: Center(
                child: Icon(Icons.add_rounded, size: 24, color: g.onAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
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
    final g = context.glass;
    final extended = context.windowSize.isExpanded;

    return Row(
      children: [
        NavigationRail(
          selectedIndex: currentIndex,
          onDestinationSelected: onSelect,
          extended: extended,
          minExtendedWidth: 188,
          backgroundColor: g.surfaceLow,
          indicatorColor: g.accent.withValues(alpha: g.isDark ? 0.20 : 0.12),
          selectedIconTheme: IconThemeData(color: g.accent),
          unselectedIconTheme: IconThemeData(color: g.textMuted),
          selectedLabelTextStyle: TextStyle(
            color: g.accent,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelTextStyle: TextStyle(color: g.textMuted, fontSize: 12),
          labelType: extended ? null : NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xl,
              bottom: AppSpacing.md,
            ),
            child: extended
                ? FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add'),
                  )
                : SizedBox(
                    width: 56,
                    height: 56,
                    child: _AddButton(onTap: onAdd),
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
        VerticalDivider(width: 1, thickness: 1, color: g.strokeSoft),
        Expanded(child: child),
      ],
    );
  }
}
