import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/lang_provider.dart';
import '../../../core/models/compatibility_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

/// Compatibility checker — partner birth details form + scored result view.
class CompatibilityScreen extends ConsumerStatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  ConsumerState<CompatibilityScreen> createState() =>
      _CompatibilityScreenState();
}

class _CompatibilityScreenState extends ConsumerState<CompatibilityScreen> {
  DateTime? _partnerDob;
  TimeOfDay? _partnerTob;
  final _placeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  CompatibilityModel? _result;

  @override
  void dispose() {
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.cosmicGold,
            surface: AppColors.featureDark,
            onSurface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _partnerDob = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.cosmicGold,
            surface: AppColors.featureDark,
            onSurface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _partnerTob = picked);
  }

  Future<void> _check() async {
    if (_partnerDob == null ||
        _partnerTob == null ||
        _placeCtrl.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dobStr = DateFormat('yyyy-MM-dd').format(_partnerDob!);
      final h = _partnerTob!.hour.toString().padLeft(2, '0');
      final m = _partnerTob!.minute.toString().padLeft(2, '0');
      final tobStr = '$h:$m:00';
      final result =
          await ref.read(compatibilityRepoProvider).check(
                partnerDob: dobStr,
                partnerTob: tobStr,
                partnerBirthPlace: _placeCtrl.text.trim(),
              );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = AppStrings.tr('compat_failed', ref.read(langProvider)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                      child: Text(AppStrings.tr('compatibility_title', lang),
                          style: AppTextStyles.headingMedium(
                              color: AppColors.white)),
                    ),
                  ),
                  if (_result != null)
                    TextButton(
                      onPressed: () => setState(() {
                        _result = null;
                        _error = null;
                      }),
                      child: Text(AppStrings.tr('reset', lang),
                          style: AppTextStyles.bodySmall(
                              color: AppColors.cosmicGold)),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: _result != null
                  ? _ResultView(
                      result: _result!,
                      partnerDob: _partnerDob!,
                      partnerPlace: _placeCtrl.text.trim(),
                    )
                  : _FormView(
                      partnerDob: _partnerDob,
                      partnerTob: _partnerTob,
                      placeCtrl: _placeCtrl,
                      loading: _loading,
                      error: _error,
                      onPickDate: _pickDate,
                      onPickTime: _pickTime,
                      onCheck: _check,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form view ─────────────────────────────────────────────────────────────────

class _FormView extends ConsumerWidget {
  const _FormView({
    required this.partnerDob,
    required this.partnerTob,
    required this.placeCtrl,
    required this.loading,
    required this.error,
    required this.onPickDate,
    required this.onPickTime,
    required this.onCheck,
  });

  final DateTime? partnerDob;
  final TimeOfDay? partnerTob;
  final TextEditingController placeCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final canCheck = partnerDob != null &&
        partnerTob != null &&
        placeCtrl.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Hero
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.featureDark,
                    border: Border.all(
                        color: AppColors.cosmicGold, width: 1.5),
                  ),
                  child: const Center(
                    child: Text('♡',
                        style: TextStyle(
                            fontSize: 34,
                            color: AppColors.scoreLove)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(AppStrings.tr('check_compatibility_title', lang),
                    style: AppTextStyles.headingLarge()),
                const SizedBox(height: 4),
                Text(AppStrings.tr('enter_partner_details', lang),
                    style: AppTextStyles.bodySmall()),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(AppStrings.tr('partner_birth_details', lang),
              style: AppTextStyles.sectionCaps()),
          const SizedBox(height: 12),

          CosmicCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.tr('dob', lang),
                    style: AppTextStyles.labelLarge()),
                const SizedBox(height: 8),
                _PickerTile(
                  icon: Icons.calendar_today_outlined,
                  label: partnerDob == null
                      ? AppStrings.tr('select_date', lang)
                      : DateFormat('dd MMMM yyyy').format(partnerDob!),
                  onTap: onPickDate,
                ),
                const SizedBox(height: 16),

                Text(AppStrings.tr('tob', lang),
                    style: AppTextStyles.labelLarge()),
                const SizedBox(height: 8),
                _PickerTile(
                  icon: Icons.access_time,
                  label: partnerTob == null
                      ? AppStrings.tr('select_time', lang)
                      : partnerTob!.format(context),
                  onTap: onPickTime,
                ),
                const SizedBox(height: 16),

                Text(AppStrings.tr('birth_place', lang), style: AppTextStyles.labelLarge()),
                const SizedBox(height: 8),
                TextField(
                  controller: placeCtrl,
                  style: AppTextStyles.bodyLarge(),
                  decoration: InputDecoration(
                    hintText: AppStrings.tr('place_hint', lang),
                    hintStyle: AppTextStyles.bodyMedium(
                        color: AppColors.cosmicTextLight),
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        color: AppColors.cosmicGold, size: 20),
                    filled: true,
                    fillColor: AppColors.cardBgAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.cosmicGold, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ],
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!,
                style: AppTextStyles.bodySmall(color: AppColors.error)),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: (loading || !canCheck) ? null : onCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.btnBg,
                foregroundColor: AppColors.btnText,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cosmicGoldLight),
                    )
                  : const Icon(Icons.favorite,
                      color: AppColors.scoreLove, size: 18),
              label: Text(
                loading
                    ? AppStrings.tr('checking', lang)
                    : AppStrings.tr('check_compatibility_btn', lang),
                style: AppTextStyles.buttonText(
                    color: AppColors.cosmicGoldLight),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Result view ───────────────────────────────────────────────────────────────

class _ResultView extends ConsumerWidget {
  const _ResultView({
    required this.result,
    required this.partnerDob,
    required this.partnerPlace,
  });

  final CompatibilityModel result;
  final DateTime partnerDob;
  final String partnerPlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Overall score hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.featureDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.cosmicGold.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(AppStrings.tr('compatibility_score', lang),
                    style: AppTextStyles.sectionCaps(
                        color: AppColors.cosmicGoldLight)),
                const SizedBox(height: 20),
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: result.overallScore,
                        strokeWidth: 8,
                        backgroundColor:
                            AppColors.cosmicGold.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.cosmicGold),
                        strokeCap: StrokeCap.round,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(result.overallScore * 100).round()}%',
                            style: AppTextStyles.headingLarge(
                                color: AppColors.cosmicGoldLight),
                          ),
                          Text(AppStrings.tr('match', lang),
                              style: AppTextStyles.bodySmall(
                                  color:
                                      AppColors.white.withOpacity(0.6))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  DateFormat('dd MMMM yyyy').format(partnerDob),
                  style: AppTextStyles.bodySmall(
                      color: AppColors.white.withOpacity(0.55)),
                ),
                Text(
                  partnerPlace,
                  style: AppTextStyles.bodySmall(
                      color: AppColors.white.withOpacity(0.55)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4 area scores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ScoreItem(
                  label: AppStrings.tr('score_love', lang),
                  value: result.loveScore,
                  color: AppColors.scoreLove),
              _ScoreItem(
                  label: AppStrings.tr('score_career', lang),
                  value: result.careerScore,
                  color: AppColors.scoreCareer),
              _ScoreItem(
                  label: AppStrings.tr('score_talk', lang),
                  value: result.communicationScore,
                  color: AppColors.scoreHealth),
              _ScoreItem(
                  label: AppStrings.tr('score_trust', lang),
                  value: result.trustScore,
                  color: AppColors.scoreMoney),
            ],
          ),

          const SizedBox(height: 16),

          // Summary
          CosmicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.tr('compatibility_summary', lang),
                    style: AppTextStyles.labelLarge(
                        color: AppColors.cosmicGold)),
                const SizedBox(height: 10),
                Text(result.summary,
                    style: AppTextStyles.bodyMedium()),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Strengths & Challenges
          CosmicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.tr('strengths', lang),
                    style: AppTextStyles.labelLarge(
                        color: AppColors.scoreCareer)),
                const SizedBox(height: 10),
                ...result.strengths.map((s) =>
                    _BulletRow(text: s, positive: true)),
                const SizedBox(height: 12),
                Text(AppStrings.tr('challenges', lang),
                    style: AppTextStyles.labelLarge(
                        color: AppColors.error)),
                const SizedBox(height: 10),
                ...result.challenges.map((c) =>
                    _BulletRow(text: c, positive: false)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Ask AI CTA
          SizedBox(
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
              label: Text(AppStrings.tr('ask_ai_compatibility', lang),
                  style: AppTextStyles.sectionCaps(
                      color: AppColors.btnText)),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _ScoreItem extends StatelessWidget {
  const _ScoreItem(
      {required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CosmicCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 5,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
                Text('${(value * 100).round()}%',
                    style: AppTextStyles.labelSmall(color: color)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.bodySmall()),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text, required this.positive});
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

class _PickerTile extends StatelessWidget {
  const _PickerTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBgAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.cosmicGold, size: 18),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyLarge()),
            const Spacer(),
            const Icon(Icons.chevron_right,
                color: AppColors.cosmicTextLight, size: 18),
          ],
        ),
      ),
    );
  }
}
