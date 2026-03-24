import 'package:flutter/material.dart';

class AppTheme {
  // New Luxury Palette
  static const Color background = Color(0xFF0B0F14); // Deep Navy Black
  static const Color foreground = Color(0xFFFFFFFF); // Primary White
  static const Color primary = Color(0xFFD4AF37); // Rich Gold
  static const Color secondary = Color(0xFFE6C76A); // Soft Gold
  static const Color accent = Color(0xFFB8963E); // Muted Gold
  static const Color muted = Color(0xFF1A2233); // Soft Dark Gradient tone
  static const Color card = Color(0xFF11151F); // Dark Card
  static const Color border = Color(0xFF1C2230); // Slightly elevated surface
  static const Color luxuryGold = Color(0xFFD4AF37); // Warm bronze gold

  // Mapping to existing names to maintain compatibility while switching logic
  static const Color primaryGold = primary;
  static const Color lightGold = secondary;
  static const Color darkGold = accent;
  static const Color accentGold = primary;
  static const Color champagneGold = secondary;

  // Black/Dark mappings
  static const Color richBlack = background;
  static const Color obsidianBlack = Color(0xFF121826);
  static const Color charcoal = card;
  static const Color midnightBlack = Color(0xFF121826);
  static const Color deepCharcoal = border;
  static const Color slate = Color(0xFF1A2233);
  static const Color graphite = Color(0xFF1A2233);

  // White mappings
  static const Color pureWhite = foreground;
  static const Color softWhite = Color(0xFFB0B3B8); // Secondary Text
  static const Color warmWhite = foreground;
  static const Color offWhite = Color(0xFFB0B3B8);
  static const Color warmBeige = secondary;

  // Spacing system
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;

  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: accentGold,
        tertiary: champagneGold,
        surface: midnightBlack,
        onPrimary: background, // text on gold should be dark
        onSecondary: background,
        onSurface: softWhite,
        surfaceContainerHighest: charcoal,
        onSurfaceVariant: offWhite,
      ),
      scaffoldBackgroundColor: obsidianBlack,
      canvasColor: richBlack,
      cardColor: charcoal,
      dividerColor: slate,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: softWhite,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: softWhite),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: deepCharcoal,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryGold, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide:
              BorderSide(color: champagneGold.withValues(alpha: 0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        labelStyle:
            TextStyle(color: offWhite.withValues(alpha: 0.8), fontSize: 14),
        floatingLabelStyle: const TextStyle(color: primaryGold, fontSize: 14),
        hintStyle: TextStyle(color: offWhite.withValues(alpha: 0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: richBlack,
          elevation: 12,
          shadowColor: primaryGold.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: charcoal,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: pureWhite),
        displayMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: softWhite),
        displaySmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, color: softWhite),
        headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: softWhite),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.normal, color: offWhite),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.normal, color: offWhite),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: softWhite),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: offWhite),
      ),
      iconTheme: const IconThemeData(
        color: primaryGold,
        size: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: slate,
        contentTextStyle: const TextStyle(color: softWhite),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: softWhite,
        iconColor: primaryGold,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: charcoal,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: softWhite,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: offWhite,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: richBlack,
        selectedItemColor: primaryGold,
        unselectedItemColor: offWhite,
      ),
    );
  }

  // NOTE: Light theme is also updated to use the new "Premium" colors basically keeping it dark-ish or using the foreground/background as requested.
  // The user asked "Colors used in ALL screen". A "Dark Gold" theme usually implies a dark mode look.
  // However, I will preserve the lightTheme getters but using the new colors which might make it look dark anyway or I should inverse?
  // User: "change the colors used in all the screen with THESE colors". constants provided.
  // This implies the whole app should look like this palette (Dark Blue + Gold).
  // So likely the Light Theme should also be this Dark Theme or very similar.
  // I will make `lightTheme` return the same as `darkTheme` or map it to this palette.
  // For safety, I'll update lightTheme to use the same palette because "background = Deep dark blue" implies the background IS dark blue.

  static ThemeData get lightTheme {
    // returning dark theme configuration because the requested palette IS dark.
    // background = 0xFF010817 (Dark Blue)
    return darkTheme;
  }

  // Rich Gold Gradient (CTA Button)
  static LinearGradient get primaryGoldGradient {
    return const LinearGradient(
      colors: [
        Color(0xFFE6C76A),
        Color(0xFFD4AF37),
        Color(0xFFB8963E),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Luxury gradient background (Main screen)
  static BoxDecoration get luxuryBackgroundGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF0B0F14),
          Color(0xFF121826),
          Color(0xFF1A2233),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  // Premium card with dark background and gold accents (Subtle fade effect)
  static BoxDecoration get premiumCardDecoration {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF0B0F14).withValues(alpha: 0.8),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      color: card,
      borderRadius: BorderRadius.circular(radiusL),
      border: Border.all(
        color: primaryGold.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryGold.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
