import 'package:flutter/material.dart';

class AppTheme {
  // Luxury color palette - Gold & Premium Black theme
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFF7EF8A);
  static const Color darkGold = Color(0xFFAE8625);
  static const Color accentGold = Color(0xFFEDC967);
  static const Color champagneGold = Color(0xFFBEA98E);

  // Premium Black Palette (inspired by luxury brands)
  static const Color richBlack = Color(0xFF0A0A0A);
  static const Color obsidianBlack = Color(0xFF0C0C0C);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color midnightBlack = Color(0xFF121212);
  static const Color deepCharcoal = Color(0xFF1C1C1C);
  static const Color slate = Color(0xFF2C2C2C);
  static const Color graphite = Color(0xFF1E1E1E);

  // White & Text Colors (off-white for better readability)
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softWhite = Color(0xFFF5F5F5);
  static const Color warmWhite = Color(0xFFFAFAFA);
  static const Color offWhite = Color(0xFFE0E0E0);
  static const Color warmBeige = Color(0xFFF5E8D8);

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
        background: obsidianBlack,
        onPrimary: richBlack,
        onSecondary: richBlack,
        onSurface: softWhite,
        onBackground: softWhite,
        surfaceVariant: charcoal,
        onSurfaceVariant: offWhite,
      ),
      scaffoldBackgroundColor: obsidianBlack,
      canvasColor: richBlack,
      cardColor: charcoal,
      dividerColor: slate,

      // FIXED: Only ONE appBarTheme declaration
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: richBlack,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: richBlack),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: deepCharcoal,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryGold, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: champagneGold.withOpacity(0.3), width: 1),
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
        labelStyle: TextStyle(color: offWhite.withOpacity(0.8), fontSize: 14),
        floatingLabelStyle: const TextStyle(color: primaryGold, fontSize: 14),
        hintStyle: TextStyle(color: offWhite.withOpacity(0.5)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: richBlack,
          elevation: 12,
          shadowColor: primaryGold.withOpacity(0.5),
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
        shadowColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: pureWhite),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: softWhite),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: softWhite),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: softWhite),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: offWhite),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: offWhite),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: softWhite),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: offWhite),
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

      // FIXED: Changed DialogTheme to DialogThemeData
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

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryGold,
        secondary: accentGold,
        tertiary: champagneGold,
        surface: warmWhite,
        background: warmWhite,
        onPrimary: richBlack,
        onSecondary: richBlack,
        onSurface: richBlack,
        onBackground: richBlack,
        surfaceVariant: Color(0xFFF5F5F5),
        onSurfaceVariant: Color(0xFF424242),
      ),
      scaffoldBackgroundColor: warmWhite,
      canvasColor: pureWhite,
      cardColor: pureWhite,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: richBlack,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: richBlack),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryGold, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: champagneGold.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        labelStyle: TextStyle(color: richBlack.withOpacity(0.7), fontSize: 14),
        floatingLabelStyle: const TextStyle(color: primaryGold, fontSize: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: richBlack,
          elevation: 8,
          shadowColor: primaryGold.withOpacity(0.4),
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
        color: pureWhite,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: richBlack),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: richBlack),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: richBlack),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: richBlack),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: richBlack),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: richBlack),
      ),

      iconTheme: const IconThemeData(
        color: primaryGold,
        size: 24,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: pureWhite,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: richBlack,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: richBlack,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),
    );
  }

  // Luxury gradient background (black with subtle variations)
  static BoxDecoration get luxuryBackgroundGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          obsidianBlack,
          richBlack,
          midnightBlack,
          obsidianBlack,
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  // Premium card with dark background and gold accents
  static BoxDecoration get premiumCardDecoration {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          charcoal,
          deepCharcoal,
          slate.withOpacity(0.5),
        ],
      ),
      borderRadius: BorderRadius.circular(radiusL),
      border: Border.all(
        color: primaryGold.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryGold.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
