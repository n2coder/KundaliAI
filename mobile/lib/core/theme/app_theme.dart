import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData build() {
    final base = ThemeData(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cosmicGold,
        secondary: AppColors.cosmicGoldLight,
        surface: AppColors.cosmicBase,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.cosmicBase,
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.cormorant(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.cosmicTextDark,
        ),
        displayMedium: GoogleFonts.cormorant(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppColors.cosmicTextDark,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.btnBg,
          foregroundColor: AppColors.btnText,
          elevation: 0,
          textStyle: GoogleFonts.cormorant(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.cosmicTextLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF25D366);
          }
          return AppColors.cardBorder;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: AppColors.cosmicTextLight),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.cosmicGold, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.cardBg,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
