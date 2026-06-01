import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// KundliAI typography — one palette, every screen.
/// Headings: Cormorant (bundled serif).
/// Body / UI: DM Sans via google_fonts.
abstract final class AppTextStyles {
  // ── Serif headings (Cormorant) ──────────────────────────────────────────

  static TextStyle displayLarge({Color color = AppColors.cosmicTextDark}) =>
      GoogleFonts.cormorant(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle displayMedium({Color color = AppColors.cosmicTextDark}) =>
      GoogleFonts.cormorant(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle headingLarge({Color color = AppColors.cosmicTextDark}) =>
      GoogleFonts.cormorant(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );

  static TextStyle headingMedium({Color color = AppColors.cosmicTextDark}) =>
      GoogleFonts.cormorant(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.25,
      );

  // ── Sans body (DM Sans) ────────────────────────────────────────────────

  static TextStyle bodyLarge({Color color = AppColors.cosmicTextDark}) =>
      GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.55,
      );

  static TextStyle bodyMedium({Color color = AppColors.cosmicTextMid}) =>
      GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.55,
      );

  static TextStyle bodySmall({Color color = AppColors.cosmicTextLight}) =>
      GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle labelLarge({Color color = AppColors.cosmicTextDark}) =>
      GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.1,
      );

  static TextStyle labelMedium({Color color = AppColors.cosmicTextMid}) =>
      GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle labelSmall({Color color = AppColors.cosmicTextLight}) =>
      GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.4,
      );

  static TextStyle buttonText({Color color = AppColors.btnText}) =>
      GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      );

  /// All-caps small label — used for section headers on cosmic bg
  static TextStyle sectionCaps({Color color = AppColors.cosmicGold}) =>
      GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.8,
      );
}
