import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fixed cosmic gradient — never scrolls
          RepaintBoundary(child: CustomPaint(painter: _SkyGradientPainter(style: style))),
          // Star field — fewer stars on warm style
          RepaintBoundary(child: CustomPaint(painter: _StarPainter(style: style))),
          // App content
          child,
        ],
      ),
    );
  }
}

// ── Sky gradient ─────────────────────────────────────────────────────────────

class _SkyGradientPainter extends CustomPainter {
  const _SkyGradientPainter({this.style = CosmicStyle.night});
  final CosmicStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final LinearGradient skyGrad;
    if (style == CosmicStyle.warm) {
      // Warm peach/salmon top → orange mid → dark mountains
      // Lighter at top so dark serif text is readable
      skyGrad = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.10, 0.28, 0.52, 0.72, 0.88, 1.0],
        colors: [
          Color(0xFF1C0E06),
          Color(0xFF7B3818),
          Color(0xFFB06030),
          Color(0xFFCC7030),
          Color(0xFFD07C30),
          Color(0xFFA03A10),
          Color(0xFF060302),
        ],
      );
    } else {
      // Night sky: near-black top (stars pop), vivid fiery orange below
      skyGrad = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.08, 0.28, 0.50, 0.65, 0.80, 1.0],
        colors: [
          Color(0xFF050202),
          Color(0xFF140804),
          Color(0xFF6B1E00),
          Color(0xFFCC4E10),
          Color(0xFFE07228),
          Color(0xFFAA3C10),
          Color(0xFF050202),
        ],
      );
    }
    canvas.drawRect(rect, Paint()..shader = skyGrad.createShader(rect));

    // Wide amber horizon glow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.68),
        width: size.width * 1.6,
        height: size.height * 0.32,
      ),
      Paint()
        ..color = const Color(0xFFE87030).withOpacity(0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );

    // Shooting star / comet (top-left diagonal)
    final cometPaint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    cometPaint.shader = const LinearGradient(
      colors: [Color(0x00F0D080), Color(0xCCF8E890), Color(0x00F0D080)],
    ).createShader(Rect.fromPoints(
      Offset(size.width * 0.08, size.height * 0.06),
      Offset(size.width * 0.30, size.height * 0.12),
    ));
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.06),
      Offset(size.width * 0.30, size.height * 0.12),
      cometPaint,
    );
    // comet head glow
    canvas.drawCircle(
      Offset(size.width * 0.30, size.height * 0.12),
      2.5,
      Paint()
        ..color = const Color(0xFFF8E890).withOpacity(0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Mountain silhouette — matching mockup profile
    final hills = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.12, size.height * 0.74,
          size.width * 0.25, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.38, size.height * 0.69,
          size.width * 0.50, size.height * 0.76)
      ..quadraticBezierTo(size.width * 0.62, size.height * 0.67,
          size.width * 0.75, size.height * 0.79)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.72,
          size.width, size.height * 0.84)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hills, Paint()..color = const Color(0xFF060302));

    // Sun — large glowing orb on the horizon
    final sunX = size.width * 0.5;
    final sunY = size.height * 0.782;
    // Outer soft glow
    canvas.drawCircle(
      Offset(sunX, sunY), 70,
      Paint()
        ..color = const Color(0xFFFF8C20).withOpacity(0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
    // Mid glow
    canvas.drawCircle(
      Offset(sunX, sunY), 36,
      Paint()
        ..color = const Color(0xFFF5C040).withOpacity(0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // Sun disk
    canvas.drawCircle(
      Offset(sunX, sunY), 16,
      Paint()..color = const Color(0xFFFAE070),
    );

    // Water reflection — column of light from sun down
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.44, size.height * 0.79, size.width * 0.12, size.height * 0.21),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF5C040).withOpacity(0.30),
            const Color(0xFFF5C040).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(size.width * 0.44, size.height * 0.79, size.width * 0.12, size.height * 0.21))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(_SkyGradientPainter old) => old.style != style;
}

// ── Star field ───────────────────────────────────────────────────────────────

class _StarPainter extends CustomPainter {
  const _StarPainter({this.style = CosmicStyle.night});
  final CosmicStyle style;

  static final _rng = math.Random(42);
  static final _stars = List.generate(55, (_) => (
        x: _rng.nextDouble(),
        y: _rng.nextDouble() * 0.48,
        r: _rng.nextDouble() * 1.4 + 0.4,
        a: _rng.nextDouble() * 0.65 + 0.25,
      ));

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = style == CosmicStyle.warm ? 0.35 : 1.0;
    for (final s in _stars) {
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        Paint()..color = const Color(0xFFF0D080).withOpacity(s.a * opacity),
      );
    }
    // Constellation lines — dimmer on warm style
    final lineOpacity = style == CosmicStyle.warm ? 0.10 : 0.18;
    _constellationLines(canvas, size, lineOpacity, [
      Offset(size.width * 0.08, size.height * 0.04),
      Offset(size.width * 0.18, size.height * 0.07),
      Offset(size.width * 0.26, size.height * 0.03),
      Offset(size.width * 0.20, size.height * 0.12),
    ]);
    _constellationLines(canvas, size, lineOpacity, [
      Offset(size.width * 0.72, size.height * 0.03),
      Offset(size.width * 0.80, size.height * 0.08),
      Offset(size.width * 0.89, size.height * 0.04),
      Offset(size.width * 0.84, size.height * 0.13),
    ]);
  }

  void _constellationLines(Canvas canvas, Size size, double opacity, List<Offset> pts) {
    final p = Paint()
      ..color = const Color(0xFFC89030).withOpacity(opacity)
      ..strokeWidth = 0.7;
    for (var i = 0; i < pts.length - 1; i++) {
      canvas.drawLine(pts[i], pts[i + 1], p);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.style != style;
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
class CosmicBottomNav extends StatelessWidget {
  const CosmicBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_rounded,          label: 'Home'),
    (icon: Icons.psychology_outlined,   label: 'Insights'),
    (icon: Icons.auto_awesome,          label: ''),       // centre star
    (icon: Icons.spa_outlined,          label: 'Guidance'),
    (icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
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
            children: List.generate(_items.length, (i) {
              final item = _items[i];
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
