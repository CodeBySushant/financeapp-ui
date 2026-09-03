import 'package:flutter/material.dart';

/// Colour tokens ported 1:1 from the Fintrak web design system
/// (`app/globals.css` -> `--ft-*`).
///
/// Nothing in the UI layer may hard-code a colour. Read them with
/// `context.colors.ink` instead.
///
/// Note on [ink]: on the web, Fintrak uses near-black `#111827` for BOTH the
/// primary text colour and the primary button fill. That pairing is what makes
/// the product read as a serious fintech tool rather than a template, so it is
/// preserved here. [onInk] is whatever sits legibly on top of it.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.faint,
    required this.onInk,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.line,
    required this.lineSoft,
    required this.shadow,
  });

  /// Page background.
  final Color canvas;

  /// Quiet inset surfaces (insight cards, chip backgrounds, disabled fields).
  final Color surface;

  /// Cards and sheets that sit above the canvas.
  final Color surfaceRaised;

  /// Primary text + primary action fill.
  final Color ink;

  /// Secondary text.
  final Color ink2;

  /// Supporting text, labels, kickers.
  final Color muted;

  /// Metadata, placeholders, disabled text.
  final Color faint;

  /// Legible foreground on top of [ink].
  final Color onInk;

  /// Focus rings, links, selected state. Deliberately NOT the primary fill.
  final Color accent;

  /// Income, under-budget, goal progress.
  final Color success;

  /// Approaching a budget limit.
  final Color warning;

  /// Over budget, destructive actions.
  final Color danger;

  /// Default hairline. Fintrak leans on borders rather than shadows.
  final Color line;

  /// Row dividers inside a bordered card.
  final Color lineSoft;

  /// Base colour for the `shadow-premium` elevation.
  final Color shadow;

  static const light = AppColors(
    canvas: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAFC),
    surfaceRaised: Color(0xFFFFFFFF),
    ink: Color(0xFF111827),
    ink2: Color(0xFF374151),
    muted: Color(0xFF6B7280),
    faint: Color(0xFF9CA3AF),
    onInk: Color(0xFFFFFFFF),
    accent: Color(0xFF2563EB),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    line: Color(0xFFE5E7EB),
    lineSoft: Color(0xFFF1F5F9),
    shadow: Color(0xFF111827),
  );

  /// Derived from `--ft-dark: #030712`. Semantic hues are lifted one step so
  /// they still clear 4.5:1 against a near-black canvas.
  static const dark = AppColors(
    canvas: Color(0xFF030712),
    surface: Color(0xFF0B1220),
    surfaceRaised: Color(0xFF0F1626),
    ink: Color(0xFFF9FAFB),
    ink2: Color(0xFFD1D5DB),
    muted: Color(0xFF9CA3AF),
    faint: Color(0xFF6B7280),
    onInk: Color(0xFF030712),
    accent: Color(0xFF60A5FA),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    line: Color(0xFF1F2937),
    lineSoft: Color(0xFF161F2F),
    shadow: Color(0xFF000000),
  );

  /// Category hues, carried over from `data/categories.js` so a category keeps
  /// the same colour on web and mobile.
  static const category = <String, Color>{
    'salary': Color(0xFF22C55E),
    'freelance': Color(0xFF06B6D4),
    'investments': Color(0xFF6366F1),
    'business': Color(0xFFEC4899),
    'rental': Color(0xFFF59E0B),
    'other-income': Color(0xFF64748B),
    'housing': Color(0xFFEF4444),
    'rent': Color(0xFFEF4444),
    'transport': Color(0xFFF97316),
    'groceries': Color(0xFF84CC16),
    'food': Color(0xFFEF4444),
    'utilities': Color(0xFF06B6D4),
    'bills': Color(0xFF06B6D4),
    'entertainment': Color(0xFF8B5CF6),
    'shopping': Color(0xFF2563EB),
    'health': Color(0xFF14B8A6),
    'education': Color(0xFF0EA5E9),
    'travel': Color(0xFFF43F5E),
    'subscriptions': Color(0xFFA855F7),
    'personal-care': Color(0xFFD946EF),
    'coffee': Color(0xFFB45309),
    'other': Color(0xFF64748B),
  };

  static Color forCategory(String? id) =>
      category[id?.toLowerCase()] ?? category['other']!;

  /// The colour a budget bar should take at [fraction] used.
  /// Thresholds match the web dashboard: calm until 75%, amber to 100%, red over.
  Color budgetTone(double fraction) {
    if (fraction >= 1.0) return danger;
    if (fraction >= 0.75) return warning;
    return success;
  }

  @override
  AppColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? ink,
    Color? ink2,
    Color? muted,
    Color? faint,
    Color? onInk,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
    Color? line,
    Color? lineSoft,
    Color? shadow,
  }) {
    return AppColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      onInk: onInk ?? this.onInk,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      line: line ?? this.line,
      lineSoft: lineSoft ?? this.lineSoft,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      ink: l(ink, other.ink),
      ink2: l(ink2, other.ink2),
      muted: l(muted, other.muted),
      faint: l(faint, other.faint),
      onInk: l(onInk, other.onInk),
      accent: l(accent, other.accent),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      line: l(line, other.line),
      lineSoft: l(lineSoft, other.lineSoft),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
