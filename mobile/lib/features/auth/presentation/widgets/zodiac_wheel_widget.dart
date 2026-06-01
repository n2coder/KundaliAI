import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZodiacWheelWidget extends StatefulWidget {
  const ZodiacWheelWidget({super.key});

  @override
  State<ZodiacWheelWidget> createState() => _ZodiacWheelWidgetState();
}

class _ZodiacWheelWidgetState extends State<ZodiacWheelWidget>
    with TickerProviderStateMixin {
  late final AnimationController _rotCtrl;
  late final AnimationController _twinkleCtrl;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _twinkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load('assets/images/zodiac_wheel.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _image = frame.image);
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    _twinkleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    if (img == null) return const SizedBox.expand();
    return AnimatedBuilder(
      animation: Listenable.merge([_rotCtrl, _twinkleCtrl]),
      builder: (_, __) => CustomPaint(
        painter: _ZodiacWheelPainter(
          image: img,
          angle: _rotCtrl.value * 2 * math.pi,
          twinkle: _twinkleCtrl.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ── Geometry ──────────────────────────────────────────────────────────────────
//
// All radii are fractions of imgSize = min(displayedImageWidth, displayedImageHeight).
//
//  wheelOuterR  – outer clip boundary of the rotating ring (just outside the zodiac circles)
//  zodiacR      – distance from wheel center to each zodiac circle center
//  zodiacClipR  – clip radius for each zodiac symbol (matches visual circle size)
//  centerClipR  – radius of the inner moon area to keep upright

const double _wheelOuterFrac  = 0.400;
const double _zodiacRFrac     = 0.368;
const double _zodiacClipFrac  = 0.082;
const double _centerClipFrac  = 0.185;

// Zodiac angles: degrees clockwise from 12-o'clock.
// Aries at 15°, then every 30°: Aries, Taurus, Gemini, Cancer, Leo, Virgo,
// Libra, Scorpio, Sagittarius, Capricorn, Aquarius, Pisces.
const List<double> _zodiacDeg = [
  15, 45, 75, 105, 135, 165, 195, 225, 255, 285, 315, 345,
];

// Background star positions as fractions of (imageWidth, imageHeight).
// Approximate locations of golden sparkles in the 22.png background.
const List<(double, double)> _starPos = [
  (0.68, 0.04),
  (0.84, 0.13),
  (0.78, 0.07),
  (0.93, 0.24),
  (0.09, 0.27),
  (0.13, 0.43),
  (0.31, 0.06),
  (0.50, 0.93),
];

const List<double> _starPhase = [0.00, 0.25, 0.55, 0.12, 0.70, 0.38, 0.85, 0.45];

// ── Painter ───────────────────────────────────────────────────────────────────

class _ZodiacWheelPainter extends CustomPainter {
  const _ZodiacWheelPainter({
    required this.image,
    required this.angle,
    required this.twinkle,
  });

  final ui.Image image;
  final double angle;   // 0 → 2π, clockwise wheel rotation
  final double twinkle; // 0 → 1, drives star twinkle cycle

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    // BoxFit.contain scaling
    final scale = math.min(size.width / imgW, size.height / imgH);
    final dstW  = imgW * scale;
    final dstH  = imgH * scale;
    final dstX  = (size.width  - dstW) / 2;
    final dstY  = (size.height - dstH) / 2;

    final cx      = dstX + dstW / 2;
    final cy      = dstY + dstH / 2;
    final imgSize = math.min(dstW, dstH);

    final wheelOuterR = imgSize * _wheelOuterFrac;
    final zodiacR     = imgSize * _zodiacRFrac;
    final zodiacClipR = imgSize * _zodiacClipFrac;
    final centerClipR = imgSize * _centerClipFrac;

    final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
    final dstRect = Rect.fromLTWH(dstX, dstY, dstW, dstH);
    final paint   = Paint();

    // ── Layer 0: Static background — full image, no rotation ──────────────
    canvas.drawImageRect(image, srcRect, dstRect, paint);

    // ── Layer 1: Rotating wheel ring (clipped to outer wheel circle) ───────
    //   Draws the image rotated clockwise, but only within the wheel boundary.
    //   The background outside that circle is covered by Layer 0 (static).
    canvas.save();
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: wheelOuterR)));
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.translate(-cx, -cy);
    canvas.drawImageRect(image, srcRect, dstRect, paint);
    canvas.restore();

    // ── Layer 2: Counter-rotate each zodiac circle ─────────────────────────
    //   For each sign: clip to its current (rotated) screen position, then
    //   draw the ORIGINAL (unrotated) image shifted so the correct symbol
    //   appears there — net effect: symbol stays upright as the ring turns.
    for (final deg in _zodiacDeg) {
      final origRad = deg * math.pi / 180;

      // Where this circle was in the original image
      final origX = cx + zodiacR * math.sin(origRad);
      final origY = cy - zodiacR * math.cos(origRad);

      // Where it is now after the wheel rotated by `angle`
      final curRad = origRad + angle;
      final curX   = cx + zodiacR * math.sin(curRad);
      final curY   = cy - zodiacR * math.cos(curRad);

      canvas.save();
      canvas.clipPath(Path()
        ..addOval(Rect.fromCircle(
            center: Offset(curX, curY), radius: zodiacClipR)));
      // Shift unrotated image so original zodiac content lands at current pos
      canvas.translate(curX - origX, curY - origY);
      canvas.drawImageRect(image, srcRect, dstRect, paint);
      canvas.restore();
    }

    // ── Layer 3: Keep center moon upright ─────────────────────────────────
    //   The center doesn't move (it's at the rotation axis), so just clip
    //   and paint the original image — no position adjustment needed.
    canvas.save();
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: centerClipR)));
    canvas.drawImageRect(image, srcRect, dstRect, paint);
    canvas.restore();

    // ── Layer 4: Twinkling star sparkles in the background ─────────────────
    _paintTwinkles(canvas, dstX, dstY, dstW, dstH);
  }

  void _paintTwinkles(
      Canvas canvas, double dstX, double dstY, double dstW, double dstH) {
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final crossPaint = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < _starPos.length; i++) {
      final (fx, fy) = _starPos[i];
      final sx = dstX + fx * dstW;
      final sy = dstY + fy * dstH;

      // Sinusoidal opacity: dim ↔ bright, each star on its own phase
      final t     = 0.5 + 0.5 * math.sin(2 * math.pi * (twinkle + _starPhase[i]));
      final alpha = (0.15 + 0.85 * t).clamp(0.0, 1.0);
      final color = Color.fromARGB(
          (alpha * 255).round(), 255, 218, 100); // warm gold

      // Glow halo
      glowPaint.color = color.withValues(alpha: alpha * 0.5);
      canvas.drawCircle(Offset(sx, sy), 4, glowPaint);

      // 4-pointed cross sparkle
      crossPaint.color = color;
      const arm = 5.5;
      canvas.drawLine(Offset(sx - arm, sy), Offset(sx + arm, sy), crossPaint);
      canvas.drawLine(Offset(sx, sy - arm), Offset(sx, sy + arm), crossPaint);

      // Tiny bright centre dot
      canvas.drawCircle(Offset(sx, sy), 1.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_ZodiacWheelPainter old) =>
      old.angle != angle || old.twinkle != twinkle;
}
