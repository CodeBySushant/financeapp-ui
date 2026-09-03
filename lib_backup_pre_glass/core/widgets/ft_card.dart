import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// The base surface. Fintrak expresses depth with a 1px hairline rather than a
/// shadow, so cards stay flat and legible in both themes and nothing looks like
/// it is hovering for no reason.
///
/// Set [raised] only for things that genuinely float above the page.
class FtCard extends StatelessWidget {
  const FtCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.raised = false,
    this.tinted = false,
    this.borderColor,
    this.radius = AppRadius.card,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Adds `shadow-premium`. Reserve for sheets and sticky surfaces.
  final bool raised;

  /// Fills with the quiet `--ft-surface` wash instead of the raised surface —
  /// used for insight and empty-state cards.
  final bool tinted;

  final Color? borderColor;
  final BorderRadius radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: tinted ? c.surface : c.surfaceRaised,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? c.line, width: 1),
        boxShadow: raised ? AppElevation.premium(c.shadow) : null,
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                splashFactory: InkSparkle.splashFactory,
                child: Padding(padding: padding, child: child),
              ),
            ),
    );

    if (semanticLabel == null) return content;
    return Semantics(
      container: true,
      label: semanticLabel,
      button: onTap != null,
      child: content,
    );
  }
}

/// A nested panel inside an [FtCard] — one radius step down, matching the web
/// dashboard's `rounded-2xl` outer / `rounded-xl` inner pairing.
class FtInnerCard extends StatelessWidget {
  const FtInnerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      radius: AppRadius.inner,
      padding: padding,
      child: child,
    );
  }
}

/// Header row for a card or page section: an optional kicker-style title on the
/// left and a quiet trailing action on the right.
class FtSectionHeader extends StatelessWidget {
  const FtSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: c.accent,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
