import 'package:flutter/material.dart';

/// Zodiac wheel — displays the illustrated wheel image as a static background.
class ZodiacWheel extends StatelessWidget {
  const ZodiacWheel({
    super.key,
    this.size = 280,
    this.spinning = false,           // kept for API compat, ignored
    this.spinDuration = const Duration(seconds: 40), // kept for API compat
  });

  final double size;
  final bool spinning;
  final Duration spinDuration;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/zodiac_wheel.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
