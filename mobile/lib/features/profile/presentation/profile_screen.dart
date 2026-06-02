import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/lang_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

/// User profile — real user data, trial countdown, settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final lang = ref.watch(langProvider);

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
                              color: AppColors.white, size: 18),
                          onPressed: () => context.go('/home'),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(AppStrings.tr('my_profile', lang),
                                style: AppTextStyles.headingMedium(
                                    color: AppColors.white)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppColors.white, size: 20),
                          onPressed: () => context.push('/birth-details'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 8),

                        // Avatar + name
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.featureDark,
                                  border: Border.all(
                                      color: AppColors.cosmicGold, width: 2),
                                ),
                                child: const Center(
                                  child: Text('♌',
                                      style: TextStyle(
                                          fontSize: 40,
                                          color: AppColors.cosmicGoldLight)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user?.name ?? user?.phone ?? '—',
                                style: AppTextStyles.headingLarge(
                                    color: AppColors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.phone ?? '',
                                style: AppTextStyles.bodySmall(
                                    color: AppColors.white.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Trial / subscription card
                        _TrialCard(
                          user: user,
                          lang: lang,
                          onUpgrade: () => _upgrade(context, ref),
                        ),
                        const SizedBox(height: 20),

                        // Birth details
                        _SectionHeader(AppStrings.tr('birth_details', lang)),
                        const SizedBox(height: 10),
                        CosmicCard(
                          child: Column(
                            children: [
                              _DetailRow(
                                icon: Icons.calendar_today_outlined,
                                label: AppStrings.tr('dob', lang),
                                value: user?.dob ?? '—',
                              ),
                              _DetailRow(
                                icon: Icons.access_time,
                                label: AppStrings.tr('tob', lang),
                                value: user?.tob ?? '—',
                              ),
                              _DetailRow(
                                icon: Icons.location_on_outlined,
                                label: AppStrings.tr('place_of_birth', lang),
                                value: user?.birthPlace ?? '—',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Settings
                        _SectionHeader(AppStrings.tr('settings', lang)),
                        const SizedBox(height: 10),
                        CosmicCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _SettingsTile(
                                icon: Icons.notifications_outlined,
                                label: AppStrings.tr('notifications', lang),
                                onTap: () => _comingSoon(context),
                              ),
                              _SettingsTile(
                                icon: Icons.language,
                                label: AppStrings.tr('language', lang),
                                trailing: lang == 'hi'
                                    ? AppStrings.tr('hindi', lang)
                                    : AppStrings.tr('english', lang),
                                onTap: () => _chooseLanguage(context, ref),
                              ),
                              _SettingsTile(
                                icon: Icons.privacy_tip_outlined,
                                label: AppStrings.tr('privacy_policy', lang),
                                onTap: () => _comingSoon(context),
                              ),
                              _SettingsTile(
                                icon: Icons.help_outline,
                                label: AppStrings.tr('help_support', lang),
                                onTap: () => _comingSoon(context),
                              ),
                              _SettingsTile(
                                icon: Icons.logout,
                                label: AppStrings.tr('sign_out', lang),
                                labelColor: AppColors.error,
                                onTap: () async {
                                  await ref
                                      .read(authProvider.notifier)
                                      .signOut();
                                  if (context.mounted) context.go('/');
                                },
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(AppStrings.tr('app_version', lang),
                              style: AppTextStyles.bodySmall(
                                  color: AppColors.white.withOpacity(0.5))),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          CosmicBottomNav(
            currentIndex: 4,
            onTap: (i) {
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
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  Future<void> _chooseLanguage(BuildContext context, WidgetRef ref) async {
    final current = ref.read(langProvider);
    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(AppStrings.tr('choose_language', current),
            style: AppTextStyles.headingMedium()),
        children: [
          for (final entry in const [('en', 'English'), ('hi', 'हिंदी')])
            RadioListTile<String>(
              value: entry.$1,
              groupValue: current,
              activeColor: AppColors.cosmicGold,
              title: Text(entry.$2, style: AppTextStyles.bodyMedium()),
              onChanged: (v) {
                if (v != null) ref.read(langProvider.notifier).setLang(v);
                Navigator.of(ctx).pop();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _upgrade(BuildContext context, WidgetRef ref) async {
    final lang = ref.read(langProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final resp = await ref.read(dioProvider).post(ApiEndpoints.paymentCreate);
      final url = (resp.data as Map<String, dynamic>?)?['short_url'] as String?;
      if (url != null && url.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: url));
        messenger.showSnackBar(SnackBar(
            content: Text(AppStrings.tr('checkout_link_copied', lang))));
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(AppStrings.tr('payment_unavailable', lang))));
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(
          content: Text(AppStrings.tr('payment_unavailable', lang))));
    }
  }
}

// ── Trial / subscription card with countdown + premium feature list ─────────

class _TrialCard extends StatelessWidget {
  const _TrialCard({
    required this.user,
    required this.lang,
    required this.onUpgrade,
  });

  final UserModel? user;
  final String lang;
  final VoidCallback onUpgrade;

  static const _features = [
    (icon: Icons.auto_awesome_outlined, key: 'feat_ai_chat'),
    (icon: Icons.insights_outlined, key: 'feat_detailed_insights'),
    (icon: Icons.chat_bubble_outline, key: 'feat_whatsapp'),
  ];

  static int? _daysLeft(String? iso) {
    if (iso == null) return null;
    final end = DateTime.tryParse(iso);
    if (end == null) return null;
    final diff = end.toLocal().difference(DateTime.now());
    if (diff.isNegative) return 0;
    return (diff.inSeconds / 86400).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final status = user?.subscriptionStatus ?? 'trial';
    final isActive = status == 'active';
    final days = _daysLeft(user?.trialEndsAt);
    final trialExpired = status == 'expired' || status == 'cancelled';

    final String headline;
    if (isActive) {
      headline = AppStrings.tr('premium_active', lang);
    } else if (trialExpired) {
      headline = AppStrings.tr('trial_ended', lang);
    } else if (days == null) {
      headline = AppStrings.tr('free_trial', lang);
    } else if (days <= 0) {
      headline = AppStrings.tr('trial_last_day', lang);
    } else {
      headline = AppStrings.tr('trial_days_left', lang)
          .replaceFirst('{days}', '$days');
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.featureDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cosmicGold.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppColors.cosmicGold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(headline,
                    style: AppTextStyles.labelLarge(
                        color: AppColors.cosmicGoldLight)),
              ),
            ],
          ),
          if (!isActive) ...[
            const SizedBox(height: 14),
            Text(
              trialExpired
                  ? AppStrings.tr('premium_unlocks_now', lang)
                  : AppStrings.tr('premium_unlocks_after', lang)
                      .replaceFirst('{days}', '${days ?? 0}'),
              style: AppTextStyles.bodySmall(
                  color: AppColors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 12),
            for (final f in _features)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      trialExpired ? Icons.lock_outline : f.icon,
                      size: 18,
                      color: trialExpired
                          ? AppColors.white.withOpacity(0.55)
                          : AppColors.cosmicGoldLight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(AppStrings.tr(f.key, lang),
                          style: AppTextStyles.bodyMedium(
                              color: AppColors.white.withOpacity(0.9))),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cosmicGold,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppStrings.tr('upgrade_now', lang),
                    style: AppTextStyles.labelLarge(
                        color: AppColors.cosmicBase)),
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(AppStrings.tr('active_subscription', lang),
                style: AppTextStyles.bodySmall(
                    color: AppColors.white.withOpacity(0.7))),
          ],
        ],
      ),
    );
  }
}

Widget _SectionHeader(String title) => Text(
      title,
      style: AppTextStyles.sectionCaps(),
    );

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.cosmicGold),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AppTextStyles.bodyMedium())),
              Text(value,
                  style: AppTextStyles.labelMedium(
                      color: AppColors.cosmicTextDark)),
            ],
          ),
        ),
        if (!isLast)
          Container(
              height: 0.8,
              margin: const EdgeInsets.only(left: 44),
              color: AppColors.cardBorder),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.labelColor,
    this.isLast = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final Color? labelColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: labelColor ?? AppColors.cosmicTextDark),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.labelMedium(
                          color:
                              labelColor ?? AppColors.cosmicTextDark)),
                ),
                if (trailing != null)
                  Text(trailing!,
                      style: AppTextStyles.bodySmall(
                          color: AppColors.cosmicTextLight)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    size: 18, color: AppColors.cosmicTextLight),
              ],
            ),
          ),
        ),
        if (!isLast)
          Container(
              height: 0.8,
              margin: const EdgeInsets.only(left: 48),
              color: AppColors.cardBorder),
      ],
    );
  }
}
