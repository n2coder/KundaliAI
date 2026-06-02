import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/lang_provider.dart';
import '../../../core/models/birth_chart_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

const _planetGlyphs = {
  'Sun': '☉', 'Moon': '☽', 'Mercury': '☿', 'Venus': '♀',
  'Mars': '♂', 'Jupiter': '♃', 'Saturn': '♄', 'Rahu': '☊', 'Ketu': '☋',
};

const _signGlyphs = {
  'Aries': '♈', 'Taurus': '♉', 'Gemini': '♊', 'Cancer': '♋',
  'Leo': '♌', 'Virgo': '♍', 'Libra': '♎', 'Scorpio': '♏',
  'Sagittarius': '♐', 'Capricorn': '♑', 'Aquarius': '♒', 'Pisces': '♓',
};

const _planetColors = <String, Color>{
  'Sun': AppColors.cosmicGold,
  'Moon': AppColors.scoreHealth,
  'Mercury': AppColors.scoreCareer,
  'Venus': AppColors.scoreLove,
  'Mars': AppColors.error,
  'Jupiter': AppColors.cosmicGoldLight,
  'Saturn': AppColors.cosmicTextLight,
  'Rahu': AppColors.scoreMoney,
  'Ketu': AppColors.scoreMoney,
};

String _fmtDeg(double d) {
  final deg = d.floor();
  final min = ((d - deg) * 60).round().toString().padLeft(2, '0');
  return "$deg° $min'";
}

/// Birth Chart — natal wheel, live planet positions from API, house breakdown.
class BirthChartScreen extends ConsumerStatefulWidget {
  const BirthChartScreen({super.key});

  @override
  ConsumerState<BirthChartScreen> createState() => _BirthChartScreenState();
}

class _BirthChartScreenState extends ConsumerState<BirthChartScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final chartAsync = ref.watch(birthChartProvider);
    final lang = ref.watch(langProvider);
    final chartSize = MediaQuery.of(context).size.width - 56;

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
                      child: Text(AppStrings.tr('birth_chart_title', lang),
                          style: AppTextStyles.headingMedium(
                              color: AppColors.white)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.ios_share_outlined,
                        color: AppColors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Tab toggle
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cardBg.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _ChartTab(
                        label: AppStrings.tr('tab_chart', lang),
                        active: _tab == 0,
                        onTap: () => setState(() => _tab = 0)),
                    _ChartTab(
                        label: AppStrings.tr('tab_planets', lang),
                        active: _tab == 1,
                        onTap: () => setState(() => _tab = 1)),
                    _ChartTab(
                        label: AppStrings.tr('tab_houses', lang),
                        active: _tab == 2,
                        onTap: () => setState(() => _tab = 2)),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _tab == 0
                  ? _chartTab(chartAsync, chartSize)
                  : _tab == 1
                      ? _planetsTab(chartAsync)
                      : _housesTab(chartAsync),
            ),

            // AI Interpretation button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.featureDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(
                        color: AppColors.cosmicGold.withOpacity(0.5)),
                  ),
                  icon: const Icon(Icons.auto_awesome,
                      color: AppColors.cosmicGold, size: 18),
                  label: Text(AppStrings.tr('ai_interpretation', lang),
                      style: AppTextStyles.sectionCaps(
                          color: AppColors.cosmicGold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartTab(
      AsyncValue<BirthChartModel> chartAsync, double chartSize) {
    final chart = chartAsync.valueOrNull;
    final lang = ref.read(langProvider);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: chartSize,
            height: chartSize,
            child: CustomPaint(painter: _NatalWheelPainter()),
          ),
        ),
        const SizedBox(height: 16),
        if (chart != null)
          CosmicCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.tr('chart_summary', lang),
                    style: AppTextStyles.labelLarge()),
                const SizedBox(height: 12),
                _SummaryRow(
                    label: AppStrings.tr('ascendant', lang),
                    value:
                        '${chart.ascendant} (${chart.ascendantDegree.toStringAsFixed(1)}°)'),
                _SummaryRow(
                    label: AppStrings.tr('sun_sign', lang), value: chart.sunSign),
                _SummaryRow(
                    label: AppStrings.tr('moon_sign', lang), value: chart.moonSign),
                _SummaryRow(
                    label: AppStrings.tr('mahadasha', lang),
                    value:
                        '${chart.dasha.mahadasha} (${chart.dasha.mahadashaRemainingYears.toStringAsFixed(1)} yrs)'),
                _SummaryRow(
                    label: AppStrings.tr('antardasha', lang),
                    value: chart.dasha.antardasha,
                    isLast: true),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _planetsTab(AsyncValue<BirthChartModel> chartAsync) {
    final lang = ref.read(langProvider);
    return chartAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.cosmicGold)),
      error: (_, __) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),
          CosmicCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.tr('planetary_positions', lang),
                    style: AppTextStyles.labelLarge()),
                const SizedBox(height: 12),
                ..._defaultPlanets.map((p) => _StaticPlanetRow(p)),
              ],
            ),
          ),
        ],
      ),
      data: (chart) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),
          CosmicCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.tr('planetary_positions', lang),
                    style: AppTextStyles.labelLarge()),
                const SizedBox(height: 12),
                ...chart.planets.map((p) => _LivePlanetRow(planet: p)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _housesTab(AsyncValue<BirthChartModel> chartAsync) {
    final lang = ref.read(langProvider);
    return chartAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.cosmicGold)),
      error: (_, __) => Center(
        child: Text(AppStrings.tr('could_not_load_houses', lang),
            style: AppTextStyles.bodyMedium()),
      ),
      data: (chart) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),
          CosmicCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.tr('house_positions', lang),
                    style: AppTextStyles.labelLarge()),
                const SizedBox(height: 12),
                ...chart.houses.map((h) => _HouseRow(house: h)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Fallback static planet data (shown on API error) ─────────────────────────

const _defaultPlanets = [
  ('Sun',     '☉', 'Leo',      '♌', "18° 45'", AppColors.cosmicGold),
  ('Moon',    '☽', 'Scorpio',  '♏', "12° 30'", AppColors.scoreHealth),
  ('Mercury', '☿', 'Virgo',    '♍', "26° 10'", AppColors.scoreCareer),
  ('Venus',   '♀', 'Cancer',   '♋', "03° 22'", AppColors.scoreLove),
  ('Mars',    '♂', 'Aries',    '♈', "14° 05'", AppColors.error),
  ('Jupiter', '♃', 'Taurus',   '♉', "22° 18'", AppColors.cosmicGoldLight),
  ('Saturn',  '♄', 'Aquarius', '♒', "05° 33'", AppColors.cosmicTextLight),
];

class _StaticPlanetRow extends StatelessWidget {
  const _StaticPlanetRow(this.p);
  final (String, String, String, String, String, Color) p;

  @override
  Widget build(BuildContext context) {
    final (name, sym, sign, signSym, deg, color) = p;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color.withOpacity(0.14)),
            child: Center(
                child: Text(sym,
                    style: TextStyle(fontSize: 14, color: color))),
          ),
          const SizedBox(width: 10),
          SizedBox(
              width: 68,
              child: Text(name, style: AppTextStyles.labelMedium())),
          Text(signSym,
              style: const TextStyle(
                  fontSize: 16, color: AppColors.cosmicTextMid)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(sign, style: AppTextStyles.bodyMedium())),
          Text(deg, style: AppTextStyles.labelMedium()),
        ],
      ),
    );
  }
}

// ── Live planet row (from API) ────────────────────────────────────────────────

class _LivePlanetRow extends StatelessWidget {
  const _LivePlanetRow({required this.planet});
  final PlanetModel planet;

  @override
  Widget build(BuildContext context) {
    final glyph =
        _planetGlyphs[planet.name] ?? planet.name.substring(0, 1);
    final signGlyph = _signGlyphs[planet.sign] ?? '✦';
    final color = _planetColors[planet.name] ?? AppColors.cosmicGold;
    final degStr =
        '${_fmtDeg(planet.degree)}${planet.retrograde ? ' ℞' : ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color.withOpacity(0.14)),
            child: Center(
                child:
                    Text(glyph, style: TextStyle(fontSize: 14, color: color))),
          ),
          const SizedBox(width: 10),
          SizedBox(
              width: 68,
              child: Text(planet.name,
                  style: AppTextStyles.labelMedium())),
          Text(signGlyph,
              style: const TextStyle(
                  fontSize: 16, color: AppColors.cosmicTextMid)),
          const SizedBox(width: 6),
          Expanded(
              child:
                  Text(planet.sign, style: AppTextStyles.bodyMedium())),
          Text(degStr, style: AppTextStyles.labelMedium()),
        ],
      ),
    );
  }
}

// ── House row ─────────────────────────────────────────────────────────────────

class _HouseRow extends ConsumerWidget {
  const _HouseRow({required this.house});
  final HouseModel house;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final signGlyph = _signGlyphs[house.sign] ?? '✦';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cosmicGold.withOpacity(0.12),
            ),
            child: Center(
              child: Text('${house.house}',
                  style: AppTextStyles.labelSmall(
                      color: AppColors.cosmicGold)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
              width: 68,
              child: Text('${AppStrings.tr('house', lang)} ${house.house}',
                  style: AppTextStyles.labelMedium())),
          Text(signGlyph,
              style: const TextStyle(
                  fontSize: 16, color: AppColors.cosmicTextMid)),
          const SizedBox(width: 6),
          Expanded(
              child:
                  Text(house.sign, style: AppTextStyles.bodyMedium())),
        ],
      ),
    );
  }
}

// ── Chart Summary row ─────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label, required this.value, this.isLast = false});
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.bodyMedium()),
              Text(value,
                  style: AppTextStyles.labelMedium(
                      color: AppColors.cosmicTextDark)),
            ],
          ),
        ),
        if (!isLast)
          Container(
              height: 0.8,
              color: AppColors.cardBorder),
      ],
    );
  }
}

// ── Tab toggle widget ─────────────────────────────────────────────────────────

class _ChartTab extends StatelessWidget {
  const _ChartTab(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? AppColors.featureDark : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.labelMedium(
              color: active
                  ? AppColors.cosmicGoldLight
                  : AppColors.cosmicTextLight,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Natal wheel painter (decorative) ─────────────────────────────────────────

class _NatalWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2 - 4;

    canvas.drawCircle(Offset(cx, cy), outerR,
        Paint()..color = const Color(0xFFF5EDE0));
    canvas.drawCircle(
        Offset(cx, cy),
        outerR,
        Paint()
          ..color = AppColors.cosmicGold.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);

    for (final f in [0.82, 0.62, 0.44]) {
      canvas.drawCircle(
          Offset(cx, cy),
          outerR * f,
          Paint()
            ..color = AppColors.cosmicGold.withOpacity(0.28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9);
    }

    final spoke = Paint()
      ..color = AppColors.cosmicTextMid.withOpacity(0.35)
      ..strokeWidth = 0.8;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawLine(
        Offset(cx + outerR * 0.44 * math.cos(a),
            cy + outerR * 0.44 * math.sin(a)),
        Offset(cx + outerR * math.cos(a), cy + outerR * math.sin(a)),
        spoke,
      );
    }

    final pts = List.generate(6, (i) {
      final a = i * math.pi / 3 - math.pi / 2;
      return Offset(cx + outerR * 0.44 * math.cos(a),
          cy + outerR * 0.44 * math.sin(a));
    });
    final red = Paint()
      ..color = const Color(0xFFB04040).withOpacity(0.65)
      ..strokeWidth = 1;
    final green = Paint()
      ..color = const Color(0xFF407040).withOpacity(0.65)
      ..strokeWidth = 1;
    for (var i = 0; i < pts.length; i++) {
      canvas.drawLine(pts[i], pts[(i + 2) % 6], red);
      canvas.drawLine(pts[i], pts[(i + 3) % 6], green);
    }

    const syms = [
      '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓', '♈', '♉'
    ];
    final symR = outerR * 0.91;
    for (var i = 0; i < 12; i++) {
      final a =
          (i * math.pi / 6) + (math.pi / 12) - math.pi / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: syms[i],
          style: TextStyle(
              fontSize: outerR * 0.09,
              color: AppColors.cosmicTextMid),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(cx + symR * math.cos(a) - tp.width / 2,
              cy + symR * math.sin(a) - tp.height / 2));
    }

    const glyphs = [
      ('☉', 0.30, 0.10),
      ('☽', 0.70, 0.00),
      ('☿', 0.82, -0.15),
      ('♀', 0.55, 0.28),
      ('♂', 0.12, -0.10),
      ('♃', 0.22, 0.25),
      ('♄', -0.10, 0.10),
    ];
    for (final (sym, rx, ry) in glyphs) {
      final tp = TextPainter(
        text: TextSpan(
          text: sym,
          style: TextStyle(
            fontSize: outerR * 0.10,
            color: AppColors.cosmicTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(cx + outerR * 0.52 * rx - tp.width / 2,
              cy + outerR * 0.52 * ry - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
