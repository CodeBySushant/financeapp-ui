import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/app_lock.dart';
import '../../../core/session/auth_controller.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/glass.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/glass_route.dart';
import '../../../core/widgets/screen_header.dart';
import '../../accounts/presentation/accounts_screen.dart';
import '../../assistant/presentation/assistant_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    required this.onNotImplemented,
    required this.onBack,
  });

  final ValueChanged<String> onNotImplemented;

  /// Profile is no longer a bar destination, so it carries its own way out.
  final VoidCallback onBack;

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref, {
    required bool everywhere,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(everywhere ? 'Sign out everywhere?' : 'Sign out?'),
        content: Text(
          everywhere
              ? 'Every device signed in to this account will be signed out.'
              : 'You will need your password to sign back in on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // The gate swaps this screen out once the state flips, so there is nothing
    // to navigate here.
    await ref
        .read(authControllerProvider.notifier)
        .signOut(everywhere: everywhere);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = context.glass;
    final user = ref.watch(currentUserProvider);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ScreenHeader(title: 'Profile', onBack: onBack),
        ),
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
                            user?.displayName ?? 'Signed in',
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
                            user?.email ?? '',
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
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Accounts',
                    onTap: () => Navigator.of(context)
                        .push(glassRoute(const AccountsScreen())),
                  ),
                  _Item(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Ask my money',
                    onTap: () => Navigator.of(context).push(
                      glassRoute(
                        AssistantScreen(
                          onBack: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeading(title: 'Appearance'),
              const _ThemePicker(),
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeading(title: 'Security'),
              const _AppLockTile(),
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
              const SectionHeading(title: 'Account'),
              _Group(
                items: [
                  _Item(
                    icon: Icons.logout_rounded,
                    label: 'Sign out',
                    onTap: () =>
                        _confirmSignOut(context, ref, everywhere: false),
                  ),
                  _Item(
                    icon: Icons.devices_rounded,
                    label: 'Sign out on all devices',
                    onTap: () =>
                        _confirmSignOut(context, ref, everywhere: true),
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
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.emphasized,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.control),
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

/// Turns the device-credential lock on and off.
///
/// Hidden entirely when the device cannot authenticate, rather than shown
/// disabled: a greyed-out switch invites a support question with no answer.
class _AppLockTile extends ConsumerWidget {
  const _AppLockTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = context.glass;
    final lock = ref.watch(appLockProvider);

    if (!lock.supported) {
      return GlassPanel(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 20, color: g.textMuted),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                'This device has no screen lock set up, so the app lock is '
                'unavailable.',
                style: TextStyle(fontSize: 13, height: 1.4, color: g.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return GlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: lock.enabled,
        onChanged: (want) async {
          final ok = await ref.read(appLockProvider).setEnabled(want);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                const SnackBar(content: Text('Could not verify. Lock unchanged.')),
              );
          }
        },
        title: Text(
          'Require unlock',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: g.text,
          ),
        ),
        subtitle: Text(
          'Ask for your fingerprint or PIN when Fintrak opens.',
          style: TextStyle(fontSize: 12.5, color: g.textMuted),
        ),
        secondary: Icon(
          Icons.fingerprint_rounded,
          size: 20,
          color: g.textSecondary,
        ),
      ),
    );
  }
}
