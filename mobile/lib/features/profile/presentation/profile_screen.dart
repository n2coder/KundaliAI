import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

/// User profile — shows real user data from auth state.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;

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
                            child: Text('My Profile',
                                style: AppTextStyles.headingMedium()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppColors.cosmicTextDark, size: 20),
                          onPressed: () {},
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
                                    color: AppColors.cosmicTextDark),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.phone ?? '',
                                style: AppTextStyles.bodySmall(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Subscription badge
                        _SubscriptionBadge(user: user),
                        const SizedBox(height: 20),

                        // Birth details
                        _SectionHeader('BIRTH DETAILS'),
                        const SizedBox(height: 10),
                        CosmicCard(
                          child: Column(
                            children: [
                              _DetailRow(
                                icon: Icons.calendar_today_outlined,
                                label: 'Date of Birth',
                                value: user?.dob ?? '—',
                              ),
                              _DetailRow(
                                icon: Icons.access_time,
                                label: 'Time of Birth',
                                value: user?.tob ?? '—',
                              ),
                              _DetailRow(
                                icon: Icons.location_on_outlined,
                                label: 'Place of Birth',
                                value: user?.birthPlace ?? '—',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Settings
                        _SectionHeader('SETTINGS'),
                        const SizedBox(height: 10),
                        CosmicCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _SettingsTile(
                                icon: Icons.notifications_outlined,
                                label: 'Notifications',
                                onTap: () {},
                              ),
                              _SettingsTile(
                                icon: Icons.language,
                                label: 'Language',
                                trailing:
                                    user?.language == 'hi' ? 'Hindi' : 'English',
                                onTap: () {},
                              ),
                              _SettingsTile(
                                icon: Icons.privacy_tip_outlined,
                                label: 'Privacy Policy',
                                onTap: () {},
                              ),
                              _SettingsTile(
                                icon: Icons.help_outline,
                                label: 'Help & Support',
                                onTap: () {},
                              ),
                              _SettingsTile(
                                icon: Icons.logout,
                                label: 'Sign Out',
                                labelColor: AppColors.error,
                                onTap: () async {
                                  await ref.read(authProvider.notifier).signOut();
                                  if (context.mounted) context.go('/');
                                },
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Text('KundliAI v1.0.0',
                              style: AppTextStyles.bodySmall(
                                  color: AppColors.cosmicTextLight)),
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
}

class _SubscriptionBadge extends StatelessWidget {
  const _SubscriptionBadge({this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final status = user?.subscriptionStatus ?? 'trial';
    final isActive = status == 'active';
    final label = isActive
        ? 'Premium Active'
        : status == 'trial'
            ? 'Free Trial'
            : 'Subscription Expired';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.featureDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cosmicGold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome,
              color: AppColors.cosmicGold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.labelLarge(
                        color: AppColors.cosmicGoldLight)),
                const SizedBox(height: 2),
                Text(
                  isActive
                      ? 'Active subscription'
                      : 'Upgrade to Premium at ₹30/month',
                  style: AppTextStyles.bodySmall(
                      color: AppColors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          if (!isActive)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cosmicGold,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('UPGRADE',
                  style: AppTextStyles.sectionCaps(
                      color: AppColors.cosmicBase)),
            ),
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
