import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ── Modernist design tokens ──────────────────────────────────────────
/// Ported 1:1 from the `modernist` Claude Design system (ds-modernist.css):
/// flat, architectural, set entirely in Archivo — a single green accent on
/// paper, strong 2px dividers, and (mostly) zero corner radius. Nothing
/// floats; alignment and rule weight do the organising.
class AppColors {
  AppColors._();

  // ── Roles ──────────────────────────────────────────────────────────
  static const bg = Color(0xFFF3F2F2);
  static const surface = Color(0xFFEAE9E9);
  static const text = Color(0xFF201E1D);
  static const accent = Color(0xFF178A4F);

  /// color-mix(in srgb, #201e1d 40%, transparent)
  static const divider = Color(0x66201E1D);

  // ── Neutral ramp (OKLCH-generated, shared lightness scale) ──────────
  static const neutral100 = Color(0xFFF8F4F4);
  static const neutral200 = Color(0xFFEAE7E7);
  static const neutral300 = Color(0xFFD7D3D3);
  static const neutral400 = Color(0xFFBAB6B6);
  static const neutral500 = Color(0xFF9B9797);
  static const neutral600 = Color(0xFF7D7979);
  static const neutral700 = Color(0xFF605D5D);
  static const neutral800 = Color(0xFF444141);
  static const neutral900 = Color(0xFF2D2B2B);

  // ── Accent ramp ───────────────────────────────────────────────────
  static const accent100 = Color(0xFFE9F7EF);
  static const accent200 = Color(0xFFC8ECD7);
  static const accent300 = Color(0xFF97DAB3);
  static const accent400 = Color(0xFF5CBF88);
  static const accent500 = Color(0xFF2EA866);
  static const accent600 = Color(0xFF178A4F);
  static const accent700 = Color(0xFF106B3D);
  static const accent800 = Color(0xFF0B4D2C);
  static const accent900 = Color(0xFF08331E);

  /// Ink at a given opacity — for the many `opacity: .NN` overrides the
  /// prototype applies directly to `--color-text`.
  static Color ink(double opacity) => text.withValues(alpha: opacity);
}

/// ── Spacing / radius scale ────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
}

/// ── Typography ────────────────────────────────────────────────────────
/// Archivo for both heading and body, per the design system — headings at
/// weight 800.
class AppTypography {
  AppTypography._();

  static TextStyle heading(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.text,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
  }) =>
      GoogleFonts.robotoMono(fontSize: size, fontWeight: weight, color: color);
}

/// ── Theme ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      splashFactory: NoSplash.splashFactory,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        primary: AppColors.accent,
        onPrimary: AppColors.bg,
        secondary: AppColors.accent,
        onSecondary: AppColors.bg,
        error: AppColors.neutral900,
        outline: AppColors.divider,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.heading(18),
        iconTheme: const IconThemeData(color: AppColors.text, size: 20),
        actionsIconTheme: const IconThemeData(color: AppColors.text),
        shape: const Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      textTheme: GoogleFonts.archivoTextTheme(base.textTheme).copyWith(
        bodyLarge: AppTypography.body(15),
        bodyMedium: AppTypography.body(14),
        bodySmall: AppTypography.body(13, color: AppColors.ink(0.7)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: AppTypography.body(14, color: AppColors.bg),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
