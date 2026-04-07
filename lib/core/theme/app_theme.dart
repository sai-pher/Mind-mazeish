import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF1A1208);
  static const Color stone = Color(0xFF3D3020);
  static const Color parchment = Color(0xFFF5E6C8);
  static const Color torchAmber = Color(0xFFFF8C00);
  static const Color torchGold = Color(0xFFFFD700);
  static const Color dangerRed = Color(0xFFC0392B);
  static const Color textDark = Color(0xFF2C1810);
  static const Color textLight = Color(0xFFF5E6C8);
  static const Color stoneDark = Color(0xFF2A2015);
  static const Color stoneMid = Color(0xFF4E3D28);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.torchAmber,
        secondary: AppColors.torchGold,
        error: AppColors.dangerRed,
        onSurface: AppColors.textLight,
        onPrimary: AppColors.textDark,
      ),
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.stoneDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        titleTextStyle: GoogleFonts.cinzel(
          color: AppColors.torchAmber,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.torchAmber),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.stone,
          foregroundColor: AppColors.textLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppColors.stoneMid, width: 1),
          ),
          textStyle: GoogleFonts.lora(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.torchAmber,
        linearTrackColor: AppColors.stoneDark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.parchment,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.stoneMid, width: 2),
        ),
      ),
      dividerColor: AppColors.stoneMid,
      iconTheme: const IconThemeData(color: AppColors.torchAmber),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: GoogleFonts.cinzelDecorative(
        color: AppColors.torchAmber,
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.cinzelDecorative(
        color: AppColors.torchAmber,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.cinzel(
        color: AppColors.torchAmber,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      headlineMedium: GoogleFonts.cinzel(
        color: AppColors.textLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
      headlineSmall: GoogleFonts.cinzel(
        color: AppColors.textLight,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: GoogleFonts.cinzel(
        color: AppColors.textLight,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
      bodyLarge: GoogleFonts.lora(
        color: AppColors.textDark,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.lora(
        color: AppColors.textDark,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.lora(
        color: AppColors.textDark,
        fontSize: 12,
      ),
      labelLarge: GoogleFonts.lora(
        color: AppColors.textLight,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.lora(
        color: AppColors.textLight,
        fontSize: 13,
      ),
    );
  }
}
