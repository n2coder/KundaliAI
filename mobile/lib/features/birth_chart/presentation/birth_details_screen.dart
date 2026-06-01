import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  final _nameCtrl  = TextEditingController();
  final _placeCtrl = TextEditingController();
  DateTime? _dob;
  TimeOfDay? _tob;
  double? _lat;
  double? _lng;
  bool _geocoding = false;
  bool _submitting = false;
  String? _placeError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _placeCtrl.dispose();
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

  Future<void> _geocodePlace() async {
    final place = _placeCtrl.text.trim();
    if (place.isEmpty) return;
    setState(() {
      _geocoding = true;
      _placeError = null;
    });
    try {
      final repo = ref.read(birthChartRepoProvider);
      final result = await repo.geocode(place);
      setState(() {
        _lat = result.lat;
        _lng = result.lng;
        _geocoding = false;
      });
    } catch (e) {
      setState(() {
        _placeError = 'Place not found. Try a different name.';
        _geocoding = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_dob == null || _tob == null || _placeCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);

    // Web preview — skip real API and go straight to home
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) context.go('/home');
      return;
    }

    try {
      final repo = ref.read(birthChartRepoProvider);
      final dobStr = DateFormat('yyyy-MM-dd').format(_dob!);
      final h = _tob!.hour.toString().padLeft(2, '0');
      final m = _tob!.minute.toString().padLeft(2, '0');
      final tobStr = '$h:$m:00';
      await repo.computeChart(
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        dob: dobStr,
        tob: tobStr,
        birthPlace: _placeCtrl.text.trim(),
        birthLat: _lat,
        birthLng: _lng,
      );
      final authRepo = ref.read(authRepoProvider);
      final updatedUser = await authRepo.getMe();
      ref.read(authProvider.notifier).updateUser(updatedUser);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save birth details. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _nameCtrl.text.trim().isNotEmpty &&
        _dob != null && _tob != null && _placeCtrl.text.trim().isNotEmpty;

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
                        'Your Birth Details',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayMedium(
                            color: AppColors.cosmicGoldGlow),
                      ),
                      const SizedBox(height: 6),
                      const CosmicDivider(),
                      const SizedBox(height: 8),
                      Text(
                        'For your personalised Vedic chart',
                        style: AppTextStyles.bodyMedium(
                            color: AppColors.cosmicGoldLight),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
            Container(
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
                  Text('Full Name', style: AppTextStyles.labelLarge()),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    style: AppTextStyles.bodyLarge(),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
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
                  Text('Date of Birth', style: AppTextStyles.labelLarge()),
                  const SizedBox(height: 8),
                  _PickerTile(
                    icon: Icons.calendar_today_outlined,
                    label: _dob == null
                        ? 'Select date'
                        : DateFormat('dd MMMM yyyy').format(_dob!),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),

                  // Time of birth
                  Text('Time of Birth', style: AppTextStyles.labelLarge()),
                  const SizedBox(height: 8),
                  _PickerTile(
                    icon: Icons.access_time,
                    label: _tob == null
                        ? 'Select time'
                        : _tob!.format(context),
                    onTap: _pickTime,
                  ),
                  const SizedBox(height: 16),

                  // Place of birth
                  Text('Place of Birth', style: AppTextStyles.labelLarge()),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _placeCtrl,
                          onChanged: (_) => setState(() {}),
                          style: AppTextStyles.bodyLarge(),
                          decoration: InputDecoration(
                            hintText: 'e.g. Mumbai, Delhi',
                            hintStyle: AppTextStyles.bodyMedium(
                                color: AppColors.cosmicTextLight),
                            prefixIcon: const Icon(Icons.location_on_outlined,
                                color: AppColors.cosmicGold, size: 20),
                            errorText: _placeError,
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
                          onSubmitted: (_) => _geocodePlace(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _GeoButton(
                        loading: _geocoding,
                        confirmed: _lat != null,
                        onTap: _geocodePlace,
                      ),
                    ],
                  ),
                  if (_lat != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 14, color: AppColors.scoreCareer),
                        const SizedBox(width: 4),
                        Text(
                          'Location confirmed — ${_lat!.toStringAsFixed(2)}°, ${_lng!.toStringAsFixed(2)}°',
                          style: AppTextStyles.bodySmall(
                              color: AppColors.scoreCareer),
                        ),
                      ],
                    ),
                  ],
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
                                Text('Generate My Chart',
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

class _GeoButton extends StatelessWidget {
  const _GeoButton({
    required this.loading,
    required this.confirmed,
    required this.onTap,
  });
  final bool loading;
  final bool confirmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: confirmed ? AppColors.scoreCareer.withOpacity(0.15) : AppColors.btnBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.cosmicGoldLight),
              )
            : Icon(
                confirmed ? Icons.check : Icons.search,
                color: confirmed ? AppColors.scoreCareer : AppColors.cosmicGoldLight,
                size: 22,
              ),
      ),
    );
  }
}
