import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../i18n/app_strings.dart';
import '../i18n/lang_provider.dart';
import '../theme/app_colors.dart';

/// Background style — night for splash, warm for all auth/content screens.
enum CosmicStyle { night, warm }

/// Universal scaffold used by EVERY screen in the app.
/// Paints the cosmic sky as the persistent background layer.
/// Use [style] = [CosmicStyle.night] (default) for the splash dark-sky look,
/// or [CosmicStyle.warm] for auth screens (warmer, lighter top for dark text).
class CosmicScaffold extends StatelessWidget {
  const CosmicScaffold({
    super.key,
    required this.child,
    this.style = CosmicStyle.night,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget child;
  final CosmicStyle style;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    // Light status-bar icons read well over the dark, scrimmed artwork.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return Scaffold(
      backgroundColor: AppColors.cosmicBase,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Shared cosmic background artwork — fixed, never scrolls.
          Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          // Contrast scrim: the artwork has a very bright amber sun-band in the
          // middle, so a graduated dark overlay keeps white headers, gold
          // accents and cream cards readable on every screen, while still
          // letting the dark starfield (top) and mountains (bottom) show.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x4D000000), // ~30% — top / header band (dark sky)
                  Color(0x66000000), // ~40% — mid (tames the bright sun)
                  Color(0x80000000), // ~50% — bottom / nav band
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // App content
          child,
        ],
      ),
    );
  }
}

// ── Reusable shared widgets ───────────────────────────────────────────────────

/// Gold 4-pointed star in a circle — top of every auth screen.
class CosmicStarBadge extends StatelessWidget {
  const CosmicStarBadge({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cosmicGold, width: 1.4),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.48, size * 0.48),
          painter: _FourStarPainter(color: AppColors.cosmicGold),
        ),
      ),
    );
  }
}

class _FourStarPainter extends CustomPainter {
  const _FourStarPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.width / 2;
    final inner = outer * 0.25;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final r = i.isEven ? outer : inner;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FourStarPainter old) => old.color != color;
}

/// ── line ✦ line — divider used under auth screen titles.
class CosmicDivider extends StatelessWidget {
  const CosmicDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
            width: 40, height: 0.8,
            color: AppColors.cosmicGold.withOpacity(0.5)),
        const SizedBox(width: 8),
        const Icon(Icons.auto_awesome, color: AppColors.cosmicGold, size: 11),
        const SizedBox(width: 8),
        Container(
            width: 40, height: 0.8,
            color: AppColors.cosmicGold.withOpacity(0.5)),
      ],
    );
  }
}

/// Floating planet helper — used on loading + phone screens.
class FloatingPlanet extends StatelessWidget {
  const FloatingPlanet({
    super.key,
    required this.size,
    this.hasRing = false,
  });
  final double size;
  final bool hasRing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: hasRing ? size * 2.4 : size,
      height: hasRing ? size * 1.0 : size,
      child: CustomPaint(painter: _PlanetPainter(size: size, hasRing: hasRing)),
    );
  }
}

class _PlanetPainter extends CustomPainter {
  const _PlanetPainter({required this.size, required this.hasRing});
  final double size;
  final bool hasRing;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;

    if (hasRing) {
      // Ring behind
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: size * 2.2, height: size * 0.55),
        Paint()
          ..color = AppColors.cosmicGold.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawCircle(
      Offset(cx, cy),
      size / 2,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFD4A060), Color(0xFFA07030), Color(0xFF603818)],
        ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: size / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cream card floating over cosmic bg.
class CosmicCard extends StatelessWidget {
  const CosmicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18.0,
    this.color = AppColors.cardBg,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.cosmicBase.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Universal AppBar for non-auth app screens — transparent over cosmic bg.
class CosmicAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CosmicAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading: leading ??
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.cosmicTextDark, size: 18),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
      title: Text(title,
          style: GoogleFonts.cormorant(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.cosmicTextDark,
          )),
      actions: actions,
      iconTheme: const IconThemeData(color: AppColors.cosmicTextDark),
    );
  }
}

/// Universal bottom nav — dark warm bg with gold active icons.
class CosmicBottomNav extends ConsumerWidget {
  const CosmicBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final items = [
      (icon: Icons.home_rounded,           label: AppStrings.tr('nav_home', lang)),
      (icon: Icons.psychology_outlined,    label: AppStrings.tr('nav_insights', lang)),
      (icon: Icons.auto_awesome,           label: ''), // centre star
      (icon: Icons.spa_outlined,           label: AppStrings.tr('nav_guidance', lang)),
      (icon: Icons.person_outline_rounded, label: AppStrings.tr('nav_profile', lang)),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBg.withOpacity(0.94),
        border: Border(
          top: BorderSide(
              color: AppColors.cosmicGold.withOpacity(0.25), width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = currentIndex == i;
              if (i == 2) {
                // Centre cosmic action button
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: Center(
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cosmicGold,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cosmicGold.withOpacity(0.45),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: AppColors.cosmicBase, size: 22),
                      ),
                    ),
                  ),
                );
              }
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: active
                            ? AppColors.navActive
                            : AppColors.navInactive,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: active
                              ? AppColors.navActive
                              : AppColors.navInactive,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
