import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../utils/money.dart';

/// Uppercase mono micro-label. Used sparingly — it is a signpost, not a heading.
class FtKicker extends StatelessWidget {
  const FtKicker(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: context.text.kicker.copyWith(color: color),
    );
  }
}

/// Status pill: full-radius, hue at 6% fill and 20% border, text at full
/// strength. Same recipe as the web `+12.4%` badge.
class FtPill extends StatelessWidget {
  const FtPill({
    super.key,
    required this.label,
    this.tone,
    this.icon,
    this.neutral = false,
  });

  final String label;
  final Color? tone;
  final IconData? icon;

  /// Renders on the quiet surface instead of a hue — for outgoing amounts,
  /// which Fintrak deliberately does not paint red.
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hue = tone ?? c.success;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: neutral ? c.surface : hue.withValues(alpha: 0.06),
        borderRadius: AppRadius.round,
        border: Border.all(
          color: neutral ? c.line : hue.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: neutral ? c.ink2 : hue),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: context.text.moneySm.copyWith(
              color: neutral ? c.ink2 : hue,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Category glyph: a squircle tinted to 8% of the category hue with the icon at
/// full strength. Carries category identity without shouting.
class FtIconTile extends StatelessWidget {
  const FtIconTile({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 38,
  });

  final IconData icon;
  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: AppRadius.tile,
      ),
      child: Icon(icon, size: size * 0.47, color: tone),
    );
  }
}

/// Budget / goal progress. Colour alone never carries the meaning — callers
/// pair this with a text figure, per the accessibility rule that financial
/// status must not be colour-only.
class FtProgressBar extends StatelessWidget {
  const FtProgressBar({
    super.key,
    required this.fraction,
    this.tone,
    this.height = 6,
    this.semanticLabel,
  });

  final double fraction;
  final Color? tone;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = fraction.clamp(0.0, 1.0);
    final fill = tone ?? c.budgetTone(fraction);

    return Semantics(
      label: semanticLabel,
      value: '${(fraction * 100).round()} percent',
      child: ClipRRect(
        borderRadius: AppRadius.round,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: AppMotion.of(context, AppMotion.slow),
          curve: AppMotion.emphasized,
          builder: (context, t, _) => LinearProgressIndicator(
            value: t,
            minHeight: height,
            backgroundColor: c.lineSoft,
            valueColor: AlwaysStoppedAnimation(fill),
          ),
        ),
      ),
    );
  }
}

/// Masks every monetary value beneath it. One toggle on the dashboard hides
/// amounts app-wide without each widget wiring up its own flag.
class PrivacyScope extends InheritedWidget {
  const PrivacyScope({
    super.key,
    required this.hidden,
    required super.child,
  });

  final bool hidden;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PrivacyScope>()?.hidden ??
      false;

  @override
  bool updateShouldNotify(PrivacyScope oldWidget) => hidden != oldWidget.hidden;
}

/// Renders a [Money] in tabular figures, respecting [PrivacyScope] and
/// optionally counting up to its value.
///
/// The counter interpolates the **integer minor units**, so the displayed
/// figure is a real amount at every frame rather than a rounded float.
class FtMoneyText extends StatelessWidget {
  const FtMoneyText(
    this.amount, {
    super.key,
    this.style,
    this.showSign = false,
    this.compact = false,
    this.animate = false,
    this.color,
    this.trimZeroDecimals = true,
  });

  final Money amount;
  final TextStyle? style;
  final bool showSign;
  final bool compact;
  final bool animate;
  final Color? color;
  final bool trimZeroDecimals;

  String _render(Money m) => m.format(
        showSign: showSign,
        compact: compact,
        trimZeroDecimals: trimZeroDecimals,
      );

  @override
  Widget build(BuildContext context) {
    final resolved =
        (style ?? context.text.moneyMd).copyWith(color: color);

    if (PrivacyScope.of(context)) {
      return ExcludeSemantics(
        child: Text(
          '\u2022' * 6,
          style: resolved.copyWith(
            color: (color ?? resolved.color)?.withValues(alpha: 0.35),
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    final text = Semantics(
      label: amount.semanticLabel(),
      excludeSemantics: true,
      child: animate && !MediaQuery.disableAnimationsOf(context)
          ? TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: amount.minor),
              duration: AppMotion.slow,
              curve: AppMotion.emphasized,
              builder: (context, minor, _) => Text(
                _render(Money.fromMinor(minor, amount.currency)),
                style: resolved,
              ),
            )
          : Text(_render(amount), style: resolved),
    );

    // Large amounts must shrink rather than clip when the user scales text up.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: text,
    );
  }
}

/// Hairline row divider used inside lists on a card.
class FtRowDivider extends StatelessWidget {
  const FtRowDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        indent: indent,
        color: context.colors.lineSoft,
      );
}
