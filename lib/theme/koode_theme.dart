import 'package:flutter/material.dart';

/// Koode Design System Tokens & Theme
/// Aligned strictly with the Koode Family Dashboard UI/UX Specification.
class KoodeColors {
  // Brand & Surface Tokens
  static const canvas = Color(0xFFF6F2E8); // Main warm background
  static const surface = Color(0xFFFFFDF8); // Cards and sheets
  static const surfaceVariant = Color(0xFFF0EBE0); // Subtle card contrast
  static const ink = Color(0xFF26271F); // Primary text
  static const secondaryText = Color(0xFF66675E); // Supporting text
  static const olive = Color(0xFF343B2D); // Navigation, selected controls, primary brand accent
  static const oliveLight = Color(0xFFEBEFE7); // Subtle olive tint

  // Status Tokens
  static const sage = Color(0xFF78866A); // Fine / completed state
  static const sageLight = Color(0xFFEFF3EC); // Sage background tint
  static const concern = Color(0xFFA56D24); // Concern / follow-up state
  static const concernLight = Color(0xFFFDF6EC); // Concern background tint
  static const emergency = Color(0xFFB74638); // Active emergency only
  static const emergencyLight = Color(0xFFFDF0EF); // Emergency background tint
  static const unknown = Color(0xFF77786F); // Unanswered / unavailable status
  static const unknownLight = Color(0xFFF1F1EE); // Unknown background tint

  // Structural Tokens
  static const divider = Color(0xFFE5DFD2); // Separators and quiet borders
  static const cardBorder = Color(0xFFE2DCD0); // Subtle card outline
}

class KoodeTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: KoodeColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: KoodeColors.olive,
        onPrimary: Colors.white,
        secondary: KoodeColors.sage,
        onSecondary: Colors.white,
        surface: KoodeColors.surface,
        onSurface: KoodeColors.ink,
        error: KoodeColors.emergency,
        onError: Colors.white,
      ),
      fontFamily: 'Roboto',
      dividerTheme: const DividerThemeData(
        color: KoodeColors.divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: KoodeColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KoodeColors.cardBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: KoodeColors.olive),
        titleTextStyle: TextStyle(
          color: KoodeColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: KoodeColors.surface,
        selectedItemColor: KoodeColors.olive,
        unselectedItemColor: KoodeColors.secondaryText,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KoodeColors.olive,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KoodeColors.olive,
          minimumSize: const Size(48, 52),
          side: const BorderSide(color: KoodeColors.olive, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KoodeColors.olive,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Refined Serif Page Headings (Warm Editorial Minimalism)
  static const TextStyle displayTitle = TextStyle(
    fontFamily: 'serif',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: KoodeColors.ink,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: KoodeColors.ink,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: KoodeColors.ink,
    height: 1.4,
  );

  static const TextStyle metadata = TextStyle(
    fontSize: 14,
    color: KoodeColors.secondaryText,
    height: 1.3,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
}
