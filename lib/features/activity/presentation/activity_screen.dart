import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../dev/preview_extras.dart';

/// Every transaction, newest first, grouped by day.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  static const _filters = ['All', 'Spending', 'Income'];
  int _filter = 0;
  String _query = '';

  List<PreviewTx> get _visible {
    final all = PreviewExtras.transactions();
    final q = _query.trim().toLowerCase();

    return all.where((t) {
      final matchesFilter = switch (_filter) {
        1 => !t.isIncome,
        2 => t.isIncome,
        _ => true,
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return t.merchant.toLowerCase().contains(q) ||
          t.categoryLabel.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    final groups = <String, List<PreviewTx>>{};
    for (final t in items) {
      groups.putIfAbsent(_dayLabel(t.at), () => []).add(t);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ScreenHeader(
            title: 'Activity',
            subtitle: '${items.length} transactions',
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(
                    color: Glass.textPrimary,
                    fontSize: 14.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search merchant or category',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Glass.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    for (var i = 0; i < _filters.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: GlassChip(
                          label: _filters[i],
                          selected: i == _filter,
                          tone: Glass.cyan,
                          onTap: () => setState(() => _filter = i),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: GlassEmpty(
                icon: Icons.search_off_rounded,
                title: 'Nothing matches',
                body: 'Try a different search, or clear the filter.',
                actionLabel: 'Add a transaction',
                onAction: widget.onAdd,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              140,
            ),
            sliver: SliverList.list(
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xs,
                      AppSpacing.sm,
                      AppSpacing.xs,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Glass.textMuted,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _dayTotal(entry.value),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Glass.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GlassPanel(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < entry.value.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 70,
                              color: Glass.white(0.07),
                            ),
                          _TxRow(tx: entry.value[i]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ],
            ),
          ),
      ],
    );
  }

  static String _dayLabel(DateTime at) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${at.day} ${months[at.month - 1]}';
  }

  static String _dayTotal(List<PreviewTx> txs) {
    var net = 0;
    for (final t in txs) {
      net += t.isIncome ? t.amount.minor : -t.amount.minor;
    }
    final money = Money.fromMinor(net.abs(), 'INR');
    return '${net >= 0 ? '+' : '-'}${money.format()}';
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx});

  final PreviewTx tx;

  @override
  Widget build(BuildContext context) {
    final tone = tx.isIncome ? Glass.success : Glass.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          CategoryGlyph(categoryId: tx.categoryId),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Glass.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.note == null
                      ? tx.categoryLabel
                      : '${tx.categoryLabel} · ${tx.note}',
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
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${tx.isIncome ? '+' : '−'}${tx.amount.format()}',
            style: context.text.moneySm.copyWith(
              fontSize: 14.5,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}
