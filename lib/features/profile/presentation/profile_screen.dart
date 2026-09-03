import 'package:flutter/material.dart';

import '../../../core/session/app_user.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/glass.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/screen_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.onEditName,
    required this.onNotImplemented,
  });

  /// Null until someone has identified themselves.
  final AppUser? user;
  final VoidCallback onEditName;
  final ValueChanged<String> onNotImplemented;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: ScreenHeader(title: 'Profile')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            140,
          ),
          sliver: SliverList.list(
            children: [
              GlassPanel(
                blurred: true,
                onTap: onEditName,
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: user == null
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [g.accent, g.accentAlt],
                              ),
                        color: user == null ? g.surfaceLow : null,
                        border: Border.all(color: g.stroke),
                      ),
                      child: Center(
                        child: user == null
                            ? Icon(
                                Icons.person_outline_rounded,
                                color: g.textSecondary,
                              )
                            : Text(
                                user!.initial,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Add your name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: g.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.email ??
                                'Saved on this device until sign-in exists',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: g.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: g.textMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeading(title: 'Money'),
              _Group(
                items: [
                  _Item(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Currency',
                    value: user?.currency ?? 'INR',
                    onTap: () => onNotImplemented('Currency'),
                  ),
                  _Item(
                    icon: Icons.pie_chart_outline_rounded,
                    label: 'Budgets',
                    onTap: () => onNotImplemented('Budget settings'),
                  ),
                  _Item(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Accounts',
                    onTap: () => onNotImplemented('Accounts'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeading(title: 'Appearance'),
              const _ThemePicker(),
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeading(title: 'App'),
              _Group(
                items: [
                  _Item(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () => onNotImplemented('Notifications'),
                  ),
                  _Item(
                    icon: Icons.lock_outline_rounded,
                    label: 'Privacy and data',
                    onTap: () => onNotImplemented('Privacy'),
                  ),
                  _Item(
                    icon: Icons.file_download_outlined,
                    label: 'Export transactions',
                    onTap: () => onNotImplemented('Export'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Text(
                  'Fintrak 0.1.0',
                  style: TextStyle(fontSize: 12, color: g.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Item {
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
}

class _Group extends StatelessWidget {
  const _Group({required this.items});

  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 58, color: g.strokeSoft),
            _Row(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: g.textSecondary),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: g.text,
                  ),
                ),
              ),
              if (item.value != null)
                Text(
                  item.value!,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: g.textMuted,
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: g.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Light, dark, or follow the device.
///
/// A segmented control rather than a switch: a two-state switch cannot express
/// "follow the system", and hiding that option behind a long-press is worse
/// than showing three buttons.
class _ThemePicker extends StatefulWidget {
  const _ThemePicker();

  @override
  State<_ThemePicker> createState() => _ThemePickerState();
}

class _ThemePickerState extends State<_ThemePicker> {
  static const _options = <(ThemeMode, String, IconData)>[
    (ThemeMode.light, 'Light', Icons.light_mode_rounded),
    (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
    (ThemeMode.system, 'System', Icons.brightness_auto_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final controller = ThemeController.instance;

    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          for (final (mode, label, icon) in _options)
            Expanded(
              child: _ThemeOption(
                label: label,
                icon: icon,
                selected: controller.isActive(mode),
                onTap: () {
                  controller.set(mode);
                  setState(() {});
                },
                palette: g,
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.palette,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final GlassPalette palette;

  @override
  Widget build(BuildContext context) {
    final tone = selected ? palette.accent : palette.textMuted;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.emphasized,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected
                  ? palette.accent.withValues(alpha: palette.isDark ? 0.20 : 0.12)
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? palette.accent.withValues(alpha: 0.45)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, size: 19, color: tone),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
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
