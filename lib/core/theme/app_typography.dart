import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One typeface, used for everything.
///
/// Reversing an earlier decision here. Plus Jakarta Sans and Space Grotesk both
/// have real personality, and that was the problem: the brief is now "premium,
/// like Apple", and Apple's type voice is a neutral grotesque with almost no
/// personality at all — the restraint *is* the style. Inter is the closest open
/// equivalent to SF Pro, so it carries UI, headings and money alike, with
/// tabular figures on anything numeric so digits never shift width.
///
/// The premium signal comes from the scale, not the face: tight negative
/// tracking on large sizes, semibold rather than bold, and a wide gap between
/// the largest and smallest steps.
@immutable
class AppText extends ThemeExtension<AppText> {
  const AppText({
    required this.kicker,
    required this.displayLg,
    required this.displayMd,
    required this.displaySm,
    required this.voice,
    required this.moneyXl,
    required this.moneyLg,
    required this.moneyMd,
    required this.moneySm,
    required this.numMeta,
  });

  /// Small supporting label above or beside a value.
  final TextStyle kicker;

  /// Screen titles.
  final TextStyle displayLg;

  /// Section headings.
  final TextStyle displayMd;

  /// Card headings.
  final TextStyle displaySm;

  /// The insight sentence and empty-state copy.
  final TextStyle voice;

  /// Hero balance.
  final TextStyle moneyXl;

  /// Section totals, goal amounts.
  final TextStyle moneyLg;

  /// Transaction row amounts.
  final TextStyle moneyMd;

  /// Inline amounts inside sentences.
  final TextStyle moneySm;

  /// Dates, counts, percentages in metadata rows.
  final TextStyle numMeta;

  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  static AppText resolve(Color ink, Color muted) {
    // Money. Negative tracking scales with size so large figures stay tight and
    // small ones stay readable.
    TextStyle figure(double size, FontWeight w, {Color? color, double h = 1.1}) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: w,
          height: h,
          color: color ?? ink,
          // Apple's hallmark: the bigger the type, the tighter the tracking.
          letterSpacing: -0.026 * size,
          fontFeatures: _tabular,
        );

    TextStyle display(double size, FontWeight w, double tracking, double h) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: w,
          height: h,
          color: ink,
          letterSpacing: tracking * size,
        );

    return AppText(
      kicker: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.2,
        color: muted,
      ),
      displayLg: display(30, FontWeight.w600, -0.028, 1.06),
      displayMd: display(22, FontWeight.w600, -0.022, 1.14),
      displaySm: display(17, FontWeight.w600, -0.016, 1.24),
      voice: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: ink,
        letterSpacing: -0.16,
      ),
      moneyXl: figure(46, FontWeight.w600, h: 1.0),
      moneyLg: figure(24, FontWeight.w600, h: 1.1),
      moneyMd: figure(16, FontWeight.w500, h: 1.25),
      moneySm: figure(14.5, FontWeight.w500, h: 1.3),
      numMeta: figure(12.5, FontWeight.w400, color: muted, h: 1.3),
    );
  }

  static TextTheme uiTextTheme(Color ink, Color muted) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ink,
        letterSpacing: -0.5,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ink,
        letterSpacing: -0.15,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: ink,
        letterSpacing: -0.1,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 15.5,
        height: 1.5,
        color: ink,
        letterSpacing: -0.1,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.5,
        color: ink,
        letterSpacing: -0.05,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12.5,
        height: 1.45,
        color: muted,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
      ),
      labelMedium: base.labelMedium?.copyWith(fontSize: 12.5, color: muted),
    );
  }

  @override
  AppText copyWith({
    TextStyle? kicker,
    TextStyle? displayLg,
    TextStyle? displayMd,
    TextStyle? displaySm,
    TextStyle? voice,
    TextStyle? moneyXl,
    TextStyle? moneyLg,
    TextStyle? moneyMd,
    TextStyle? moneySm,
    TextStyle? numMeta,
  }) {
    return AppText(
      kicker: kicker ?? this.kicker,
      displayLg: displayLg ?? this.displayLg,
      displayMd: displayMd ?? this.displayMd,
      displaySm: displaySm ?? this.displaySm,
      voice: voice ?? this.voice,
      moneyXl: moneyXl ?? this.moneyXl,
      moneyLg: moneyLg ?? this.moneyLg,
      moneyMd: moneyMd ?? this.moneyMd,
      moneySm: moneySm ?? this.moneySm,
      numMeta: numMeta ?? this.numMeta,
    );
  }

  @override
  AppText lerp(covariant AppText? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppText(
      kicker: l(kicker, other.kicker),
      displayLg: l(displayLg, other.displayLg),
      displayMd: l(displayMd, other.displayMd),
      displaySm: l(displaySm, other.displaySm),
      voice: l(voice, other.voice),
      moneyXl: l(moneyXl, other.moneyXl),
      moneyLg: l(moneyLg, other.moneyLg),
      moneyMd: l(moneyMd, other.moneyMd),
      moneySm: l(moneySm, other.moneySm),
      numMeta: l(numMeta, other.numMeta),
    );
  }
}

extension AppTextX on BuildContext {
  AppText get text => Theme.of(this).extension<AppText>()!;
}
