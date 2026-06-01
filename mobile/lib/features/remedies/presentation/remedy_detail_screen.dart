import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

class RemedyData {
  const RemedyData({
    required this.icon,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.description,
    required this.benefits,
    required this.steps,
    required this.bestTime,
    required this.duration,
    required this.planet,
  });
  final String icon;
  final String title;
  final String category;
  final String subtitle;
  final String description;
  final List<String> benefits;
  final List<String> steps;
  final String bestTime;
  final String duration;
  final String planet;
}

final remedyDataMap = <String, RemedyData>{
  'Surya Mantra': RemedyData(
    icon: '☀',
    title: 'Surya Mantra',
    category: 'Solar Remedy',
    subtitle: 'For Confidence & Success',
    description:
        'The Surya Mantra is a powerful solar invocation that connects you with the life-giving energy of the Sun. Chanting this mantra at sunrise activates your solar plexus chakra, boosts confidence, and removes obstacles from your path.',
    benefits: [
      'Increases self-confidence and willpower',
      'Improves eyesight and vitality',
      'Removes career obstacles',
      'Enhances leadership qualities',
      'Brings clarity of purpose',
    ],
    steps: [
      'Wake up before sunrise and take a bath.',
      'Face the rising Sun and stand with hands folded.',
      'Chant "Om Hraam Hreem Hraum Sah Suryaya Namah" 108 times.',
      'Offer water to the Sun (Arghya) while chanting.',
      'Sit in meditation for 5 minutes after chanting.',
    ],
    bestTime: 'Sunday, 6:00 AM – 7:00 AM (Sunrise)',
    duration: '21 days for full effect',
    planet: '☉ Sun',
  ),
  'Moon Water Therapy': RemedyData(
    icon: '☽',
    title: 'Moon Water Therapy',
    category: 'Lunar Remedy',
    subtitle: 'For Emotional Balance',
    description:
        'Moon Water Therapy harnesses the healing energy of the full moon to create charged water that soothes emotional imbalances, improves intuition, and strengthens the mind-body connection.',
    benefits: [
      'Calms anxiety and emotional turbulence',
      'Strengthens intuition and psychic abilities',
      'Improves sleep quality',
      'Balances mood swings',
      'Enhances spiritual connection',
    ],
    steps: [
      'On the full moon night, fill a glass jar with clean water.',
      'Place it on a windowsill where moonlight falls directly.',
      'Set an intention for healing and balance.',
      'Leave overnight until before sunrise.',
      'Drink a glass of this charged water every morning for 7 days.',
    ],
    bestTime: 'Full Moon night, 10:00 PM – 4:00 AM',
    duration: '7 days (per lunar cycle)',
    planet: '☽ Moon',
  ),
  'Tuesday Hanuman Chalisa': RemedyData(
    icon: '✿',
    title: 'Tuesday Hanuman Chalisa',
    category: 'Devotional Remedy',
    subtitle: 'For Strength & Protection',
    description:
        'Reciting the Hanuman Chalisa on Tuesdays invokes the protective energy of Mars and Lord Hanuman. This powerful remedy removes fear, builds mental strength, and shields against negative influences.',
    benefits: [
      'Removes fear and anxiety',
      'Builds physical and mental strength',
      'Protection from negative energies',
      'Resolves legal disputes and conflicts',
      'Boosts Mars energy for action and courage',
    ],
    steps: [
      'Light a diya with mustard oil on Tuesday morning.',
      'Offer red flowers and sindoor to Lord Hanuman.',
      'Recite the Hanuman Chalisa clearly and slowly.',
      'Recite a minimum of 3 times, ideally 11 times.',
      'Distribute prasad (sweets) to others.',
    ],
    bestTime: 'Tuesday, 5:00 AM – 8:00 AM or 6:00 PM – 8:00 PM',
    duration: '11 consecutive Tuesdays',
    planet: '♂ Mars',
  ),
  'Green Aventurine': RemedyData(
    icon: '◈',
    title: 'Green Aventurine',
    category: 'Crystal Remedy',
    subtitle: 'For Wealth & Opportunities',
    description:
        'Green Aventurine is the stone of opportunity and abundance. It resonates with Venus and Jupiter energies to attract wealth, success in ventures, and open doors to new possibilities.',
    benefits: [
      'Attracts financial opportunities',
      'Enhances luck in business and career',
      'Calms emotional stress',
      'Strengthens decision-making',
      'Aligns Venus energy for prosperity',
    ],
    steps: [
      'Cleanse the crystal under running water for 3 minutes.',
      'Charge it in sunlight for 4 hours on a Friday.',
      'Hold it in your left hand and set an abundance intention.',
      'Carry it in your wallet or left pocket daily.',
      'Re-cleanse and recharge on every new moon.',
    ],
    bestTime: 'Friday (Venus day) for charging',
    duration: 'Wear or carry continuously for 40 days',
    planet: '♀ Venus / ♃ Jupiter',
  ),
};

/// Remedy detail screen — shows full practice guide for a single remedy.
class RemedyDetailScreen extends StatelessWidget {
  const RemedyDetailScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final data = remedyDataMap[title] ??
        RemedyData(
          icon: '✦',
          title: title,
          category: 'Vedic Remedy',
          subtitle: 'Personalized for you',
          description: 'This remedy has been selected based on your birth chart analysis.',
          benefits: ['Restores planetary balance', 'Promotes overall wellbeing'],
          steps: ['Follow the guidance of your astrologer.'],
          bestTime: 'As recommended',
          duration: '21 days',
          planet: 'Your ruling planet',
        );

    return CosmicScaffold(
      child: SafeArea(
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
                      child: Text(data.title,
                          style: AppTextStyles.headingMedium()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: AppColors.cosmicTextDark),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 8),

                  // Hero card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.featureDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.cosmicGold.withOpacity(0.3),
                          width: 0.8),
                    ),
                    child: Column(
                      children: [
                        Text(data.icon,
                            style: const TextStyle(fontSize: 52)),
                        const SizedBox(height: 12),
                        Text(data.title,
                            style: AppTextStyles.headingLarge(
                                color: AppColors.white)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color:
                                AppColors.cosmicGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.cosmicGold.withOpacity(0.4)),
                          ),
                          child: Text(data.category,
                              style: AppTextStyles.sectionCaps(
                                  color: AppColors.cosmicGoldLight)),
                        ),
                        const SizedBox(height: 10),
                        Text(data.subtitle,
                            style: AppTextStyles.bodyMedium(
                                color: AppColors.cosmicGoldLight)),

                        const SizedBox(height: 16),
                        // Quick info row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _InfoChip(label: 'Planet', value: data.planet),
                            Container(
                                width: 0.8,
                                height: 28,
                                color: AppColors.cosmicGold.withOpacity(0.3)),
                            _InfoChip(label: 'Duration', value: data.duration),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // About
                  CosmicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About This Remedy',
                            style: AppTextStyles.labelLarge()),
                        const SizedBox(height: 8),
                        Text(data.description,
                            style: AppTextStyles.bodyMedium()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Benefits
                  CosmicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Benefits',
                            style: AppTextStyles.labelLarge(
                                color: AppColors.cosmicGold)),
                        const SizedBox(height: 10),
                        ...data.benefits.map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      color: AppColors.cosmicGold, size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(b,
                                        style: AppTextStyles.bodyMedium()),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // How to Practice
                  CosmicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How to Practice',
                            style: AppTextStyles.labelLarge(
                                color: AppColors.cosmicGold)),
                        const SizedBox(height: 10),
                        ...data.steps.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.cosmicGold
                                          .withOpacity(0.15),
                                      border: Border.all(
                                          color: AppColors.cosmicGold
                                              .withOpacity(0.5)),
                                    ),
                                    child: Center(
                                      child: Text('${e.key + 1}',
                                          style: AppTextStyles.labelSmall(
                                              color: AppColors.cosmicGold)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(e.value,
                                        style: AppTextStyles.bodyMedium()),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Best time card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.featureDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.cosmicGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            color: AppColors.cosmicGold, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Best Time',
                                  style: AppTextStyles.sectionCaps(
                                      color: AppColors.cosmicGoldLight)),
                              const SizedBox(height: 4),
                              Text(data.bestTime,
                                  style: AppTextStyles.bodyMedium(
                                      color: AppColors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Start Practice CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.btnBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('START PRACTICE',
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.bodySmall(
                color: AppColors.white.withOpacity(0.55))),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.labelMedium(
                color: AppColors.cosmicGoldLight)),
      ],
    );
  }
}
