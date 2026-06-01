import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

class _GuidanceTopic {
  const _GuidanceTopic({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tags,
  });
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<String> tags;
}

const _topics = [
  _GuidanceTopic(
    icon: '💼',
    title: 'Career & Finance',
    subtitle: 'Job timing, business muhurta, investment windows',
    color: AppColors.scoreCareer,
    tags: ['Job Change', 'Business', 'Investment'],
  ),
  _GuidanceTopic(
    icon: '❤️',
    title: 'Love & Marriage',
    subtitle: 'Compatibility, marriage muhurta, relationship healing',
    color: AppColors.scoreLove,
    tags: ['Compatibility', 'Marriage Date', 'Relationship'],
  ),
  _GuidanceTopic(
    icon: '🏠',
    title: 'Home & Property',
    subtitle: 'Auspicious dates for moving, buying, or renovating',
    color: AppColors.cosmicGold,
    tags: ['Buy Property', 'Moving In', 'Vastu'],
  ),
  _GuidanceTopic(
    icon: '🎓',
    title: 'Education & Skills',
    subtitle: 'Study timing, exam luck, learning windows',
    color: AppColors.scoreHealth,
    tags: ['Exams', 'New Course', 'Study Plan'],
  ),
  _GuidanceTopic(
    icon: '🌿',
    title: 'Health & Wellness',
    subtitle: 'Auspicious days for treatment, surgery, detox',
    color: AppColors.scoreMoney,
    tags: ['Surgery Date', 'Detox', 'Mental Wellness'],
  ),
  _GuidanceTopic(
    icon: '✈️',
    title: 'Travel & Foreign',
    subtitle: 'Auspicious travel, foreign settlement windows',
    color: AppColors.cosmicGoldLight,
    tags: ['Best Travel Day', 'Foreign Settlement', 'Visa'],
  ),
];

/// Guidance screen — topic picker → AI-powered personalised Vedic guidance.
class GuidanceScreen extends StatelessWidget {
  const GuidanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                        color: AppColors.cosmicTextDark, size: 18),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text('Personalised Guidance',
                              style: AppTextStyles.headingMedium()),
                          Text('Ask about any life area',
                              style: AppTextStyles.bodySmall()),
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
                              Text("WHAT WOULD YOU\nLIKE GUIDANCE ON?",
                                  style: AppTextStyles.sectionCaps(
                                      color: AppColors.cosmicGoldLight)),
                              const SizedBox(height: 8),
                              Text(
                                'Choose a topic and our AI Vedic astrologer will analyse your birth chart for personalised insights.',
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

                  Text('CHOOSE A TOPIC',
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
                              Text(t.title,
                                  style: AppTextStyles.labelLarge()),
                              const SizedBox(height: 4),
                              Text(t.subtitle,
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
                  Text('QUICK QUESTIONS', style: AppTextStyles.sectionCaps()),
                  const SizedBox(height: 12),
                  ..._quickQuestions.map((q) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => context.go('/chat'),
                          child: CosmicCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome,
                                    color: AppColors.cosmicGold, size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child:
                                      Text(q, style: AppTextStyles.bodyMedium()),
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
                  onPressed: () => context.go('/chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.btnBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.cosmicGold, size: 18),
                  label: Text('ASK ANYTHING',
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
    context.go('/chat');
  }
}

const _quickQuestions = [
  'When is the best time for me to change my job?',
  'Will I find love this year?',
  'Is this a good time to start a business?',
  'What planetary remedies should I follow?',
];
