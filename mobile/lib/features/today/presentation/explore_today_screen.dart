import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/lang_provider.dart';
import '../../../core/models/today_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

/// "Explore Today" detail — full daily reading with panchang, muhurtas,
/// lucky items, and planetary influences from the API.
class ExploreTodayScreen extends ConsumerWidget {
  const ExploreTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider).valueOrNull;
    final lang = ref.watch(langProvider);
    final dateLabel = today != null
        ? DateFormat('EEEE, d MMMM yyyy').format(DateTime.parse(today.date))
        : DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

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
                      child: Column(
                        children: [
                          Text(AppStrings.tr('todays_full_reading', lang),
                              style: AppTextStyles.headingMedium(
                                  color: AppColors.white)),
                          Text(dateLabel,
                              style: AppTextStyles.bodySmall(
                                  color: AppColors.white.withOpacity(0.7))),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: AppColors.white),
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

                  // Day score hero
                  _DayScoreCard(today: today),
                  const SizedBox(height: 16),

                  // Moon phase
                  _MoonPhaseCard(moonPhase: today?.moonPhase),
                  const SizedBox(height: 14),

                  // Auspicious times
                  _MuhurtaCard(muhurtas: today?.muhurtas),
                  const SizedBox(height: 14),

                  // Lucky items
                  _LuckyItemsCard(today: today),
                  const SizedBox(height: 14),

                  // Do / Avoid activities
                  _ActivitiesCard(
                    doToday: today?.doToday,
                    avoidToday: today?.avoidToday,
                  ),
                  const SizedBox(height: 14),

                  // Planetary influences
                  _PlanetaryInfluenceCard(
                      influences: today?.planetaryInfluences),
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
                  icon: const Icon(Icons.auto_awesome,
                      color: AppColors.cosmicGold, size: 18),
                  label: Text(AppStrings.tr('ask_ai_more_details', lang),
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

// ── Day Score card ────────────────────────────────────────────────────────────

class _DayScoreCard extends ConsumerWidget {
  const _DayScoreCard({required this.today});
  final TodayModel? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final score = today?.lifeScores?.dayScore ?? 82;
    final title = today?.lifeScores?.dayTitle.isNotEmpty == true
        ? today!.lifeScores!.dayTitle
        : 'A day of Growth\n& New Opportunities';
    final subtitle = today?.lifeScores?.daySubtitle.isNotEmpty == true
        ? today!.lifeScores!.daySubtitle
        : 'The Sun and Jupiter align to support bold moves. This is an excellent day for starting new ventures, having important conversations, and making decisions.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.featureDark,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.cosmicGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.tr('todays_cosmic_weather', lang),
                    style: AppTextStyles.sectionCaps(
                        color: AppColors.cosmicGoldLight)),
                const SizedBox(height: 8),
                Text(title,
                    style: AppTextStyles.headingMedium(
                        color: AppColors.white)),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall(
                      color: AppColors.white.withOpacity(0.75)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 6,
                      backgroundColor:
                          AppColors.cosmicGold.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.cosmicGold),
                      strokeCap: StrokeCap.round,
                    ),
                    Text('$score%',
                        style: AppTextStyles.labelMedium(
                            color: AppColors.cosmicGoldLight)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(AppStrings.tr('day_score', lang),
                  style: AppTextStyles.bodySmall(
                      color: AppColors.white.withOpacity(0.55))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Moon Phase card ───────────────────────────────────────────────────────────

class _MoonPhaseCard extends ConsumerWidget {
  const _MoonPhaseCard({required this.moonPhase});
  final MoonPhaseModel? moonPhase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final emoji = moonPhase?.emoji ?? '🌔';
    final name = moonPhase?.name ?? 'Waxing Gibbous Moon';
    final desc = moonPhase?.description ??
        'Energy is building. Excellent for growth-focused actions, amplifying intentions set at the new moon.';
    final percent = moonPhase?.percent ?? 84;
    final sign = moonPhase?.sign ?? 'Leo';

    return CosmicCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cosmicGold.withOpacity(0.12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelLarge()),
                const SizedBox(height: 4),
                Text(desc, style: AppTextStyles.bodySmall()),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _PhaseBadge(
                        label: AppStrings.tr('moon_in', lang)
                            .replaceFirst('{sign}', sign),
                        color: AppColors.cosmicGold),
                    const SizedBox(width: 8),
                    _PhaseBadge(
                        label: AppStrings.tr('percent_full', lang)
                            .replaceFirst('{p}', '$percent'),
                        color: AppColors.scoreHealth),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: AppTextStyles.labelSmall(color: color)),
    );
  }
}

// ── Auspicious Times (Muhurta) ────────────────────────────────────────────────

class _MuhurtaCard extends ConsumerWidget {
  const _MuhurtaCard({required this.muhurtas});
  final List<MuhurtaModel>? muhurtas;

  static const _fallback = [
    (name: 'Brahma Muhurta',  start: '5:12 AM', end: '6:00 AM',  good: true),
    (name: 'Abhijit Muhurta', start: '12:07 PM', end: '12:55 PM', good: true),
    (name: 'Rahu Kaal',       start: '4:30 PM', end: '6:00 PM',  good: false),
    (name: 'Gulika Kaal',     start: '3:00 PM', end: '4:30 PM',  good: false),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return CosmicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.tr('auspicious_times', lang),
              style: AppTextStyles.labelLarge(
                  color: AppColors.cosmicGold)),
          const SizedBox(height: 10),
          if (muhurtas != null && muhurtas!.isNotEmpty)
            ...muhurtas!.map((m) => _TimeRow(
                  label: m.name,
                  time: '${m.start} – ${m.end}',
                  icon: m.isAuspicious ? '✦' : '⚠',
                  good: m.isAuspicious,
                ))
          else
            ..._fallback.map((m) => _TimeRow(
                  label: m.name,
                  time: '${m.start} – ${m.end}',
                  icon: m.good ? '✦' : '⚠',
                  good: m.good,
                )),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.time,
    required this.icon,
    required this.good,
  });
  final String label;
  final String time;
  final String icon;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final color = good ? AppColors.scoreCareer : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 16, color: color)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMedium()),
          ),
          Text(time, style: AppTextStyles.labelSmall(color: color)),
        ],
      ),
    );
  }
}

// ── Lucky Items ───────────────────────────────────────────────────────────────

class _LuckyItemsCard extends ConsumerWidget {
  const _LuckyItemsCard({required this.today});
  final TodayModel? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final colour = today?.luckyColor ?? 'Golden';
    final number = today?.luckyNumber.toString() ?? '3';
    final gem = today?.luckyGem ?? 'Ruby';
    final direction = today?.luckyDirection ?? 'East';

    return CosmicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.tr('lucky_for_today', lang),
              style: AppTextStyles.labelLarge(
                  color: AppColors.cosmicGold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LuckyItem(icon: '🎨', label: AppStrings.tr('lucky_colour', lang), value: colour),
              _LuckyItem(icon: '🔢', label: AppStrings.tr('lucky_number', lang), value: number),
              _LuckyItem(icon: '💎', label: AppStrings.tr('lucky_gem', lang), value: gem),
              _LuckyItem(
                  icon: '🧭', label: AppStrings.tr('lucky_direction', lang), value: direction),
            ],
          ),
        ],
      ),
    );
  }
}

class _LuckyItem extends StatelessWidget {
  const _LuckyItem(
      {required this.icon, required this.label, required this.value});
  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall()),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.labelSmall(
                color: AppColors.cosmicGold)),
      ],
    );
  }
}

// ── Do Today / Avoid Today ────────────────────────────────────────────────────

class _ActivitiesCard extends ConsumerWidget {
  const _ActivitiesCard(
      {required this.doToday, required this.avoidToday});
  final List<String>? doToday;
  final List<String>? avoidToday;

  static const _defaultDo = [
    'Start new business ventures or sign contracts',
    'Approach seniors or authority figures for favors',
    'Invest in long-term financial instruments',
    'Begin a health or wellness routine',
  ];

  static const _defaultAvoid = [
    'Travel or long journeys during Rahu Kaal',
    'Arguments or confrontations — energy is tense',
    'Major purchases after 4:30 PM',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final dos = doToday?.isNotEmpty == true ? doToday! : _defaultDo;
    final avoids =
        avoidToday?.isNotEmpty == true ? avoidToday! : _defaultAvoid;

    return CosmicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.tr('do_today', lang),
              style: AppTextStyles.labelLarge(
                  color: AppColors.scoreCareer)),
          const SizedBox(height: 10),
          ...dos.map((s) => _BulletItem(text: s, positive: true)),
          const SizedBox(height: 12),
          Text(AppStrings.tr('avoid_today', lang),
              style:
                  AppTextStyles.labelLarge(color: AppColors.error)),
          const SizedBox(height: 10),
          ...avoids.map((s) => _BulletItem(text: s, positive: false)),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text, required this.positive});
  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.scoreCareer : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            positive
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: AppTextStyles.bodySmall())),
        ],
      ),
    );
  }
}

// ── Planetary Influences ──────────────────────────────────────────────────────

class _PlanetaryInfluenceCard extends ConsumerWidget {
  const _PlanetaryInfluenceCard({required this.influences});
  final List<PlanetaryInfluenceModel>? influences;

  static const _defaultInfluences = [
    (glyph: '☉ Sun',      sign: 'Gemini',  effect: 'Communication & intellect highlighted'),
    (glyph: '☽ Moon',     sign: 'Leo',     effect: 'Creativity & self-expression boosted'),
    (glyph: '♃ Jupiter',  sign: 'Taurus',  effect: 'Financial wisdom & expansion'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final items = influences?.isNotEmpty == true
        ? influences!
            .map((i) => (glyph: i.glyph, sign: i.sign, effect: i.effect))
            .toList()
        : _defaultInfluences.toList();

    return CosmicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.tr('todays_planetary_influences', lang),
              style: AppTextStyles.labelLarge(
                  color: AppColors.cosmicGold)),
          const SizedBox(height: 12),
          ...items.map((inf) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cosmicGold.withOpacity(0.1),
                        border: Border.all(
                            color:
                                AppColors.cosmicGold.withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Text(
                          inf.glyph.split(' ').first,
                          style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.cosmicGoldLight),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inf.glyph,
                              style: AppTextStyles.labelMedium()),
                          Text(inf.effect,
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
                        border:
                            Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(inf.sign,
                          style: AppTextStyles.labelSmall()),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
