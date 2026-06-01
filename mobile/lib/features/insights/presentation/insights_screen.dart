import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/insight_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

/// Insights — wired to backend all-insights endpoint.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int _tab = 0;

  static const _tabs = ['Love', 'Career', 'Money', 'Health'];
  static const _categories = ['love', 'career', 'money', 'health'];

  @override
  Widget build(BuildContext context) {
    final insightsAsync = ref.watch(allInsightsProvider);

    return CosmicScaffold(
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
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
                            child: Text('Insights',
                                style: AppTextStyles.headingMedium()),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: Row(
                      children: List.generate(
                        _tabs.length,
                        (i) => _InsightTab(
                          label: _tabs[i],
                          active: _tab == i,
                          onTap: () => setState(() => _tab = i),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: insightsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.cosmicGold),
                      ),
                      error: (e, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_outlined,
                                  color: AppColors.cosmicTextLight,
                                  size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Could not load insights.',
                                style: AppTextStyles.bodyMedium(
                                    color: AppColors.cosmicTextMid),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (insights) {
                        final cat = _categories[_tab];
                        final insight = insights
                            .where((i) => i.category == cat)
                            .firstOrNull;
                        if (insight == null) {
                          return const Center(
                              child: Text('No data for this category'));
                        }
                        return _InsightBody(
                          insight: insight,
                          tabLabel: _tabs[_tab],
                          onDetail: () =>
                              context.go('/insights/${_tabs[_tab]}'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          CosmicBottomNav(
            currentIndex: 1,
            onTap: (i) {
              switch (i) {
                case 0:
                  context.go('/home');
                  break;
                case 1:
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
            },
          ),
        ],
      ),
    );
  }
}

class _InsightBody extends StatelessWidget {
  const _InsightBody({
    required this.insight,
    required this.tabLabel,
    required this.onDetail,
  });
  final InsightModel insight;
  final String tabLabel;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _InsightCard(insight: insight, label: tabLabel),
              const SizedBox(height: 20),
              if (insight.bestPeriods.isNotEmpty) ...[
                Text('Best Time Periods',
                    style: AppTextStyles.headingMedium()),
                const SizedBox(height: 12),
                ...insight.bestPeriods.map(
                  (p) => _PeriodTile(label: p),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.btnBg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('DETAILED ANALYSIS',
                      style: AppTextStyles.sectionCaps(
                          color: AppColors.btnText)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward,
                      color: AppColors.btnText, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightTab extends StatelessWidget {
  const _InsightTab({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Text(
          label,
          style: AppTextStyles.labelMedium(
            color: active
                ? AppColors.cosmicGoldLight
                : AppColors.cosmicTextLight,
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.label});
  final InsightModel insight;
  final String label;

  @override
  Widget build(BuildContext context) {
    final score = insight.score;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.featureDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.cosmicGold.withOpacity(0.3), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$label Outlook',
                      style: AppTextStyles.headingMedium(
                          color: AppColors.white)),
                  Text(
                    '${insight.periodStart.substring(0, 7)} – ${insight.periodEnd.substring(0, 7)}',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.white.withOpacity(0.6)),
                  ),
                ],
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score,
                      strokeWidth: 6,
                      backgroundColor:
                          AppColors.cosmicGold.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.cosmicGold),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${insight.scorePercent}%',
                      style: AppTextStyles.headingMedium(
                          color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.content,
            style: AppTextStyles.bodySmall(
                color: AppColors.white.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CosmicCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cosmicGold.withOpacity(0.14),
              ),
              child: const Icon(Icons.radio_button_unchecked,
                  color: AppColors.cosmicGold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.labelLarge()),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBgAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text('High',
                  style: AppTextStyles.labelSmall()),
            ),
          ],
        ),
      ),
    );
  }
}
