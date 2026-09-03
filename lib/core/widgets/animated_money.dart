import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../utils/money.dart';

/// A monetary figure that counts to its new value instead of snapping.
///
/// The interpolation runs on the integer minor units and rebuilds a [Money] at
/// each frame, so no intermediate value is ever a double — the animation cannot
/// introduce a rounding artefact into a displayed balance.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({
    super.key,
    required this.value,
    required this.style,
    this.compact = false,
  });

  final Money value;
  final TextStyle style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      // begin only applies on first build, where counting up from zero is the
      // effect we want. Later rebuilds animate from the current value to the
      // new end, which is what TweenAnimationBuilder does automatically.
      tween: IntTween(begin: 0, end: value.minor),
      duration: AppMotion.of(context, const Duration(milliseconds: 620)),
      curve: AppMotion.emphasized,
      builder: (context, minor, _) {
        return Text(
          Money.fromMinor(minor, value.currency).format(compact: compact),
          style: style,
          semanticsLabel: value.semanticLabel(),
        );
      },
    );
  }
}
