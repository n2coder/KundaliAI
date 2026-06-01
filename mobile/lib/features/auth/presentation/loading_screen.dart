import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';
import '../../../core/widgets/zodiac_wheel.dart';

/// InitialScreen_4 — THE REFERENCE SCREEN.
/// Warm peach/terracotta sky, spinning zodiac wheel with Saturn (ring) floating
/// left and Jupiter floating right, gold progress bar, 4 step icons.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progressCtrl;
  late final Animation<double> _progress;
  int _step = 0;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..addListener(() => setState(() {}));
    _progress =
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut);
    _progressCtrl.forward();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (_step < 3) {
        setState(() => _step++);
      } else {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.go('/home');
        });
      }
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wheelSize = w * 0.76;

    return CosmicScaffold(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Star badge
            const CosmicStarBadge(size: 52),
            const SizedBox(height: 16),

            // Title + divider
            Text(
              'Verifying Your Number',
              style: AppTextStyles.displayMedium(
                  color: AppColors.cosmicTextDark),
            ),
            const SizedBox(height: 6),
            const CosmicDivider(),
            const SizedBox(height: 6),
            Text(
              'Aligning the stars for your cosmic journey...',
              style: AppTextStyles.bodyMedium(
                  color: AppColors.cosmicTextMid),
            ),
            const SizedBox(height: 18),

            // ── Zodiac wheel with flanking planets ───────────────────────
            Expanded(
              child: Center(
                child: SizedBox(
                  width: w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The wheel
                      ZodiacWheel(
                        size: wheelSize,
                        spinning: true,
                        spinDuration: const Duration(seconds: 20),
                      ),

                      // Saturn (with ring) — left of wheel
                      Positioned(
                        left: w * 0.01,
                        top: wheelSize * 0.18,
                        child: const FloatingPlanet(size: 38, hasRing: true),
                      ),

                      // Jupiter — right of wheel
                      Positioned(
                        right: w * 0.01,
                        top: wheelSize * 0.14,
                        child: const FloatingPlanet(size: 30, hasRing: false),
                      ),

                      // Small moon — lower right
                      Positioned(
                        right: w * 0.06,
                        bottom: wheelSize * 0.08,
                        child: const FloatingPlanet(size: 18, hasRing: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    'Verifying & aligning cosmic energies...',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.cosmicTextMid),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress.value,
                      minHeight: 10,
                      backgroundColor: AppColors.cosmicWheelBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.cosmicGold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Loading...',
                      style: AppTextStyles.bodySmall(
                          color: AppColors.cosmicTextLight)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4 step icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StepIcon(
                      icon: Icons.shield_outlined,
                      label: 'Secure\nVerification',
                      active: _step >= 0),
                  _StepIcon(
                      icon: Icons.public_rounded,
                      label: 'Aligning\nPlanets',
                      active: _step >= 1),
                  _StepIcon(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Reading Your\nChart',
                      active: _step >= 2),
                  _StepIcon(
                      icon: Icons.spa_outlined,
                      label: 'Preparing Your\nExperience',
                      active: _step >= 3),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: active ? 1.0 : 0.3,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? AppColors.cosmicGold
                    : AppColors.cosmicGold.withOpacity(0.4),
                width: 1.2,
              ),
            ),
            child: Icon(
              icon,
              color: active ? AppColors.cosmicGold : AppColors.cosmicGold.withOpacity(0.4),
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall(
              color: active
                  ? AppColors.cosmicTextDark
                  : AppColors.cosmicTextDark.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
