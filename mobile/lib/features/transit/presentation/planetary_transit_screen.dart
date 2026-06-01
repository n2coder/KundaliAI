import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/transit_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

// Fallback static data shown when the API is unavailable
const _fallbackTransits = [
  TransitModel(
    planet: 'Jupiter', glyph: '♃',
    from: 'Taurus', to: 'Gemini',
    period: 'May 2024 – May 2025', impact: 'High',
    description: "Jupiter's transit through Taurus brings material abundance, financial growth, and stability. This is a year to build lasting assets and make long-term investments.",
    advice: 'Invest in real estate or long-term instruments. Avoid impulsive spending.',
  ),
  TransitModel(
    planet: 'Saturn', glyph: '♄',
    from: 'Aquarius', to: 'Pisces',
    period: 'Mar 2023 – Feb 2026', impact: 'Medium',
    description: 'Saturn in Pisces asks you to release illusions and build spiritual discipline. Challenges in the 12th house bring introspection and karmic clearing.',
    advice: 'Practice meditation daily. Address hidden fears and emotional baggage.',
  ),
  TransitModel(
    planet: 'Rahu', glyph: '☊',
    from: 'Pisces', to: 'Aquarius',
    period: 'Oct 2023 – Apr 2025', impact: 'High',
    description: 'Rahu in Pisces amplifies spiritual curiosity, foreign connections, and hidden opportunities. Unexpected gains are possible through non-traditional means.',
    advice: 'Explore meditation, foreign travel, or online income streams.',
  ),
  TransitModel(
    planet: 'Ketu', glyph: '☋',
    from: 'Virgo', to: 'Leo',
    period: 'Oct 2023 – Apr 2025', impact: 'Medium',
    description: 'Ketu in Virgo encourages detachment from perfectionism and routine. A time to release what no longer serves your growth and focus on the bigger picture.',
    advice: "Delegate daily tasks. Don't over-analyse; trust your intuition.",
  ),
  TransitModel(
    planet: 'Mars', glyph: '♂',
    from: 'Cancer', to: 'Leo',
    period: 'Jun 2024 – Jul 2024', impact: 'Low',
    description: 'Mars in Cancer can create emotional restlessness and family tensions. Energy is best directed toward home improvements and nurturing relationships.',
    advice: 'Channel energy into fitness or home projects. Avoid arguments at home.',
  ),
];

Color _transitColor(String planet) => switch (planet) {
      'Jupiter' => AppColors.cosmicGold,
      'Saturn'  => AppColors.scoreHealth,
      'Rahu'    => AppColors.scoreLove,
      'Ketu'    => AppColors.scoreCareer,
      'Mars'    => AppColors.scoreMoney,
      'Venus'   => AppColors.scoreLove,
      'Mercury' => AppColors.scoreCareer,
      'Sun'     => AppColors.cosmicGoldLight,
      'Moon'    => AppColors.scoreHealth,
      _         => AppColors.cosmicGold,
    };

/// Full planetary transits catalog — all active transits with expandable detail.
class PlanetaryTransitScreen extends ConsumerStatefulWidget {
  const PlanetaryTransitScreen({super.key});

  @override
  ConsumerState<PlanetaryTransitScreen> createState() =>
      _PlanetaryTransitScreenState();
}

class _PlanetaryTransitScreenState
    extends ConsumerState<PlanetaryTransitScreen> {
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    final transitsAsync = ref.watch(transitsProvider);

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
                      child: Column(
                        children: [
                          Text('Planetary Transits',
                              style: AppTextStyles.headingMedium()),
                          Text('Active • 2024–2025',
                              style: AppTextStyles.bodySmall()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Transit wheel hero
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 180,
                child: CustomPaint(
                  painter: _TransitWheelPainter(),
                  child: const SizedBox.expand(),
                ),
              ),
            ),

            // Transit list
            Expanded(
              child: transitsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.cosmicGold)),
                error: (_, __) => _TransitList(
                  transits: _fallbackTransits,
                  expanded: _expanded,
                  onTap: (i) =>
                      setState(() => _expanded = _expanded == i ? null : i),
                ),
                data: (transits) => _TransitList(
                  transits: transits.isEmpty ? _fallbackTransits : transits,
                  expanded: _expanded,
                  onTap: (i) =>
                      setState(() => _expanded = _expanded == i ? null : i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransitList extends StatelessWidget {
  const _TransitList({
    required this.transits,
    required this.expanded,
    required this.onTap,
  });
  final List<TransitModel> transits;
  final int? expanded;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: transits.length,
      itemBuilder: (_, i) {
        final t = transits[i];
        final open = expanded == i;
        final color = _transitColor(t.planet);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onTap(i),
            child: CosmicCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.12),
                          border:
                              Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text(t.glyph,
                              style:
                                  TextStyle(fontSize: 22, color: color)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.planet,
                                style: AppTextStyles.labelLarge()),
                            const SizedBox(height: 2),
                            Text('${t.from} → ${t.to}',
                                style: AppTextStyles.bodySmall(
                                    color:
                                        AppColors.cosmicTextLight)),
                            const SizedBox(height: 2),
                            Text(t.period,
                                style: AppTextStyles.labelSmall(
                                    color: color)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _ImpactBadge(label: t.impact, color: color),
                          const SizedBox(height: 6),
                          Icon(
                            open
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.cosmicTextLight,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (open) ...[
                    const SizedBox(height: 12),
                    Container(height: 0.8, color: AppColors.cardBorder),
                    const SizedBox(height: 12),
                    Text(t.description,
                        style: AppTextStyles.bodyMedium()),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: color, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(t.advice,
                                style: AppTextStyles.bodySmall(
                                    color:
                                        AppColors.cosmicTextMid)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.btnBg,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.auto_awesome,
                            color: AppColors.cosmicGold, size: 14),
                        label: Text(
                            'ASK AI ABOUT ${t.planet.toUpperCase()}',
                            style: AppTextStyles.sectionCaps(
                                color: AppColors.btnText)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ImpactBadge extends StatelessWidget {
  const _ImpactBadge({required this.label, required this.color});
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
      child: Text(label, style: AppTextStyles.labelSmall(color: color)),
    );
  }
}

class _TransitWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 10;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = AppColors.cosmicWheelBg
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = AppColors.cosmicGold.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.62,
      Paint()
        ..color = AppColors.cosmicGold.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    const glyphs = ['♃', '♄', '☊', '☋', '♂'];
    const colors = [
      AppColors.cosmicGold,
      AppColors.scoreHealth,
      AppColors.scoreLove,
      AppColors.scoreCareer,
      AppColors.scoreMoney,
    ];
    for (var i = 0; i < glyphs.length; i++) {
      final angle = (i * 2 * math.pi / glyphs.length) - math.pi / 2;
      final px = cx + (r * 0.80) * math.cos(angle);
      final py = cy + (r * 0.80) * math.sin(angle);

      canvas.drawCircle(
        Offset(px, py),
        14,
        Paint()
          ..color = colors[i].withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: glyphs[i],
          style: TextStyle(fontSize: 18, color: colors[i]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(px - tp.width / 2, py - tp.height / 2));
    }

    final tp = TextPainter(
      text: const TextSpan(
        text: '✦',
        style: TextStyle(fontSize: 20, color: AppColors.cosmicGoldLight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
