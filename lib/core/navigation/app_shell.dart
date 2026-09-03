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
/// The add action is a free-floating button rather than a slot inside the bar.
/// The previous build reserved a centre slot by inserting a disabled
/// destination, which made the bar emit indices 0..5 against a five-item list —
/// tapping the last tab threw a RangeError, and the middle tabs were silently
/// off by one. Keeping the action outside the bar means the emitted index is
/// always a real destination index.
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

    return AuroraBackground(
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
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        bottomInset > 0 ? bottomInset * 0.5 + AppSpacing.sm : AppSpacing.lg,
      ),
      // One pill holds everything: five destinations and the add action. The
      // action is still a separate widget rather than a sixth entry in
      // shellDestinations, so it can never emit an index into that list.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: Glass.white(0.09),
              border: Border.all(color: Glass.white(0.15)),
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
      ),
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
    final tone = selected ? Glass.textPrimary : Glass.textMuted;

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
              color: selected ? Glass.white(0.13) : Colors.transparent,
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
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Glass.violet, Color(0xFF9C4DF4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Glass.violet.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              // No label. A labelled sixth slot would read as another tab; a
              // filled tile with a single glyph reads as an action.
              child: const Center(
                child: Icon(Icons.add_rounded, size: 24, color: Colors.white),
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
    final extended = context.windowSize.isExpanded;

    return Row(
      children: [
        NavigationRail(
          selectedIndex: currentIndex,
          onDestinationSelected: onSelect,
          extended: extended,
          minExtendedWidth: 188,
          backgroundColor: Glass.white(0.04),
          indicatorColor: Glass.white(0.13),
          selectedIconTheme: const IconThemeData(color: Glass.textPrimary),
          unselectedIconTheme: const IconThemeData(color: Glass.textMuted),
          selectedLabelTextStyle: const TextStyle(
            color: Glass.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelTextStyle: const TextStyle(
            color: Glass.textMuted,
            fontSize: 12,
          ),
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
        VerticalDivider(width: 1, thickness: 1, color: Glass.white(0.09)),
        Expanded(child: child),
      ],
    );
  }
}
