import 'package:flutter/material.dart';

/// 4pt spacing scale.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Horizontal page gutter. Widens on tablets so lines never over-run.
  static double gutter(double width) => width >= 905 ? xxxl : lg;
}

/// Radii.
///
/// A scale, not a constant. Using one generous radius on everything from a
/// full-width card to a 40px glyph is the flattest tell of a generated UI —
/// the corner should stay in proportion to the shape it belongs to, so a big
/// surface gets a slightly softer corner and a small control a tighter one.
/// Chips keep a true pill because that is a different shape language, not a
/// bigger version of the same one.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double control = 10;
  static const double lg = 12;

  /// The largest surfaces: the balance card, the nav bar.
  static const double hero = 14;

  /// Modal sheets, which meet the screen edge and want a softer meeting point.
  static const double sheetTop = 18;

  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius inner = BorderRadius.all(Radius.circular(control));
  static const BorderRadius tile = BorderRadius.all(Radius.circular(md));
  static const BorderRadius button = BorderRadius.all(Radius.circular(control));
  static const BorderRadius round = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(sheetTop));
}

/// Motion, ported from the web easing `cubic-bezier(0.22, 1, 0.36, 1)`.
///
/// Everything here must be gated on [MediaQuery.disableAnimationsOf] at the
/// call site — see `Motion.duration(context, ...)`.
abstract final class AppMotion {
  static const Curve emphasized = Cubic(0.22, 1, 0.36, 1);
  static const Curve standard = Curves.easeOutCubic;

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration base = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 700);

  /// Collapses to a single frame when the user has asked for reduced motion.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

/// `shadow-premium` / `shadow-premium-sm`. Used only where something genuinely
/// floats (sheets, the FAB, sticky headers) — cards use hairlines instead.
abstract final class AppElevation {
  static List<BoxShadow> premium(Color base) => [
        BoxShadow(
          color: base.withValues(alpha: 0.07),
          blurRadius: 40,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> premiumSm(Color base) => [
        BoxShadow(
          color: base.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}
