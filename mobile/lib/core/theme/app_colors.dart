import 'package:flutter/material.dart';

/// KundliAI colour system.
/// ONE theme throughout the entire app — the warm peach/terracotta cosmic sky
/// from InitialScreen_4. Cards and inputs float over it as cream surfaces.
abstract final class AppColors {
  // ── Cosmic sky (universal background) ───────────────────────────────────

  /// Very dark warm-brown base — top edge and hills
  static const cosmicBase   = Color(0xFF0E0806);
  static const cosmicSkyTop = Color(0xFF241510);
  static const cosmicSkyMid = Color(0xFF8B4830);

  /// Main peach/salmon horizon — the dominant hue of the reference screen
  static const cosmicSkyPeach = Color(0xFFC47858);
  static const cosmicSkyLight = Color(0xFFD4A07A);
  static const cosmicHills    = Color(0xFF0A0604);

  // ── Gold accent ─────────────────────────────────────────────────────────
  static const cosmicGold      = Color(0xFFC89030);
  static const cosmicGoldLight = Color(0xFFE0B860);
  static const cosmicGoldGlow  = Color(0xFFF0C878);

  // ── Zodiac wheel ────────────────────────────────────────────────────────
  static const cosmicWheelBg = Color(0xFF150D08);

  // ── Text on cosmic background ───────────────────────────────────────────
  /// Primary text — dark warm brown, readable against peach sky
  static const cosmicTextDark = Color(0xFF1C1008);
  static const cosmicTextMid  = Color(0xFF3A2418);
  static const cosmicTextLight = Color(0xFF7A5A40);

  // ── Card / surface ──────────────────────────────────────────────────────
  /// Cream card — floats over the cosmic bg
  static const cardBg    = Color(0xFFF5EDE0);
  /// Slightly darker cream — input fills, alt sections
  static const cardBgAlt = Color(0xFFEDE5D8);
  /// Card border
  static const cardBorder = Color(0xFFD4C0A0);

  // ── Dark feature cards (e.g. "Today's Cosmic Weather") ──────────────────
  static const featureDark      = Color(0xFF1B3D35);
  static const featureDarkLight = Color(0xFF2A5045);

  // ── Primary action buttons ───────────────────────────────────────────────
  static const btnBg   = Color(0xFF1A1208);  // near-black warm
  static const btnText = Color(0xFFE0B860);  // gold

  // ── Bottom nav ──────────────────────────────────────────────────────────
  static const navBg       = Color(0xFF1A0E08);  // dark warm, semi-opaque applied in code
  static const navActive   = Color(0xFFC89030);  // gold
  static const navInactive = Color(0xFFC0906A);  // muted warm

  // ── Life score colours ───────────────────────────────────────────────────
  static const scoreLove   = Color(0xFFE07878);
  static const scoreCareer = Color(0xFF48A070);
  static const scoreHealth = Color(0xFF6090C8);
  static const scoreMoney  = Color(0xFFC4A040);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const error   = Color(0xFFD94040);
  static const success = Color(0xFF48A070);
  static const white   = Color(0xFFFFFFFF);
  static const black   = Color(0xFF000000);
}
