import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass.dart';
import '../../../core/widgets/screen_header.dart';
import '../../transactions/application/transactions_provider.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/domain/transaction.dart';

/// Every transaction, newest first, grouped by day.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.removeListener(_maybeLoadMore);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    // Fetch before the user reaches the end, so the next page is usually there
    // by the time they get to it.
    if (remaining < 600) {
      ref.read(transactionsProvider.notifier).loadMore();
    }
  }

  Future<void> _delete(Transaction tx) async {
    final message = await ref.read(transactionsProvider.notifier).delete(tx);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message ?? 'Deleted ${tx.amount.format()}')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final state = ref.watch(transactionsProvider);
    final controller = ref.read(transactionsProvider.notifier);

    final groups = <String, List<Transaction>>{};
    for (final t in state.items) {
      groups.putIfAbsent(_dayLabel(t.transactionDate), () => []).add(t);
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      backgroundColor: g.canvasBottom,
      color: g.accent,
      edgeOffset: 100,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ScreenHeader(
              title: 'Activity',
              subtitle: state.loading
                  ? 'Loading…'
                  : '${state.items.length}${state.hasMore ? '+' : ''} transactions',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    onSubmitted: (v) => controller
                        .setFilters(state.filters.copyWith(search: v)),
                    textInputAction: TextInputAction.search,
                    style: TextStyle(color: g.text, fontSize: 14.5),
                    decoration: InputDecoration(
                      hintText: 'Search merchant or note',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: g.textMuted,
                      ),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: g.textMuted,
                              ),
                              onPressed: () {
                                _search.clear();
                                controller.setFilters(
                                  state.filters.copyWith(search: null),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: state.filters.type == null,
                        onTap: () => controller
                            .setFilters(state.filters.copyWith(type: null)),
                      ),
                      for (final t in TxType.values)
                        _FilterChip(
                          label: t.label,
                          selected: state.filters.type == t,
                          onTap: () => controller
                              .setFilters(state.filters.copyWith(type: t)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          if (state.loading)
            const SliverToBoxAdapter(child: _ListSkeleton())
          else if (state.error != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverToBoxAdapter(
                child: GlassEmpty(
                  icon: Icons.cloud_off_rounded,
                  title: 'Could not load your activity',
                  body: state.error!,
                  actionLabel: 'Try again',
                  onAction: controller.refresh,
                ),
              ),
            )
          else if (state.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverToBoxAdapter(
                child: GlassEmpty(
                  icon: Icons.receipt_long_rounded,
                  title: 'Nothing here yet',
                  body: 'Add a transaction and it will show up right away.',
                  actionLabel: 'Add a transaction',
                  onAction: widget.onAdd,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                150,
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
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: g.textMuted,
                        ),
                      ),
                    ),
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < entry.value.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: 70,
                                color: g.strokeSoft,
                              ),
                            _TxRow(
                              tx: entry.value[i],
                              onDelete: () => _delete(entry.value[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  if (state.loadingMore)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: g.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
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
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: GlassChip(
        label: label,
        selected: selected,
        tone: context.glass.accent,
        onTap: onTap,
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx, required this.onDelete});

  final Transaction tx;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Delete this transaction?'),
                content: Text(
                  '${tx.title} · ${tx.amount.format()}. '
                  'Account balances will be adjusted.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: g.danger.withValues(alpha: 0.16),
        child: Icon(Icons.delete_outline_rounded, color: g.danger, size: 20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            CategoryGlyph(categoryId: tx.categorySlug ?? 'other', size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                      color: g.text,
                    ),
                  ),
                  if (tx.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tx.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: g.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${tx.isIncome ? '+' : tx.isTransfer ? '' : '\u2212'}${tx.amount.format()}',
              style: context.text.moneyMd.copyWith(
                color: tx.isIncome ? g.success : g.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          GlassSkeleton(height: 92),
          SizedBox(height: AppSpacing.lg),
          GlassSkeleton(height: 150),
          SizedBox(height: AppSpacing.lg),
          GlassSkeleton(height: 120),
        ],
      ),
    );
  }
}
