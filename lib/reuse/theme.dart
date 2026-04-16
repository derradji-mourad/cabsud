import 'package:flutter/material.dart';

class AppTheme {
  // ─── Core Palette ───────────────────────────────────────────────────────────
  static const Color background = Color(0xFF06090F);   // Deep midnight black
  static const Color foreground = Color(0xFFF8F4EC);   // Warm ivory white
  static const Color primary    = Color(0xFFD4AF37);   // Metallic gold
  static const Color secondary  = Color(0xFFEDC967);   // Champagne accent
  static const Color accent     = Color(0xFFD4AF37);   // Same as primary
  static const Color muted      = Color(0xFF111827);   // Dark muted
  static const Color card       = Color(0xFF0D1117);   // Card surface
  static const Color border     = Color(0xFF1A2236);   // Subtle border
  static const Color luxuryGold = Color(0xFFC9A227);   // Deep burnished gold

  // ─── Named Aliases (full backwards-compat) ──────────────────────────────────
  static const Color primaryGold    = primary;
  static const Color lightGold      = Color(0xFFF2D675); // Champagne gold
  static const Color darkGold       = Color(0xFF8B6914); // Burnished dark gold
  static const Color accentGold     = secondary;
  static const Color champagneGold  = lightGold;

  static const Color richBlack      = background;
  static const Color obsidianBlack  = background;
  static const Color charcoal       = card;
  static const Color midnightBlack  = muted;
  static const Color deepCharcoal   = border;
  static const Color slate          = border;
  static const Color graphite       = muted;

  static const Color pureWhite  = foreground;
  static const Color softWhite  = foreground;
  static const Color warmWhite  = foreground;
  static const Color offWhite   = foreground;
  static const Color warmBeige  = luxuryGold;

  // ─── Spacing System ──────────────────────────────────────────────────────────
  static const double spaceXS = 4.0;
  static const double spaceS  = 8.0;
  static const double spaceM  = 16.0;
  static const double spaceL  = 24.0;
  static const double spaceXL = 32.0;

  // ─── Border Radius ───────────────────────────────────────────────────────────
  static const double radiusS  = 8.0;
  static const double radiusM  = 12.0;
  static const double radiusL  = 16.0;
  static const double radiusXL = 24.0;

  // ─── Theme Data ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary:                  primaryGold,
        secondary:                accentGold,
        tertiary:                 champagneGold,
        surface:                  muted,
        onPrimary:                background,
        onSecondary:              background,
        onSurface:                softWhite,
        surfaceContainerHighest:  charcoal,
        onSurfaceVariant:         offWhite,
      ),
      scaffoldBackgroundColor: background,
      canvasColor:  richBlack,
      cardColor:    charcoal,
      dividerColor: border,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: softWhite,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: softWhite),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: primaryGold, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: BorderSide(color: primaryGold.withValues(alpha: 0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusL),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.5),
        ),
        labelStyle:          TextStyle(color: offWhite.withValues(alpha: 0.7), fontSize: 14),
        floatingLabelStyle:  const TextStyle(color: primaryGold, fontSize: 13),
        hintStyle:           TextStyle(color: offWhite.withValues(alpha: 0.4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: richBlack,
          elevation: 8,
          shadowColor: primaryGold.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: charcoal,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: pureWhite,  letterSpacing: -1.0),
        displayMedium:  TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: softWhite,  letterSpacing: -0.5),
        displaySmall:   TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: softWhite,  letterSpacing: -0.3),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: softWhite,  letterSpacing: 0.1),
        bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: offWhite),
        bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: offWhite),
        labelLarge:     TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: softWhite,  letterSpacing: 0.3),
        labelMedium:    TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: offWhite,   letterSpacing: 0.5),
      ),
      iconTheme: const IconThemeData(color: primaryGold, size: 24),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: muted,
        contentTextStyle: const TextStyle(color: softWhite),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: softWhite,
        iconColor: primaryGold,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        titleTextStyle: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: softWhite, letterSpacing: 0.2,
        ),
        contentTextStyle: const TextStyle(fontSize: 14, color: offWhite, height: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXL)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: richBlack,
        selectedItemColor: primaryGold,
        unselectedItemColor: offWhite,
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;

  // ─── Gradients ───────────────────────────────────────────────────────────────

  static LinearGradient get primaryGoldGradient {
    return const LinearGradient(
      colors: [darkGold, primaryGold, lightGold, primaryGold],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  static LinearGradient get subtleGoldGradient {
    return const LinearGradient(
      colors: [darkGold, luxuryGold, primaryGold],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ─── Decorations ─────────────────────────────────────────────────────────────

  static BoxDecoration get luxuryBackgroundGradient {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          background,
          const Color(0xFF090E18),
          muted.withValues(alpha: 0.8),
          background,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ),
    );
  }

  static BoxDecoration get premiumCardDecoration {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radiusXL),
      border: Border.all(
        color: primaryGold.withValues(alpha: 0.15),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryGold.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 32,
          offset: const Offset(0, 16),
          spreadRadius: -4,
        ),
      ],
    );
  }

  // Glassmorphism card — use over images or backgrounds
  static BoxDecoration get glassDecoration {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(radiusXL),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.08),
        width: 1,
      ),
    );
  }

  // Elevated surface (slightly lighter than card)
  static BoxDecoration get elevatedSurfaceDecoration {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          muted,
          muted.withValues(alpha: 0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(radiusL),
      border: Border.all(
        color: primaryGold.withValues(alpha: 0.12),
        width: 1,
      ),
    );
  }
}
