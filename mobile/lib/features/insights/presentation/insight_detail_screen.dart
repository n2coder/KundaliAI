import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

class _InsightData {
  const _InsightData({
    required this.tab,
    required this.score,
    required this.scoreColor,
    required this.headline,
    required this.summary,
    required this.monthlyBreakdown,
    required this.keyPredictions,
    required this.favDates,
    required this.avoidDates,
  });
  final String tab;
  final double score;
  final Color scoreColor;
  final String headline;
  final String summary;
  final List<_MonthScore> monthlyBreakdown;
  final List<String> keyPredictions;
  final List<String> favDates;
  final List<String> avoidDates;
}

class _MonthScore {
  const _MonthScore(this.month, this.score);
  final String month;
  final double score;
}

const _insightDetails = {
  'Love': _InsightData(
    tab: 'Love',
    score: 0.72,
    scoreColor: AppColors.scoreLove,
    headline: 'Deep Connections Forming',
    summary:
        'Venus transiting your 7th house brings powerful relationship energy. Existing partnerships deepen and singles may meet a significant person. The period from July to September is especially potent for romantic commitments.',
    monthlyBreakdown: [
      _MonthScore('Jan', 0.55), _MonthScore('Feb', 0.70),
      _MonthScore('Mar', 0.60), _MonthScore('Apr', 0.72),
      _MonthScore('May', 0.75), _MonthScore('Jun', 0.68),
      _MonthScore('Jul', 0.85), _MonthScore('Aug', 0.90),
      _MonthScore('Sep', 0.82), _MonthScore('Oct', 0.70),
      _MonthScore('Nov', 0.65), _MonthScore('Dec', 0.72),
    ],
    keyPredictions: [
      'July–September: High romantic energy, possible commitment',
      'Venus conjunct Jupiter in August brings joy in love',
      'Avoid major decisions in October (Mercury retrograde)',
      'December brings warmth and family harmony',
    ],
    favDates: ['2 Jul', '14 Aug', '22 Aug', '5 Sep', '18 Dec'],
    avoidDates: ['8 Oct', '15 Oct', '1 Nov'],
  ),
  'Career': _InsightData(
    tab: 'Career',
    score: 0.85,
    scoreColor: AppColors.scoreCareer,
    headline: 'Strong Year for Growth',
    summary:
        'Jupiter transiting your 10th house of career brings expansion, recognition, and leadership opportunities. Your hard work will be noticed. This is one of the strongest career years in your recent chart history.',
    monthlyBreakdown: [
      _MonthScore('Jan', 0.65), _MonthScore('Feb', 0.70),
      _MonthScore('Mar', 0.75), _MonthScore('Apr', 0.80),
      _MonthScore('May', 0.85), _MonthScore('Jun', 0.88),
      _MonthScore('Jul', 0.90), _MonthScore('Aug', 0.95),
      _MonthScore('Sep', 0.88), _MonthScore('Oct', 0.72),
      _MonthScore('Nov', 0.78), _MonthScore('Dec', 0.80),
    ],
    keyPredictions: [
      'May–September: Peak career performance window',
      'August: High chance of promotion or recognition',
      'New partnership or collaboration opportunity in June',
      'October: Pause major decisions (Mercury retrograde)',
    ],
    favDates: ['12 May', '8 Jun', '3 Aug', '15 Aug', '10 Sep'],
    avoidDates: ['2 Oct', '18 Oct', '28 Oct'],
  ),
  'Money': _InsightData(
    tab: 'Money',
    score: 0.75,
    scoreColor: AppColors.scoreMoney,
    headline: 'Financial Stability Building',
    summary:
        'Saturn in your 2nd house brings disciplined financial energy. While windfalls are limited, steady income growth and smart investments made now will pay off significantly in 2025–2026.',
    monthlyBreakdown: [
      _MonthScore('Jan', 0.60), _MonthScore('Feb', 0.65),
      _MonthScore('Mar', 0.72), _MonthScore('Apr', 0.70),
      _MonthScore('May', 0.75), _MonthScore('Jun', 0.80),
      _MonthScore('Jul', 0.85), _MonthScore('Aug', 0.80),
      _MonthScore('Sep', 0.75), _MonthScore('Oct', 0.65),
      _MonthScore('Nov', 0.70), _MonthScore('Dec', 0.78),
    ],
    keyPredictions: [
      'Jupiter aspects your 2nd house from May — income rises',
      'Good time for long-term investments from June',
      'Avoid speculative investments in October',
      'December: Unexpected bonus or gift is possible',
    ],
    favDates: ['20 May', '15 Jun', '7 Jul', '22 Nov', '14 Dec'],
    avoidDates: ['5 Oct', '20 Oct', '3 Nov'],
  ),
  'Health': _InsightData(
    tab: 'Health',
    score: 0.68,
    scoreColor: AppColors.scoreHealth,
    headline: 'Focus on Rest & Recovery',
    summary:
        'Mars transiting your 6th house increases physical energy but also the risk of overexertion. Prioritise consistent sleep, avoid skipping meals, and take up a grounding practice like yoga or walking.',
    monthlyBreakdown: [
      _MonthScore('Jan', 0.75), _MonthScore('Feb', 0.70),
      _MonthScore('Mar', 0.68), _MonthScore('Apr', 0.65),
      _MonthScore('May', 0.60), _MonthScore('Jun', 0.65),
      _MonthScore('Jul', 0.70), _MonthScore('Aug', 0.72),
      _MonthScore('Sep', 0.68), _MonthScore('Oct', 0.65),
      _MonthScore('Nov', 0.70), _MonthScore('Dec', 0.75),
    ],
    keyPredictions: [
      'May–June: Watch for stress-related issues; rest is key',
      'Start a daily walk or yoga routine from July',
      'Diet improvements in August yield strong results',
      'December: Energy levels recover and stabilise',
    ],
    favDates: ['10 Jul', '5 Aug', '20 Aug', '12 Dec'],
    avoidDates: ['22 May', '10 Jun', '15 Sep'],
  ),
};

/// Detailed insight page — full monthly breakdown + predictions + key dates.
class InsightDetailScreen extends StatefulWidget {
  const InsightDetailScreen({super.key, required this.tab});
  final String tab;

  @override
  State<InsightDetailScreen> createState() => _InsightDetailScreenState();
}

class _InsightDetailScreenState extends State<InsightDetailScreen> {
  late String _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.tab;
  }

  @override
  Widget build(BuildContext context) {
    final d = _insightDetails[_activeTab]!;

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
                      child: Text('Detailed Analysis',
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

            // Tab pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: ['Love', 'Career', 'Money', 'Health'].map((t) {
                  final active = _activeTab == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.featureDark
                              : AppColors.cardBg.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? AppColors.cosmicGold.withOpacity(0.4)
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            t,
                            style: AppTextStyles.labelSmall(
                              color: active
                                  ? AppColors.cosmicGoldLight
                                  : AppColors.cosmicTextLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Score hero
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
                              Text(d.tab,
                                  style: AppTextStyles.sectionCaps(
                                      color: d.scoreColor)),
                              const SizedBox(height: 6),
                              Text(d.headline,
                                  style: AppTextStyles.headingMedium(
                                      color: AppColors.white)),
                              const SizedBox(height: 8),
                              Text(d.summary,
                                  style: AppTextStyles.bodySmall(
                                      color:
                                          AppColors.white.withOpacity(0.72))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: d.score,
                                strokeWidth: 6,
                                backgroundColor:
                                    d.scoreColor.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    d.scoreColor),
                                strokeCap: StrokeCap.round,
                              ),
                              Text(
                                '${(d.score * 100).round()}%',
                                style: AppTextStyles.labelMedium(
                                    color: d.scoreColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Monthly breakdown
                  CosmicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monthly Breakdown 2024',
                            style: AppTextStyles.labelLarge()),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 100,
                          child: _MonthlyChart(
                              data: d.monthlyBreakdown,
                              color: d.scoreColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Key predictions
                  CosmicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Key Predictions',
                            style: AppTextStyles.labelLarge(
                                color: AppColors.cosmicGold)),
                        const SizedBox(height: 10),
                        ...d.keyPredictions.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      size: 13, color: AppColors.cosmicGold),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(p,
                                        style: AppTextStyles.bodyMedium()),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dates row
                  Row(
                    children: [
                      Expanded(
                        child: CosmicCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.check_circle_outline,
                                    color: AppColors.scoreCareer, size: 14),
                                const SizedBox(width: 6),
                                Text('Favorable',
                                    style: AppTextStyles.labelMedium(
                                        color: AppColors.scoreCareer)),
                              ]),
                              const SizedBox(height: 8),
                              ...d.favDates.map((dt) => Text(dt,
                                  style: AppTextStyles.bodySmall())),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CosmicCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.warning_amber_outlined,
                                    color: AppColors.error, size: 14),
                                const SizedBox(width: 6),
                                Text('Caution',
                                    style: AppTextStyles.labelMedium(
                                        color: AppColors.error)),
                              ]),
                              const SizedBox(height: 8),
                              ...d.avoidDates.map((dt) => Text(dt,
                                  style: AppTextStyles.bodySmall())),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Ask AI button
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
                  icon: const Icon(Icons.auto_awesome,
                      color: AppColors.cosmicGold, size: 18),
                  label: Text('ASK AI ASTROLOGER',
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

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.data, required this.color});
  final List<_MonthScore> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarChartPainter(data: data, color: color),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.data, required this.color});
  final List<_MonthScore> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final barW = size.width / (data.length * 1.6);
    final gap = (size.width - barW * data.length) / (data.length + 1);

    for (var i = 0; i < data.length; i++) {
      final x = gap + i * (barW + gap);
      final barH = size.height * 0.75 * data[i].score;
      final top = size.height * 0.75 - barH;

      // Bar
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barW, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(rr, Paint()..color = color.withOpacity(0.75));

      // Month label
      final tp = TextPainter(
        text: TextSpan(
          text: data[i].month.substring(0, 3),
          style: TextStyle(
              fontSize: 9, color: AppColors.cosmicTextLight),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(x + barW / 2 - tp.width / 2, size.height * 0.78));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
