import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/lang_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

class _GuidanceTopic {
  const _GuidanceTopic({
    required this.icon,
    required this.titleKey,
    required this.subKey,
    required this.color,
  });
  final String icon;
  final String titleKey;
  final String subKey;
  final Color color;
}

const _topics = [
  _GuidanceTopic(
    icon: '💼',
    titleKey: 'topic_career',
    subKey: 'topic_career_sub',
    color: AppColors.scoreCareer,
  ),
  _GuidanceTopic(
    icon: '❤️',
    titleKey: 'topic_love',
    subKey: 'topic_love_sub',
    color: AppColors.scoreLove,
  ),
  _GuidanceTopic(
    icon: '🏠',
    titleKey: 'topic_home',
    subKey: 'topic_home_sub',
    color: AppColors.cosmicGold,
  ),
  _GuidanceTopic(
    icon: '🎓',
    titleKey: 'topic_education',
    subKey: 'topic_education_sub',
    color: AppColors.scoreHealth,
  ),
  _GuidanceTopic(
    icon: '🌿',
    titleKey: 'topic_health',
    subKey: 'topic_health_sub',
    color: AppColors.scoreMoney,
  ),
  _GuidanceTopic(
    icon: '✈️',
    titleKey: 'topic_travel',
    subKey: 'topic_travel_sub',
    color: AppColors.cosmicGoldLight,
  ),
];

/// Guidance screen — topic picker → AI-powered personalised Vedic guidance.
class GuidanceScreen extends ConsumerWidget {
  const GuidanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return CosmicScaffold(
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
            // AppBar
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
                      child: Column(
                        children: [
                          Text(AppStrings.tr('personalised_guidance', lang),
                              style: AppTextStyles.headingMedium(
                                  color: AppColors.white)),
                          Text(AppStrings.tr('ask_any_life_area', lang),
                              style: AppTextStyles.bodySmall(
                                  color: AppColors.white.withOpacity(0.7))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 8),

                  // Hero banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.featureDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.cosmicGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppStrings.tr('what_guidance_on', lang),
                                  style: AppTextStyles.sectionCaps(
                                      color: AppColors.cosmicGoldLight)),
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.tr('guidance_hero_sub', lang),
                                style: AppTextStyles.bodySmall(
                                    color:
                                        AppColors.white.withOpacity(0.72)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text('✦',
                            style: TextStyle(
                                fontSize: 42,
                                color: AppColors.cosmicGoldLight)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(AppStrings.tr('choose_a_topic', lang),
                      style: AppTextStyles.sectionCaps()),
                  const SizedBox(height: 12),

                  // Topic grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: _topics.map((t) {
                      return GestureDetector(
                        onTap: () => _openChat(context, t),
                        child: CosmicCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.icon,
                                  style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 8),
                              Text(AppStrings.tr(t.titleKey, lang),
                                  style: AppTextStyles.labelLarge()),
                              const SizedBox(height: 4),
                              Text(AppStrings.tr(t.subKey, lang),
                                  style: AppTextStyles.bodySmall(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Quick questions
                  Text(AppStrings.tr('quick_questions', lang),
                      style: AppTextStyles.sectionCaps()),
                  const SizedBox(height: 12),
                  ..._quickQuestions.map((q) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => context.push('/chat'),
                          child: CosmicCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome,
                                    color: AppColors.cosmicGold, size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(AppStrings.tr(q, lang),
                                      style: AppTextStyles.bodyMedium()),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    color: AppColors.cosmicTextLight, size: 14),
                              ],
                            ),
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Chat CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.btnBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.cosmicGold, size: 18),
                  label: Text(AppStrings.tr('ask_anything_caps', lang),
                      style:
                          AppTextStyles.sectionCaps(color: AppColors.btnText)),
                ),
              ),
            ),
                ],
              ),
            ),
          ),
          CosmicBottomNav(
            currentIndex: 3,
            onTap: (i) {
              switch (i) {
                case 0: context.go('/home'); break;
                case 1: context.go('/insights'); break;
                case 2: context.go('/chat'); break;
                case 3: break;
                case 4: context.go('/profile'); break;
              }
            },
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, _GuidanceTopic topic) {
    // Navigate to chat with topic pre-loaded
    context.push('/chat');
  }
}

const _quickQuestions = ['qq_job', 'qq_love', 'qq_business', 'qq_remedies'];
