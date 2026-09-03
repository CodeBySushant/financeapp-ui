import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../dev/preview_extras.dart';

/// Where the money actually goes, and how each budget is holding up.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final budgets = PreviewExtras.budgets();

    var spentMinor = 0;
    for (final b in budgets) {
      spentMinor += b.spent.minor;
    }
    final spent = Money.fromMinor(spentMinor, 'INR');

    final segments = [
      for (final b in budgets)
        _Segment(
          label: b.label,
          value: b.spent,
          color: g.categoryColor(b.categoryId),
          categoryId: b.categoryId,
        ),
    ]..sort((a, b) => b.value.minor.compareTo(a.value.minor));

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: ScreenHeader(
            title: 'Insights',
            subtitle: 'This month at a glance',
          ),
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
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The ring is inset inside a square box rather than filling
                    // it. Previously the stroke's outer edge landed exactly on
                    // the bounding box, so the round caps and antialiasing were
                    // clipped against it.
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
                                totalMinor: spentMinor,
                                track: g.strokeSoft,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  spent.format(compact: true),
                                  style: context.text.moneyLg.copyWith(
                                    color: g.text,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'spent',
                                  style: TextStyle(
                                    fontSize: 12,
                                    letterSpacing: -0.05,
                                    color: g.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // A legend of bare colour dots asks you to match hues back
                    // to a chart. Giving each row its amount and share makes it
                    // readable on its own and uses the card's width.
                    for (var i = 0; i < segments.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, indent: 20, color: g.strokeSoft),
                      _LegendRow(
                        segment: segments[i],
                        totalMinor: spentMinor,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeading(title: 'Budgets'),
              for (final b in budgets)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _BudgetRow(budget: b),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segment {
  const _Segment({
    required this.label,
    required this.value,
    required this.color,
    required this.categoryId,
  });

  final String label;
  final Money value;
  final Color color;
  final String categoryId;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.totalMinor,
    required this.track,
  });

  final List<_Segment> segments;
  final int totalMinor;

  /// Passed in: a CustomPainter has no BuildContext to read the palette from.
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    if (totalMinor <= 0) return;

    const stroke = 18.0;
    const gap = 0.045; // radians of breathing room between arcs
    // One extra pixel of inset: with round caps, an arc whose outer edge sits
    // exactly on the bounding box gets shaved by antialiasing.
    const inset = 1.0;
    final centre = Offset(size.width / 2, size.height / 2);
    final radius =
        (math.min(size.width, size.height) - stroke) / 2 - inset;
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
      final sweep = (s.value.minor / totalMinor) * math.pi * 2;
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
          ..color = s.color,
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

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.budget});

  final PreviewBudget budget;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final over = budget.spent > budget.limit;
    final tone = g.budgetTone(budget.fraction);

    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              CategoryGlyph(categoryId: budget.categoryId, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  budget.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: g.text,
                  ),
                ),
              ),
              Text(
                '${budget.spent.format(compact: true)} / ${budget.limit.format(compact: true)}',
                style: context.text.numMeta.copyWith(
                  fontSize: 12.5,
                  color: g.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GlassBar(fraction: budget.fraction, tone: tone, height: 6),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              over
                  ? 'Over by ${(budget.spent - budget.limit).format()}'
                  : '${budget.remaining.format()} left',
              style: TextStyle(
                fontSize: 12,
                fontWeight: over ? FontWeight.w600 : FontWeight.w400,
                color: over ? g.danger : g.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.segment, required this.totalMinor});

  final _Segment segment;
  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final share =
        totalMinor <= 0 ? 0 : (segment.value.minor / totalMinor * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: segment.color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              segment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                letterSpacing: -0.15,
                color: g.text,
              ),
            ),
          ),
          Text(
            '$share%',
            style: TextStyle(fontSize: 13, color: g.textMuted),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            segment.value.format(),
            style: context.text.moneyMd.copyWith(color: g.text),
          ),
        ],
      ),
    );
  }
}
