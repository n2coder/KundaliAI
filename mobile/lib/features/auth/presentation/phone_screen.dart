import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final number = _controller.text.trim();
    if (number.length < 10) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    // Firebase verifyPhoneNumber is mobile-only; bypass for web preview
    if (kIsWeb) {
      setState(() => _loading = false);
      context.go(
        '/otp?phone=${Uri.encodeComponent('+91$number')}&vid=web-preview',
      );
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$number',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final uc = await FirebaseAuth.instance.signInWithCredential(credential);
          final token = await uc.user?.getIdToken();
          if (token == null || !mounted) return;
          await ref.read(authProvider.notifier).signIn(token);
          final user = ref.read(authProvider).valueOrNull;
          if (mounted) {
            context.go(user?.hasBirthChart == true ? '/home' : '/birth-details');
          }
        } catch (_) {
          if (mounted) setState(() => _loading = false);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = e.message ?? 'Verification failed';
          });
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() => _loading = false);
          context.go(
            '/otp?phone=${Uri.encodeComponent('+91$number')}&vid=${Uri.encodeComponent(verificationId)}',
          );
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen background image
          Image.asset('assets/images/phone_bg.jpeg', fit: BoxFit.cover),

          // Form overlay — floats in the lower portion
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Floating form card — rounded all corners
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Mobile Number', style: AppTextStyles.labelLarge()),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Country selector
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.cardBgAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                const Text('🇮🇳',
                                    style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text('+91',
                                    style: AppTextStyles.labelLarge()),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: AppColors.cosmicTextLight),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              maxLength: 10,
                              style: AppTextStyles.bodyLarge(),
                              decoration: InputDecoration(
                                hintText: 'Enter your mobile number',
                                hintStyle: AppTextStyles.bodyMedium(
                                    color: AppColors.cosmicTextLight),
                                counterText: '',
                                filled: true,
                                fillColor: AppColors.cardBgAlt,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.cosmicGold, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 6),
                        Text(_error!,
                            style: AppTextStyles.bodySmall(
                                color: AppColors.error)),
                      ],
                      const SizedBox(height: 14),
                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.btnBg,
                            foregroundColor: AppColors.btnText,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                          ),
                          child: _loading
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
                                    Text('Continue',
                                        style: AppTextStyles.buttonText(
                                            color: AppColors.cosmicGoldLight)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward,
                                        color: AppColors.cosmicGoldLight,
                                        size: 18),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Privacy note inside card
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield_outlined,
                              size: 13, color: AppColors.cosmicTextLight),
                          const SizedBox(width: 5),
                          Text('Your number is safe with us. ',
                              style: AppTextStyles.bodySmall()),
                          Text('We never share your data.',
                              style: AppTextStyles.bodySmall(
                                  color: AppColors.cosmicGold)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Secured by — outside the card, at very bottom
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 12, color: AppColors.cosmicGold),
                    const SizedBox(width: 5),
                    Text('Secured by 256-bit encryption',
                        style: AppTextStyles.bodySmall(
                            color: AppColors.cosmicGold)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
