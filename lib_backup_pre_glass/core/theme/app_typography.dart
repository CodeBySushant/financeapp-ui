
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Three type roles, mirroring Fintrak's `--font-display` / `--font-sans` /
/// `--font-mono` split:
///
///  * **Fraunces** (serif) carries headlines and the one-line insight voice.
///    Used sparingly — it is the personality, not the workhorse.
///  * **Inter** carries all UI text.
///  * **JetBrains Mono** carries every monetary or numeric value, with tabular
///    figures so digits never shift width as amounts animate or update.
///
/// Widgets read these through `context.text`, never by calling GoogleFonts
/// directly, so swapping a face is a one-file change.
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

  /// Uppercase mono micro-label. Web: `.kicker`, 0.72rem / 0.14em tracking.
  final TextStyle kicker;

  /// Web `.display-xl` — screen titles.
  final TextStyle displayLg;

  /// Web `.display-lg` — section headings.
  final TextStyle displayMd;

  /// Card headings that still want the serif.
  final TextStyle displaySm;

  /// The AI insight / empty-state sentence. Serif at body size reads as a
  /// considered remark rather than UI chrome.
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
    TextStyle mono(double size, FontWeight w, {Color? color, double? h}) =>
        GoogleFonts.jetBrainsMono(
          fontSize: size,
          fontWeight: w,
          height: h,
          color: color ?? ink,
          letterSpacing: -0.01 * size,
          fontFeatures: _tabular,
        );

    TextStyle serif(double size, FontWeight w, double tracking, double h) =>
        GoogleFonts.fraunces(
          fontSize: size,
          fontWeight: w,
          height: h,
          color: ink,
          letterSpacing: tracking * size,
        );

    return AppText(
      kicker: GoogleFonts.jetBrainsMono(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.6,
        height: 1.2,
        color: muted,
      ),
      displayLg: serif(30, FontWeight.w500, -0.02, 1.06),
      displayMd: serif(23, FontWeight.w500, -0.015, 1.12),
      displaySm: serif(18, FontWeight.w500, -0.012, 1.2),
      voice: serif(16, FontWeight.w400, -0.005, 1.45),
      moneyXl: mono(32, FontWeight.w600, h: 1.1),
      moneyLg: mono(22, FontWeight.w600, h: 1.15),
      moneyMd: mono(15, FontWeight.w500, h: 1.25),
      moneySm: mono(13.5, FontWeight.w500, h: 1.3),
      numMeta: mono(12, FontWeight.w400, color: muted, h: 1.3),
    );
  }

  /// Inter for everything that is not a headline or a number.
  static TextTheme uiTextTheme(Color ink, Color muted) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ink,
        letterSpacing: -0.1,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 15.5, height: 1.5, color: ink),
      bodyMedium:
          base.bodyMedium?.copyWith(fontSize: 14, height: 1.5, color: ink),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12.5,
        height: 1.45,
        color: muted,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
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
