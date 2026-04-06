import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Color Tokens ──────────────────────────────────────────────
class AColors {
  static const Color bg = Color(0xFF020205); // Absolute black for OLED
  static const Color surface = Color(0xFF0F0F1A);
  static const Color surfaceAlt = Color(0xFF141426);
  static const Color primary = Color(0xFF6366F1); // Modern Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color accent = Color(0xFF10B981); // Emerald Green
  static const Color error = Color(0xFFF43F5E); // Rose
  static const Color success = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSec = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFF475569);
  static const Color divider = Color(0xFF1E293B);

  // Premium Palette
  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color electricViolet = Color(0xFF7C3AED);

  // Glassmorphism
  static const Color glassBorder = Color(0x20FFFFFF);
  static const Color glassSurface = Color(0x10FFFFFF);

  // Shimmers
  static const Color shimmerBase = Color(0xFF0F172A);
  static const Color shimmerHigh = Color(0xFF1E293B);

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, neonPurple], // Indigo to Violet
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient premiumGradient = LinearGradient(
    colors: [
      primary,
      electricViolet,
      Color(0xFFC026D3)
    ], // Indigo -> Violet -> Fuchsia
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient glassGradient = LinearGradient(
    colors: [Color(0x20FFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x60000000),
      blurRadius: 30,
      offset: Offset(0, 15),
    ),
  ];

  static const BoxShadow glowShadow = BoxShadow(
    color: Color(0x406366F1),
    blurRadius: 20,
    spreadRadius: 2,
  );
}

// ── Theme ─────────────────────────────────────────────────────
class ATheme {
  static ThemeData get dark {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.outfitTextTheme(base.textTheme).apply(
      bodyColor: AColors.textPrimary,
      displayColor: AColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AColors.bg,
      primaryColor: AColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AColors.primary,
        secondary: AColors.accent,
        surface: AColors.surface,
        error: AColors.error,
        onPrimary: Colors.white,
        onSurface: AColors.textPrimary,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          letterSpacing: -1.5,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          letterSpacing: -0.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AColors.textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: AColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AColors.primary,
        unselectedItemColor: AColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AColors.surface,
        hintStyle: GoogleFonts.outfit(color: AColors.textHint, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AColors.divider, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ).copyWith(
          elevation: ButtonStyleButton.allOrNull(0),
        ),
      ),
      cardTheme: CardThemeData(
        color: AColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AColors.divider, width: 1),
        ),
      ),
      dividerColor: AColors.divider,
      iconTheme: const IconThemeData(color: AColors.textPrimary, size: 24),
      sliderTheme: SliderThemeData(
        activeTrackColor: AColors.primary,
        inactiveTrackColor: AColors.divider,
        thumbColor: Colors.white,
        overlayColor: AColors.primary.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
    );
  }
}

