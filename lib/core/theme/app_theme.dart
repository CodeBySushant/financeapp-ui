import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';
import 'app_typography.dart';
import 'glass.dart';

/// Builds the light and dark themes from a [GlassPalette].
///
/// Both share every dimension, weight and radius; only colour differs. That is
/// deliberate — a theme switch that also moves things around reads as two
/// different apps rather than one app with a setting.
abstract final class AppTheme {
  static ThemeData light() => _build(GlassPalette.light);
  static ThemeData dark() => _build(GlassPalette.dark);

  static ThemeData _build(GlassPalette g) {
    final text = AppText.resolve(g.text, g.textMuted);
    final textTheme = AppText.uiTextTheme(g.text, g.textMuted).apply(
      bodyColor: g.text,
      displayColor: g.text,
    );

    final scheme =
        (g.isDark ? const ColorScheme.dark() : const ColorScheme.light())
            .copyWith(
      primary: g.accent,
      onPrimary: g.onAccent,
      secondary: g.accentAlt,
      onSecondary: g.onAccent,
      surface: g.canvasBottom,
      onSurface: g.text,
      error: g.danger,
      onError: g.onAccent,
      outline: g.stroke,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: g.isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[text, g],

      // GlassBackground paints the canvas once; every Scaffold above it must
      // let that show through.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashColor: g.accent.withValues(alpha: 0.10),
      highlightColor: g.accent.withValues(alpha: 0.05),
      dividerTheme: DividerThemeData(
        color: g.strokeSoft,
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(color: g.text),
        systemOverlayStyle:
            g.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: g.accent,
          foregroundColor: g.onAccent,
          disabledBackgroundColor: g.accent.withValues(alpha: 0.28),
          disabledForegroundColor: g.onAccent.withValues(alpha: 0.65),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: g.text,
          minimumSize: const Size(0, 50),
          side: BorderSide(color: g.stroke),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: g.accentAlt),
      ),

      iconTheme: IconThemeData(color: g.textSecondary, size: 22),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: g.surfaceLow,
        hintStyle: TextStyle(color: g.textMuted, fontSize: 14.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: _field(g.stroke),
        enabledBorder: _field(g.stroke),
        focusedBorder: _field(g.accent.withValues(alpha: 0.7)),
        errorBorder: _field(g.danger.withValues(alpha: 0.7)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: g.isDark ? const Color(0xFF161C2E) : g.text,
        contentTextStyle: TextStyle(
          color: g.isDark ? g.text : Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: g.stroke),
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _field(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color),
      );
}
