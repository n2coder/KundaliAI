import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/lang_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

/// Today's Horoscope â€” wired to backend daily/weekly/monthly endpoints.
class HoroscopeScreen extends ConsumerStatefulWidget {
  const HoroscopeScreen({super.key});

  @override
  ConsumerState<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends ConsumerState<HoroscopeScreen> {
  int _tab = 0; // 0=Today 1=Weekly 2=Monthly

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final lang = ref.watch(langProvider);
    final horoscope = switch (_tab) {
      0 => ref.watch(dailyHoroscopeProvider),
      1 => ref.watch(weeklyHoroscopeProvider),
      _ => ref.watch(monthlyHoroscopeProvider),
    };

    return CosmicScaffold(
      child: SafeArea(
        child: Column(
          children: [
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
                      child: Text(AppStrings.tr('todays_horoscope', lang),
                          style: AppTextStyles.headingMedium(
                              color: AppColors.white)),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cosmicGold, width: 1.5),
                color: AppColors.cosmicWheelBg.withOpacity(0.7),
              ),
              child: Center(
                child: Text(
                  'â™Œ',
                  style: TextStyle(
                      fontSize: 36, color: AppColors.cosmicGoldLight),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user != null ? '' : AppStrings.tr('your_sign', lang),
              style: AppTextStyles.headingLarge(color: AppColors.white),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cardBg.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _Tab(
                        label: AppStrings.tr('tab_today', lang),
                        active: _tab == 0,
                        onTap: () => setState(() => _tab = 0)),
                    _Tab(
                        label: AppStrings.tr('tab_this_week', lang),
                        active: _tab == 1,
                        onTap: () => setState(() => _tab = 1)),
                    _Tab(
                        label: AppStrings.tr('tab_this_month', lang),
                        active: _tab == 2,
                        onTap: () => setState(() => _tab = 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: horoscope.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.cosmicGold),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined,
                            color: AppColors.cosmicTextLight, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.tr('horoscope_load_error', lang),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(
                              color: AppColors.cosmicTextMid),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (h) => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _HoroscopeContentCard(content: h.content),
                    const SizedBox(height: 12),
                    const _HoroscopeWhatsAppCard(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.btnBg,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.share_outlined,
                            size: 18, color: AppColors.btnText),
                        label: Text(AppStrings.tr('share', lang),
                            style: AppTextStyles.sectionCaps(
                                color: AppColors.btnText)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.chat_bubble_rounded,
                            size: 18, color: Colors.white),
                        label: Text(AppStrings.tr('whatsapp_caps', lang),
                            style: AppTextStyles.sectionCaps(
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});
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

class _HoroscopeContentCard extends ConsumerWidget {
  const _HoroscopeContentCard({required this.content});
  final String content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return CosmicCard(
      padding: const EdgeInsets.all(18),
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
                  color: AppColors.cosmicGold.withOpacity(0.14),
                ),
                child: const Center(
                  child: Text('â˜€',
                      style: TextStyle(
                          fontSize: 20, color: AppColors.cosmicGold)),
                ),
              ),
              const SizedBox(width: 14),
              Text(AppStrings.tr('your_reading', lang),
                  style: AppTextStyles.labelLarge(
                      color: AppColors.cosmicTextDark)),
            ],
          ),
          const SizedBox(height: 14),
          Text(content, style: AppTextStyles.bodyMedium()),
        ],
      ),
    );
  }
}

class _HoroscopeWhatsAppCard extends ConsumerStatefulWidget {
  const _HoroscopeWhatsAppCard();

  @override
  ConsumerState<_HoroscopeWhatsAppCard> createState() =>
      _HoroscopeWhatsAppCardState();
}

class _HoroscopeWhatsAppCardState
    extends ConsumerState<_HoroscopeWhatsAppCard> {
  bool _enabled = false;
  bool _saving = false;

  Future<void> _toggle(bool v) async {
    setState(() => _saving = true);
    try {
      await ref.read(horoscopeRepoProvider).updateWhatsApp(enabled: v);
      setState(() => _enabled = v);
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final lang = ref.watch(langProvider);
    if (_enabled != (user?.whatsappEnabled ?? false) && !_saving) {
      _enabled = user?.whatsappEnabled ?? false;
    }
    return CosmicCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF25D366).withOpacity(0.12),
              border: Border.all(
                  color: const Color(0xFF25D366).withOpacity(0.4)),
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                color: Color(0xFF25D366), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.tr('get_daily_whatsapp', lang),
                    style: AppTextStyles.labelMedium()),
                const SizedBox(height: 2),
                Text(
                  _enabled
                      ? AppStrings.tr('delivering_at_7', lang)
                      : AppStrings.tr('never_miss_reading', lang),
                  style: AppTextStyles.bodySmall(
                      color: _enabled
                          ? AppColors.scoreCareer
                          : AppColors.cosmicTextLight),
                ),
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
                  value: _enabled,
                  onChanged: _toggle,
                  activeColor: const Color(0xFF25D366),
                ),
        ],
      ),
    );
  }
}
