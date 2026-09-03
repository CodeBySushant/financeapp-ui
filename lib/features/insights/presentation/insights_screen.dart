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
          color: Glass.categoryColor(b.categoryId),
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
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  children: [
                    SizedBox(
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(190, 190),
                            painter: _DonutPainter(
                              segments: segments,
                              totalMinor: spentMinor,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Spent',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Glass.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                spent.format(compact: true),
                                style: context.text.moneyLg.copyWith(
                                  fontSize: 24,
                                  color: Glass.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final s in segments)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: s.color,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.label,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Glass.textSecondary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
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
  _DonutPainter({required this.segments, required this.totalMinor});

  final List<_Segment> segments;
  final int totalMinor;

  @override
  void paint(Canvas canvas, Size size) {
    if (totalMinor <= 0) return;

    const stroke = 26.0;
    const gap = 0.035; // radians of breathing room between arcs
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: centre, radius: radius);

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Glass.white(0.06),
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
      old.totalMinor != totalMinor || old.segments.length != segments.length;
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.budget});

  final PreviewBudget budget;

  @override
  Widget build(BuildContext context) {
    final over = budget.spent > budget.limit;
    final tone = Glass.budgetTone(budget.fraction);

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
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Glass.textPrimary,
                  ),
                ),
              ),
              Text(
                '${budget.spent.format(compact: true)} / ${budget.limit.format(compact: true)}',
                style: context.text.numMeta.copyWith(
                  fontSize: 12.5,
                  color: Glass.textSecondary,
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
                color: over ? Glass.danger : Glass.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
