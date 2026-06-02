import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/lang_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

const _allRemedies = [
  // Mantras
  _RemedyItem('☀', 'Surya Mantra',          'For Confidence & Success',      'Mantras'),
  _RemedyItem('☽', 'Chandra Beej Mantra',    'For Emotional Stability',       'Mantras'),
  _RemedyItem('♂', 'Mangal Mantra',          'For Courage & Energy',          'Mantras'),
  _RemedyItem('☿', 'Budh Mantra',            'For Intelligence & Business',   'Mantras'),
  _RemedyItem('♃', 'Guru Mantra',            'For Wisdom & Prosperity',       'Mantras'),
  _RemedyItem('♀', 'Shukra Mantra',          'For Love & Luxury',             'Mantras'),
  _RemedyItem('♄', 'Shani Mantra',           'For Discipline & Protection',   'Mantras'),
  // Crystals
  _RemedyItem('◈', 'Green Aventurine',       'For Wealth & Opportunities',    'Crystals'),
  _RemedyItem('◇', 'Rose Quartz',            'For Love & Relationships',      'Crystals'),
  _RemedyItem('◆', 'Black Tourmaline',       'For Protection',                'Crystals'),
  _RemedyItem('◉', 'Citrine',                'For Abundance & Positivity',    'Crystals'),
  _RemedyItem('○', 'Moonstone',              'For Intuition & Balance',       'Crystals'),
  // Rituals
  _RemedyItem('✿', 'Tuesday Hanuman Chalisa','For Strength & Protection',     'Rituals'),
  _RemedyItem('⚛', 'Friday Lakshmi Puja',   'For Wealth & Grace',            'Rituals'),
  _RemedyItem('☁', 'Monday Shiva Abhishek', 'For Peace & Transformation',    'Rituals'),
  _RemedyItem('✦', 'Navgraha Shanti Havan', 'For Planetary Balance',         'Rituals'),
  // Therapy
  _RemedyItem('☽', 'Moon Water Therapy',    'For Emotional Balance',         'Therapy'),
  _RemedyItem('🌿', 'Tulsi Jal Therapy',    'For Health & Purification',     'Therapy'),
  _RemedyItem('☀', 'Surya Namaskar',        'For Vitality & Solar Energy',   'Therapy'),
  _RemedyItem('◎', 'Trataka Candle Gazing', 'For Focus & Third Eye',         'Therapy'),
];

class _RemedyItem {
  const _RemedyItem(this.icon, this.title, this.subtitle, this.category);
  final String icon;
  final String title;
  final String subtitle;
  final String category;
}

const _categories = ['All', 'Mantras', 'Crystals', 'Rituals', 'Therapy'];

/// All Remedies — full catalog with category filter.
class AllRemediesScreen extends ConsumerStatefulWidget {
  const AllRemediesScreen({super.key});

  @override
  ConsumerState<AllRemediesScreen> createState() => _AllRemediesScreenState();
}

class _AllRemediesScreenState extends ConsumerState<AllRemediesScreen> {
  int _cat = 0;

  List<_RemedyItem> get _filtered => _cat == 0
      ? _allRemedies
      : _allRemedies
          .where((r) => r.category == _categories[_cat])
          .toList();

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
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
                        color: AppColors.white, size: 18),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(AppStrings.tr('all_remedies_title', lang),
                          style: AppTextStyles.headingMedium(
                              color: AppColors.white)),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Category filter
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _cat = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: _cat == i
                          ? AppColors.featureDark
                          : AppColors.cardBg.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _cat == i
                            ? AppColors.cosmicGold.withOpacity(0.5)
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      _categories[i],
                      style: AppTextStyles.labelMedium(
                        color: _cat == i
                            ? AppColors.cosmicGoldLight
                            : AppColors.cosmicTextLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final r = _filtered[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () =>
                          context.push('/remedies/${Uri.encodeComponent(r.title)}'),
                      child: CosmicCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.cosmicGold.withOpacity(0.12),
                              ),
                              child: Center(
                                child: Text(r.icon,
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: AppColors.cosmicGoldLight)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title,
                                      style: AppTextStyles.labelLarge()),
                                  const SizedBox(height: 2),
                                  Text(r.subtitle,
                                      style: AppTextStyles.bodySmall()),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgAlt,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.cardBorder),
                              ),
                              child: Text(r.category,
                                  style: AppTextStyles.labelSmall()),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right,
                                color: AppColors.cosmicTextLight, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
