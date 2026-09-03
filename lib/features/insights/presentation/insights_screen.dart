import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/screen_header.dart';
import '../../budgets/application/budgets_provider.dart';
import '../../budgets/domain/budget.dart';

/// Where the money went, and how each budget is holding up.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = context.glass;
    final async = ref.watch(budgetsProvider);
    final board = async.valueOrNull;

    // Only per-category lines belong in the ring; the whole-month budget covers
    // the same spend and would double-count every slice.
    final segments = [
      ...?board?.items.where((b) => b.label != 'Everything' && b.used.minor > 0),
    ]..sort((a, b) => b.used.minor.compareTo(a.used.minor));

    final totalUsed =
        segments.fold<int>(0, (sum, b) => sum + b.used.minor);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(budgetsProvider),
      backgroundColor: g.canvasBottom,
      color: g.accent,
      edgeOffset: 100,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ScreenHeader(
              title: 'Insights',
              subtitle: board == null
                  ? 'Loading…'
                  : '${board.period} · ${board.daysRemaining} days left',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              150,
            ),
            sliver: SliverToBoxAdapter(
              child: switch (async) {
                AsyncValue(hasError: true, :final error) => GlassEmpty(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load your insights',
                    body: error is ApiException
                        ? error.message
                        : 'Something went wrong.',
                    actionLabel: 'Try again',
                    onAction: () => ref.invalidate(budgetsProvider),
                  ),
                AsyncValue(isLoading: true) => const Column(
                    children: [
                      GlassSkeleton(height: 300),
                      SizedBox(height: AppSpacing.lg),
                      GlassSkeleton(height: 96),
                    ],
                  ),
                _ => board == null || board.items.isEmpty
                    ? const GlassEmpty(
                        icon: Icons.pie_chart_outline_rounded,
                        title: 'No budgets yet',
                        body:
                            'Set a monthly budget and this fills in as you spend.',
                      )
                    : Column(
                        children: [
                          if (segments.isNotEmpty) ...[
                            _BreakdownCard(
                              segments: segments,
                              totalUsed: totalUsed,
                            ),
                            const SizedBox(height: AppSpacing.huge),
                          ],
                          const SectionHeading(title: 'Budgets'),
                          for (final b in board.items)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _BudgetRow(budget: b),
                            ),
                        ],
                      ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.segments, required this.totalUsed});

  final List<BudgetLine> segments;
  final int totalUsed;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return GlassPanel(
      blurred: true,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The ring is inset inside its box: an arc whose outer edge sits
          // exactly on the bounding box gets its round caps shaved by
          // antialiasing.
          Center(
            child: SizedBox(
              width: 168,
              height: 168,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(168),
                    painter: _DonutPainter(
                      segments: segments,
                      totalMinor: totalUsed,
                      track: g.strokeSoft,
                      colorOf: g.categoryColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Money.fromMinor(
                          totalUsed,
                          segments.first.used.currency,
                        ).format(compact: true),
                        style: context.text.moneyLg.copyWith(color: g.text),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'spent',
                        style: TextStyle(fontSize: 12, color: g.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 20, color: g.strokeSoft),
            _LegendRow(line: segments[i], totalMinor: totalUsed),
          ],
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.totalMinor,
    required this.track,
    required this.colorOf,
  });

  final List<BudgetLine> segments;
  final int totalMinor;

  /// Passed in: a CustomPainter has no BuildContext to read the palette from.
  final Color track;
  final Color Function(String?) colorOf;

  @override
  void paint(Canvas canvas, Size size) {
    if (totalMinor <= 0) return;

    const stroke = 18.0;
    const gap = 0.045;
    const inset = 1.0;
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2 - inset;
    final rect = Rect.fromCircle(center: centre, radius: radius);

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = (s.used.minor / totalMinor) * math.pi * 2;
      if (sweep <= gap) {
        start += sweep;
        continue;
      }
      canvas.drawArc(
        rect,
        start + gap / 2,
        sweep - gap,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = colorOf(s.categorySlug),
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.totalMinor != totalMinor ||
      old.segments.length != segments.length ||
      old.track != track;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.line, required this.totalMinor});

  final BudgetLine line;
  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final share =
        totalMinor <= 0 ? 0 : (line.used.minor / totalMinor * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: g.categoryColor(line.categorySlug),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              line.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                letterSpacing: -0.15,
                color: g.text,
              ),
            ),
          ),
          Text('$share%', style: TextStyle(fontSize: 13, color: g.textMuted)),
          const SizedBox(width: AppSpacing.lg),
          Text(
            line.used.format(),
            style: context.text.moneyMd.copyWith(color: g.text),
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.budget});

  final BudgetLine budget;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final tone = budget.isExceeded ? g.danger : g.textSecondary;

    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              CategoryGlyph(categoryId: budget.categorySlug, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  budget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.15,
                    color: g.text,
                  ),
                ),
              ),
              Text(
                '${budget.used.format(compact: true)} / ${budget.limit.format(compact: true)}',
                style: context.text.numMeta.copyWith(color: g.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GlassBar(fraction: budget.fraction, tone: tone, height: 5),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              budget.isExceeded
                  ? 'Over by ${(budget.used - budget.limit).format()}'
                  : '${budget.remaining.format()} left',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: budget.isExceeded ? FontWeight.w600 : FontWeight.w400,
                color: budget.isExceeded ? g.danger : g.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
