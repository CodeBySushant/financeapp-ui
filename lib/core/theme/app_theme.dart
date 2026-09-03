import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';
import 'app_typography.dart';
import 'glass.dart';

/// The app theme.
///
/// Fintrak is dark-only by design. Glass needs a rich backdrop to refract; a
/// light theme would flatten every frosted surface into a grey rectangle, so
/// there is no light variant rather than a bad one.
abstract final class AppTheme {
  static ThemeData glass() {
    final text = AppText.resolve(Glass.textPrimary, Glass.textMuted);
    final textTheme =
        AppText.uiTextTheme(Glass.textPrimary, Glass.textMuted).apply(
      bodyColor: Glass.textPrimary,
      displayColor: Glass.textPrimary,
    );

    final scheme = const ColorScheme.dark().copyWith(
      primary: Glass.violet,
      onPrimary: Colors.white,
      secondary: Glass.cyan,
      onSecondary: Glass.canvasDeep,
      surface: Glass.canvas,
      onSurface: Glass.textPrimary,
      error: Glass.danger,
      onError: Glass.canvasDeep,
      outline: Glass.white(0.14),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[text],

      // Transparent everywhere: AuroraBackground paints the canvas once, and
      // every Scaffold above it must let that show through.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashColor: Glass.white(0.06),
      highlightColor: Glass.white(0.03),
      dividerTheme: DividerThemeData(
        color: Glass.white(0.09),
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Glass.textPrimary,
        ),
        iconTheme: const IconThemeData(color: Glass.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Glass.violet,
          foregroundColor: Colors.white,
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
          foregroundColor: Glass.textPrimary,
          minimumSize: const Size(0, 50),
          side: BorderSide(color: Glass.white(0.18)),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Glass.cyan),
      ),

      iconTheme: const IconThemeData(color: Glass.textSecondary, size: 22),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Glass.white(0.06),
        hintStyle: const TextStyle(color: Glass.textMuted, fontSize: 14.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: _field(Glass.white(0.12)),
        enabledBorder: _field(Glass.white(0.12)),
        focusedBorder: _field(Glass.cyan.withValues(alpha: 0.65)),
        errorBorder: _field(Glass.danger.withValues(alpha: 0.65)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF161C2E),
        contentTextStyle: const TextStyle(
          color: Glass.textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Glass.white(0.14)),
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
