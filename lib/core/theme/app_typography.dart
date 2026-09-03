import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Two type roles.
///
///  * **Plus Jakarta Sans** carries every word in the interface — UI, headings,
///    labels. It has a tall x-height and geometric-humanist letterforms that
///    stay legible at 11px over a translucent surface, which Inter's flatter
///    forms do not do as well on glass.
///  * **Space Grotesk** carries every monetary and numeric value, with tabular
///    figures so digits never shift width as an amount updates.
///
/// The previous build used Fraunces for headlines and JetBrains Mono for money.
/// Both were wrong here: a serif is an editorial voice sitting inside a glass
/// interface, and a monospace makes a balance read like a code listing rather
/// than an amount of money.
///
/// Widgets read these through `context.text`, never by calling GoogleFonts
/// directly, so swapping a face stays a one-file change.
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
    TextStyle figure(double size, FontWeight w, {Color? color, double h = 1.15}) =>
        GoogleFonts.spaceGrotesk(
          fontSize: size,
          fontWeight: w,
          height: h,
          color: color ?? ink,
          letterSpacing: -0.018 * size,
          fontFeatures: _tabular,
        );

    TextStyle display(double size, FontWeight w, double tracking, double h) =>
        GoogleFonts.plusJakartaSans(
          fontSize: size,
          fontWeight: w,
          height: h,
          color: ink,
          letterSpacing: tracking * size,
        );

    return AppText(
      kicker: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.2,
        color: muted,
      ),
      displayLg: display(28, FontWeight.w700, -0.024, 1.08),
      displayMd: display(21, FontWeight.w600, -0.020, 1.15),
      displaySm: display(17, FontWeight.w600, -0.016, 1.22),
      voice: GoogleFonts.plusJakartaSans(
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: ink,
        letterSpacing: -0.05,
      ),
      moneyXl: figure(34, FontWeight.w700, h: 1.05),
      moneyLg: figure(22, FontWeight.w600),
      moneyMd: figure(15.5, FontWeight.w600, h: 1.25),
      moneySm: figure(14, FontWeight.w600, h: 1.3),
      numMeta: figure(12, FontWeight.w500, color: muted, h: 1.3),
    );
  }

  static TextTheme uiTextTheme(Color ink, Color muted) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.4,
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
