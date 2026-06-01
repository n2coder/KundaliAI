import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';
import 'widgets/zodiac_wheel_widget.dart';

/// Splash / landing screen.
/// For new sessions: shows marketing content (zodiac wheel + Get Started).
/// For returning users: silently checks stored JWT and redirects.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state — when it resolves from loading, redirect if logged in
    ref.listen(authProvider, (prev, next) {
      if (_redirected) return;
      next.whenData((user) {
        if (user != null && mounted) {
          _redirected = true;
          if (user.hasBirthChart) {
            context.go('/home');
          } else {
            context.go('/birth-details');
          }
        }
      });
    });

    return CosmicScaffold(
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            const Expanded(
              flex: 6,
              child: ZodiacWheelWidget(),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const _GoldStarIcon(),
                    const SizedBox(height: 12),
                    Text(
                      'Kundali AI',
                      style: AppTextStyles.displayLarge(color: AppColors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your Cosmic AI Companion',
                      style: AppTextStyles.bodyMedium(
                          color: AppColors.cosmicGoldLight),
                    ),
                    const SizedBox(height: 12),
                    const CosmicDivider(),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _FeatureCol(
                            icon: '♄', label: 'Personalized\nPredictions'),
                        _Separator(),
                        _FeatureCol(icon: '✦', label: 'AI Powered\nInsights'),
                        _Separator(),
                        _FeatureCol(
                            icon: '🪷', label: 'Ancient Wisdom\nModern AI'),
                      ],
                    ),
                    const Spacer(),
                    _GetStartedButton(onTap: () => context.go('/phone')),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => context.go('/phone'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Login',
                            style: AppTextStyles.bodyMedium(
                                color: AppColors.cosmicGoldLight),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right,
                              color: AppColors.cosmicGoldLight, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldStarIcon extends StatelessWidget {
  const _GoldStarIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cosmicGold, width: 1.2),
      ),
      child:
          const Icon(Icons.auto_awesome, color: AppColors.cosmicGold, size: 20),
    );
  }
}

class _FeatureCol extends StatelessWidget {
  const _FeatureCol({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon,
            style:
                const TextStyle(color: AppColors.cosmicGold, fontSize: 18)),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(color: AppColors.cosmicGoldLight),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 0.8,
        height: 32,
        color: AppColors.cosmicGold.withOpacity(0.3));
  }
}

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get Started',
              style:
                  AppTextStyles.buttonText(color: AppColors.cosmicTextDark),
            ),
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.btnBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward,
                  color: AppColors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
