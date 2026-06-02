import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/lang_provider.dart';
import '../../../core/models/remedy_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

/// Remedies — wired to backend personalised remedies endpoint.
class RemediesScreen extends ConsumerWidget {
  const RemediesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remediesAsync = ref.watch(remediesProvider);
    final lang = ref.watch(langProvider);

    return CosmicScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.white, size: 18),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(AppStrings.tr('remedies_title', lang),
                          style: AppTextStyles.headingMedium(
                              color: AppColors.white)),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: remediesAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.cosmicGold),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined,
                            color: AppColors.cosmicTextLight, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.tr('remedies_load_error', lang),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(
                              color: AppColors.cosmicTextMid),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (remedies) => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const _RemediesBanner(),
                    const SizedBox(height: 18),
                    ...remedies.map((r) => _RemedyTile(remedy: r)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push('/remedies/all'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.btnBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(AppStrings.tr('view_all_remedies', lang),
                      style: AppTextStyles.sectionCaps(
                          color: AppColors.btnText)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemediesBanner extends ConsumerWidget {
  const _RemediesBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.featureDark,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: AppColors.cosmicGold.withOpacity(0.3), width: 0.8),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CustomPaint(painter: _DiyaBgPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.tr('remedies_banner_title', lang),
                  style: AppTextStyles.headingMedium(
                      color: AppColors.cosmicGoldLight),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.tr('remedies_banner_sub', lang),
                  style: AppTextStyles.bodySmall(
                      color: AppColors.white.withOpacity(0.72)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiyaBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final leafPaint = Paint()
        ..color = AppColors.featureDarkLight.withOpacity(0.6 - i * 0.15);
      final path = Path();
      final ox = size.width * (0.72 + i * 0.06);
      final oy = size.height * (0.5 - i * 0.1);
      path.moveTo(ox, oy + 40);
      path.quadraticBezierTo(ox - 18, oy, ox + 5, oy - 35);
      path.quadraticBezierTo(ox + 20, oy, ox, oy + 40);
      canvas.drawPath(path, leafPaint);
    }
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.55),
      22,
      Paint()
        ..color = AppColors.cosmicGoldLight.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.55),
      10,
      Paint()..color = AppColors.cosmicGoldGlow.withOpacity(0.8),
    );
    final flamePath = Path()
      ..moveTo(size.width * 0.80, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.42,
          size.width * 0.80, size.height * 0.50)
      ..quadraticBezierTo(size.width * 0.82, size.height * 0.42,
          size.width * 0.80, size.height * 0.35);
    canvas.drawPath(flamePath,
        Paint()..color = AppColors.cosmicGoldGlow.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RemedyTile extends StatelessWidget {
  const _RemedyTile({required this.remedy});
  final RemedyModel remedy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () =>
            context.push('/remedies/${Uri.encodeComponent(remedy.title)}'),
        child: CosmicCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cosmicGold.withOpacity(0.12),
                ),
                child: Center(
                  child: Text(remedy.icon,
                      style: const TextStyle(
                          fontSize: 22,
                          color: AppColors.cosmicGoldLight)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(remedy.title, style: AppTextStyles.labelLarge()),
                    const SizedBox(height: 2),
                    Text(remedy.category, style: AppTextStyles.bodySmall()),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.cosmicTextLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
