import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass.dart';
import '../../../core/widgets/screen_header.dart';
import '../../home/domain/home_summary.dart';

/// What you are saving towards.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({
    super.key,
    required this.goals,
    required this.onCreate,
  });

  final List<GoalProgress> goals;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ScreenHeader(
            title: 'Goals',
            subtitle: goals.isEmpty
                ? 'Nothing tracked yet'
                : '${goals.length} in progress',
            trailing: GestureDetector(
              onTap: onCreate,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: g.strokeSoft,
                  border: Border.all(color: g.stroke),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: g.text,
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            140,
          ),
          sliver: goals.isEmpty
              ? SliverToBoxAdapter(
                  child: GlassEmpty(
                    icon: Icons.flag_rounded,
                    title: 'No goal set',
                    body:
                        'A goal turns saving from a vague intention into a number you can watch move.',
                    actionLabel: 'Create a goal',
                    onAction: onCreate,
                  ),
                )
              : SliverList.list(
                  children: [
                    for (final g in goals)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: _GoalTile(goal: g),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});

  final GoalProgress goal;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final remaining = goal.target - goal.saved;

    return GlassPanel(
      tint: g.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassRing(
                fraction: goal.fraction,
                tone: g.success,
                size: 64,
                stroke: 7,
                child: Text(
                  '${goal.percent}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: g.text,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: g.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.saved.format(),
                      style: context.text.moneyMd.copyWith(
                        fontSize: 19,
                        color: g.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of ${goal.target.format()}',
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
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Still to save',
                  value: remaining.isNegative
                      ? 'Reached'
                      : remaining.format(compact: true),
                ),
              ),
              if (goal.targetDate != null)
                Expanded(
                  child: _Stat(
                    label: 'Target date',
                    value: _formatDate(goal.targetDate!),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: g.textMuted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: g.text,
          ),
        ),
      ],
    );
  }
}
