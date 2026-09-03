import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/glass.dart';

/// The title block every non-home screen opens with.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Shows a back affordance. Needed by screens reached from somewhere other
  /// than the bar, which have no tab to indicate where they sit.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final top = MediaQuery.viewPaddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        top + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Semantics(
              button: true,
              label: 'Back',
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: g.isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.78),
                    border: Border.all(color: g.stroke, width: 0.8),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: g.text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: g.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 13, color: g.textMuted),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
