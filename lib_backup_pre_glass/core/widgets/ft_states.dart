import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'ft_card.dart';

/// An empty screen is an invitation, not an apology. The headline names the
/// space, one serif line explains it, and the action is a verb.
class FtEmptyState extends StatelessWidget {
  const FtEmptyState({
    super.key,
    required this.icon,
    required this.headline,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.compactPadding = false,
  });

  final IconData icon;
  final String headline;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compactPadding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return FtCard(
      tinted: true,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: compactPadding ? AppSpacing.xl : AppSpacing.xxxl,
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: AppRadius.inner,
              border: Border.all(color: c.line),
            ),
            child: Icon(icon, size: 21, color: c.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            headline,
            style: context.text.displaySm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// A shimmering placeholder block. Skeletons preserve the shape of the content
/// that is coming, so the layout does not jump when data lands.
class FtSkeleton extends StatefulWidget {
  const FtSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadius.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<FtSkeleton> createState() => _FtSkeletonState();
}

class _FtSkeletonState extends State<FtSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour reduced motion: hold a flat tint instead of pulsing.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(c.lineSoft, c.line, _controller.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// Dashboard-shaped loading state.
class FtCardSkeleton extends StatelessWidget {
  const FtCardSkeleton({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FtSkeleton(width: 96, height: 11),
          const SizedBox(height: AppSpacing.md),
          const FtSkeleton(width: 168, height: 26),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < lines; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            const Row(
              children: [
                FtSkeleton(width: 38, height: 38, radius: AppRadius.sm),
                SizedBox(width: AppSpacing.md),
                Expanded(child: FtSkeleton(width: double.infinity, height: 12)),
                SizedBox(width: AppSpacing.xxl),
                FtSkeleton(width: 56, height: 12),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
