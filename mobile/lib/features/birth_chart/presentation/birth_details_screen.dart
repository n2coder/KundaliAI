import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/lang_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

/// Onboarding screen: collects DOB, TOB, and birth place after first login.
class BirthDetailsScreen extends ConsumerStatefulWidget {
  const BirthDetailsScreen({super.key});

  @override
  ConsumerState<BirthDetailsScreen> createState() => _BirthDetailsScreenState();
}

class _BirthDetailsScreenState extends ConsumerState<BirthDetailsScreen> {
  final _nameCtrl = TextEditingController();
  DateTime? _dob;
  TimeOfDay? _tob;
  bool _submitting = false;

  // Preset cities for testing — bypasses geocoding entirely
  static const _cities = [
    ('New Delhi',      28.6139,  77.2090),
    ('Noida',          28.5355,  77.3910),
    ('Gurugram',       28.4595,  77.0266),
    ('Ghaziabad',      28.6692,  77.4538),
    ('Faridabad',      28.4089,  77.3178),
    ('Greater Noida',  28.4744,  77.5040),
    ('Lucknow',        26.8467,  80.9462),
    ('Kanpur',         26.4499,  80.3319),
    ('Agra',           27.1767,  78.0081),
    ('Varanasi',       25.3176,  82.9739),
    ('Prayagraj',      25.4358,  81.8463),
    ('Meerut',         28.9845,  77.7064),
  ];
  String? _selectedCity;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
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
    if (picked != null) setState(() => _dob = picked);
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
    if (picked != null) setState(() => _tob = picked);
  }

  Future<void> _submit() async {
    if (_dob == null || _tob == null || _selectedCity == null) return;
    setState(() => _submitting = true);

    // Web preview — skip real API and go straight to home
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) context.go('/home');
      return;
    }

    try {
      final city = _cities.firstWhere((c) => c.$1 == _selectedCity!);
      final repo = ref.read(birthChartRepoProvider);
      final dobStr = DateFormat('yyyy-MM-dd').format(_dob!);
      final h = _tob!.hour.toString().padLeft(2, '0');
      final m = _tob!.minute.toString().padLeft(2, '0');
      final tobStr = '$h:$m:00';
      await repo.computeChart(
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        dob: dobStr,
        tob: tobStr,
        birthPlace: city.$1,
        birthLat: city.$2,
        birthLng: city.$3,
      );
      final authRepo = ref.read(authRepoProvider);
      final updatedUser = await authRepo.getMe();
      ref.read(authProvider.notifier).updateUser(updatedUser);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _submitting = false);
      String msg = AppStrings.tr('save_failed', ref.read(langProvider));
      if (e is DioException) {
        final detail = (e.response?.data as Map?)?['detail']?.toString();
        msg = detail ?? 'Error ${e.response?.statusCode}: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    final canSubmit = _nameCtrl.text.trim().isNotEmpty &&
        _dob != null && _tob != null && _selectedCity != null;

    return CosmicScaffold(
      style: CosmicStyle.warm,
      child: Stack(
        children: [
          // Zodiac wheel image fills the top half as background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.50,
            child: Opacity(
              opacity: 0.55,
              child: Image.asset(
                'assets/images/zodiac_wheel.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Column(
                    children: [
                      const CosmicStarBadge(size: 52),
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.tr('your_birth_details', lang),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayMedium(
                            color: AppColors.cosmicGoldGlow),
                      ),
                      const SizedBox(height: 6),
                      const CosmicDivider(),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.tr('for_personalised_chart', lang),
                        style: AppTextStyles.bodyMedium(
                            color: AppColors.cosmicGoldLight),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    reverse: true,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Container(
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Full name
                  Text(AppStrings.tr('full_name', lang), style: AppTextStyles.labelLarge()),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    style: AppTextStyles.bodyLarge(),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: AppStrings.tr('enter_full_name', lang),
                      hintStyle: AppTextStyles.bodyMedium(
                          color: AppColors.cosmicTextLight),
                      prefixIcon: const Icon(Icons.person_outline,
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
                  const SizedBox(height: 16),

                  // Date of birth
                  Text(AppStrings.tr('dob', lang), style: AppTextStyles.labelLarge()),
                  const SizedBox(height: 8),
                  _PickerTile(
                    icon: Icons.calendar_today_outlined,
                    label: _dob == null
                        ? AppStrings.tr('select_date', lang)
                        : DateFormat('dd MMMM yyyy').format(_dob!),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),

                  // Time of birth
                  Text(AppStrings.tr('tob', lang), style: AppTextStyles.labelLarge()),
                  const SizedBox(height: 8),
                  _PickerTile(
                    icon: Icons.access_time,
                    label: _tob == null
                        ? AppStrings.tr('select_time', lang)
                        : _tob!.format(context),
                    onTap: _pickTime,
                  ),
                  const SizedBox(height: 16),

                  // Place of birth — preset city dropdown
                  Text(AppStrings.tr('place_of_birth', lang), style: AppTextStyles.labelLarge()),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    hint: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.cosmicGold, size: 20),
                        const SizedBox(width: 10),
                        Text(AppStrings.tr('select_city', lang),
                            style: AppTextStyles.bodyMedium(
                                color: AppColors.cosmicTextLight)),
                      ],
                    ),
                    dropdownColor: AppColors.featureDark,
                    style: AppTextStyles.bodyLarge(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.cosmicGold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cardBgAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.cosmicGold, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                    items: _cities.map((c) => DropdownMenuItem(
                      value: c.$1,
                      child: Text(c.$1, style: AppTextStyles.bodyLarge()),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedCity = v),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (!canSubmit || _submitting) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.btnBg,
                        foregroundColor: AppColors.btnText,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.cosmicGoldLight),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(AppStrings.tr('generate_my_chart', lang),
                                    style: AppTextStyles.buttonText(
                                        color: AppColors.cosmicGoldLight)),
                                const SizedBox(width: 8),
                                const Icon(Icons.auto_awesome,
                                    color: AppColors.cosmicGoldLight, size: 18),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
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

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

