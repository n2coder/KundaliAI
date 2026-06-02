import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/lang_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

/// Home screen – shows user name from auth state + today's panchang summary.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return CosmicScaffold(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _HomeAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const _CosmicWeatherCard(),
                      const SizedBox(height: 22),
                      _SectionHeader(AppStrings.tr('quick_access', lang)),
                      const SizedBox(height: 10),
                      const _QuickAccessGrid(),
                      const SizedBox(height: 22),
                      _SectionHeader(AppStrings.tr('your_life_scores', lang)),
                      const SizedBox(height: 12),
                      const _LifeScoresRow(),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionHeader(AppStrings.tr('planetary_transit', lang)),
                          TextButton(
                            onPressed: () => context.push('/transits'),
                            child: Text(AppStrings.tr('view_all', lang),
                                style: AppTextStyles.bodySmall(
                                    color: AppColors.cosmicGoldLight)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _PlanetaryTransitCard(),
                      const SizedBox(height: 22),
                      _SectionHeader(AppStrings.tr('whatsapp_delivery', lang)),
                      const SizedBox(height: 10),
                      const _WhatsAppCard(),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          CosmicBottomNav(
            currentIndex: 0,
            onTap: (i) => _onNavTap(context, i),
          ),
        ],
      ),
    );
  }

  void _onNavTap(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/insights');
        break;
      case 2:
        context.go('/chat');
        break;
      case 3:
        context.go('/guidance');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}

class _HomeAppBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final lang = ref.watch(langProvider);
    final firstName =
        user?.name?.split(' ').first ?? user?.phone ?? 'There';
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 0,
      toolbarHeight: 64,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            AppStrings.tr('home_greeting', lang)
                                .replaceFirst('{name}', firstName),
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headingLarge(
                                color: AppColors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('👋', style: TextStyle(fontSize: 22)),
                      ],
                    ),
                    Text(AppStrings.tr('home_tagline', lang),
                        style: AppTextStyles.bodySmall(
                            color: AppColors.white.withOpacity(0.75))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _LanguageToggle(),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBg.withOpacity(0.85),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: AppColors.cosmicTextDark, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// EN / HI pill toggle shown next to the notification bell.
class _LanguageToggle extends ConsumerWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return GestureDetector(
      onTap: () => ref.read(langProvider.notifier).toggle(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langChip('EN', lang == 'en'),
            _langChip('हि', lang == 'hi'),
          ],
        ),
      ),
    );
  }

  Widget _langChip(String label, bool active) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.cosmicGold : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium(
              color: active ? AppColors.cosmicBase : AppColors.cosmicTextMid),
        ),
      );
}

Widget _SectionHeader(String title) => Text(
      title,
      style: AppTextStyles.sectionCaps(),
    );

// ── Today's Cosmic Weather card (with panchang data) ─────────────────────────

class _CosmicWeatherCard extends ConsumerWidget {
  const _CosmicWeatherCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayProvider);
    final lang = ref.watch(langProvider);

    return Container(
      width: double.infinity,
      height: 172,
      decoration: BoxDecoration(
        color: AppColors.featureDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.cosmicGold.withOpacity(0.3), width: 0.8),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(painter: _WeatherCardBg()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tr('todays_cosmic_weather', lang),
                  style: AppTextStyles.sectionCaps(
                      color: AppColors.cosmicGoldLight),
                ),
                const SizedBox(height: 8),
                todayAsync.when(
                  loading: () => Row(
                    children: [
                      Text('☀',
                          style: TextStyle(
                              fontSize: 24,
                              color: AppColors.cosmicGoldLight)),
                      const SizedBox(width: 8),
                      Text(AppStrings.tr('loading_weather', lang),
                          style: AppTextStyles.headingMedium(
                              color: AppColors.white)),
                    ],
                  ),
                  error: (_, __) => Text(
                    'A day of Growth\n& New Opportunities',
                    style: AppTextStyles.headingMedium(
                        color: AppColors.white),
                  ),
                  data: (today) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('☀',
                          style: TextStyle(
                              fontSize: 24,
                              color: AppColors.cosmicGoldLight)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${today.panchang.tithi} · ${today.panchang.nakshatra}',
                              style: AppTextStyles.headingMedium(
                                  color: AppColors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${today.panchang.vara} · Sunrise ${today.panchang.sunrise}',
                              style: AppTextStyles.bodySmall(
                                  color:
                                      AppColors.white.withOpacity(0.75)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context.push('/explore-today'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppStrings.tr('explore_today', lang),
                            style: AppTextStyles.sectionCaps(
                                color: AppColors.cosmicTextDark)),
                        const SizedBox(width: 5),
                        const Icon(Icons.arrow_forward,
                            size: 12,
                            color: AppColors.cosmicTextDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherCardBg extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final hills = Paint()
      ..color = AppColors.featureDarkLight.withOpacity(0.7);
    final path = Path()
      ..moveTo(size.width * 0.35, size.height)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.4,
          size.width * 0.72, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.3,
          size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, hills);
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.32),
      26,
      Paint()
        ..color = AppColors.cosmicGoldLight.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.32),
      16,
      Paint()..color = AppColors.cosmicGoldLight.withOpacity(0.55),
    );
    for (final pt in [
      Offset(size.width * 0.60, size.height * 0.18),
      Offset(size.width * 0.92, size.height * 0.12),
      Offset(size.width * 0.75, size.height * 0.55),
    ]) {
      canvas.drawCircle(
          pt, 1.5, Paint()..color = AppColors.cosmicGoldGlow.withOpacity(0.8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Quick Access ──────────────────────────────────────────────────────────────

const _quickItems = [
  (icon: Icons.calendar_month_outlined, key: 'qa_daily_horoscope', route: '/horoscope'),
  (icon: Icons.radio_button_unchecked,  key: 'qa_birth_chart',     route: '/birth-chart'),
  (icon: Icons.auto_awesome_outlined,   key: 'qa_ai_chat',         route: '/chat'),
  (icon: Icons.favorite_border,         key: 'qa_compatibility',   route: '/compatibility'),
];

class _QuickAccessGrid extends ConsumerWidget {
  const _QuickAccessGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return Row(
      children: _quickItems.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.push(item.route),
              child: CosmicCard(
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 6),
                child: Column(
                  children: [
                    Icon(item.icon,
                        color: AppColors.cosmicTextDark, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.tr(item.key, lang),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall(
                          color: AppColors.cosmicTextDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Life Scores (wired to todayProvider) ─────────────────────────────────────

class _LifeScoresRow extends ConsumerWidget {
  const _LifeScoresRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final lifeScores = ref.watch(todayProvider).valueOrNull?.lifeScores;

    final scores = [
      (label: AppStrings.tr('score_love', lang),   value: lifeScores?.love   ?? 0.72, color: AppColors.scoreLove),
      (label: AppStrings.tr('score_career', lang), value: lifeScores?.career ?? 0.85, color: AppColors.scoreCareer),
      (label: AppStrings.tr('score_health', lang), value: lifeScores?.health ?? 0.68, color: AppColors.scoreHealth),
      (label: AppStrings.tr('score_money', lang),  value: lifeScores?.money  ?? 0.75, color: AppColors.scoreMoney),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: scores.map((s) {
        return CosmicCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SizedBox(
                width: 66,
                height: 66,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: s.value,
                      strokeWidth: 5.5,
                      backgroundColor: s.color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(s.color),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${(s.value * 100).round()}%',
                      style: AppTextStyles.labelMedium(color: s.color),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(s.label, style: AppTextStyles.bodySmall()),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Planetary Transit card (wired to transitsProvider) ───────────────────────

class _PlanetaryTransitCard extends ConsumerWidget {
  const _PlanetaryTransitCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transitsAsync = ref.watch(transitsProvider);
    return transitsAsync.when(
      loading: () => _TransitCardContent(
        planet: 'Jupiter in Taurus',
        period: 'May 2024 – May 2025',
        description: 'Great time for financial growth, stability & long-term gains.',
        isLoading: true,
      ),
      error: (_, __) => _TransitCardContent(
        planet: 'Jupiter in Taurus',
        period: 'May 2024 – May 2025',
        description: 'Great time for financial growth, stability & long-term gains.',
        isLoading: false,
      ),
      data: (transits) {
        if (transits.isEmpty) {
          return _TransitCardContent(
            planet: 'No active transits',
            period: '',
            description: 'Check back soon for planetary transit updates.',
            isLoading: false,
          );
        }
        final t = transits.first;
        return _TransitCardContent(
          planet: '${t.planet} in ${t.to}',
          period: t.period,
          description: t.description,
          isLoading: false,
        );
      },
    );
  }
}

class _TransitCardContent extends StatelessWidget {
  const _TransitCardContent({
    required this.planet,
    required this.period,
    required this.description,
    required this.isLoading,
  });
  final String planet;
  final String period;
  final String description;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.featureDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.cosmicGold.withOpacity(0.3), width: 0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(planet,
                    style: AppTextStyles.headingMedium(
                        color: AppColors.white)),
                if (period.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(period,
                      style: AppTextStyles.bodySmall(
                          color: AppColors.white.withOpacity(0.55))),
                ],
                const SizedBox(height: 8),
                Text(
                  description.length > 80
                      ? '${description.substring(0, 80)}…'
                      : description,
                  style: AppTextStyles.bodySmall(
                      color: AppColors.white.withOpacity(0.75)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 70,
            height: 70,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.cosmicGold, strokeWidth: 2))
                : CustomPaint(painter: _JupiterPainter()),
          ),
        ],
      ),
    );
  }
}

class _JupiterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 2;
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFFD4A060),
            Color(0xFFA07030),
            Color(0xFF704820),
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
    for (var i = 0; i < 4; i++) {
      final y = cy - r * 0.5 + i * r * 0.35;
      canvas.drawLine(
        Offset(cx - r * math.sqrt(1 - math.pow((y - cy) / r, 2)), y),
        Offset(cx + r * math.sqrt(1 - math.pow((y - cy) / r, 2)), y),
        Paint()
          ..color = const Color(0xFFC09050).withOpacity(0.4)
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── WhatsApp Delivery card ────────────────────────────────────────────────────

class _WhatsAppCard extends ConsumerStatefulWidget {
  const _WhatsAppCard();

  @override
  ConsumerState<_WhatsAppCard> createState() => _WhatsAppCardState();
}

class _WhatsAppCardState extends ConsumerState<_WhatsAppCard> {
  bool _saving = false;
  String _time = '07:00';

  Future<void> _toggle(bool v) async {
    setState(() => _saving = true);
    try {
      await ref.read(horoscopeRepoProvider).updateWhatsApp(enabled: v);
      final user = ref.read(authProvider).valueOrNull;
      if (user != null) {
        ref
            .read(authProvider.notifier)
            .updateUser(user.copyWith(whatsappEnabled: v));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final enabled = user?.whatsappEnabled ?? false;
    final lang = ref.watch(langProvider);

    return CosmicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF25D366).withOpacity(0.15),
                  border: Border.all(
                      color: const Color(0xFF25D366).withOpacity(0.4)),
                ),
                child: const Icon(Icons.chat_bubble_rounded,
                    color: Color(0xFF25D366), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.tr('whatsapp_card_title', lang),
                        style: AppTextStyles.labelLarge()),
                    const SizedBox(height: 2),
                    Text(
                        AppStrings.tr('whatsapp_card_subtitle', lang),
                        style: AppTextStyles.bodySmall()),
                  ],
                ),
              ),
              _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.cosmicGold))
                  : Switch(
                      value: enabled,
                      onChanged: _toggle,
                      activeColor: const Color(0xFF25D366),
                    ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 14),
            Text(AppStrings.tr('delivery_time', lang),
                style: AppTextStyles.sectionCaps(
                    color: AppColors.cosmicGold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['06:00', '07:00', '08:00', '09:00'].map((t) {
                final active = _time == t;
                return GestureDetector(
                  onTap: () {
                    setState(() => _time = t);
                    ref
                        .read(horoscopeRepoProvider)
                        .updateWhatsApp(enabled: true, deliveryTime: t);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.featureDark
                          : AppColors.cardBgAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? AppColors.cosmicGold.withOpacity(0.5)
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      t,
                      style: AppTextStyles.labelSmall(
                          color: active
                              ? AppColors.cosmicGoldLight
                              : AppColors.cosmicTextLight),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
