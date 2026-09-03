import 'package:flutter/material.dart';

import '../../../core/session/app_user.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/glass.dart';
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
                fill: 0.09,
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
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Glass.violet, Glass.pink],
                              ),
                        color: user == null ? Glass.white(0.08) : null,
                        border: Border.all(color: Glass.white(0.16)),
                      ),
                      child: Center(
                        child: user == null
                            ? const Icon(
                                Icons.person_outline_rounded,
                                color: Glass.textSecondary,
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: Glass.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.email ??
                                'Saved on this device until sign-in exists',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Glass.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Glass.textMuted,
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
                  style: TextStyle(fontSize: 12, color: Glass.white(0.28)),
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
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 58, color: Glass.white(0.07)),
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
              Icon(item.icon, size: 20, color: Glass.textSecondary),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Glass.textPrimary,
                  ),
                ),
              ),
              if (item.value != null)
                Text(
                  item.value!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Glass.textMuted,
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Glass.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
