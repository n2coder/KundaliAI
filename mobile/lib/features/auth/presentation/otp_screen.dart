import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/lang_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cosmic_scaffold.dart';

/// OTP verification. Verifies with Firebase then exchanges for backend JWT.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, required this.verificationId});
  final String phone;
  final String verificationId;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _streamCtrl = StreamController<ErrorAnimationType>();
  String _otp = '';
  bool _loading = false;
  String? _error;
  int _countdown = 25;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamCtrl.close();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 25);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) {
        t.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _verify() async {
    if (_otp.length < 6) {
      _streamCtrl.add(ErrorAnimationType.shake);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    // Web preview bypass — simulate success so UI flow can be tested
    if (kIsWeb || widget.verificationId == 'web-preview') {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/birth-details');
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otp,
      );
      final uc =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseToken = await uc.user?.getIdToken();
      if (firebaseToken == null) throw Exception('Failed to get token');

      await ref.read(authProvider.notifier).signIn(firebaseToken);

      final authState = ref.read(authProvider);
      authState.whenData((user) {
        if (user != null && mounted) {
          context.go(user.hasBirthChart ? '/home' : '/birth-details');
        }
      });
      authState.whenOrNull(
        error: (e, _) {
          if (mounted) {
            setState(() {
              _loading = false;
              _error = e.toString();
            });
          }
        },
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message ?? 'Invalid OTP';
      });
      _streamCtrl.add(ErrorAnimationType.shake);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    return CosmicScaffold(
      style: CosmicStyle.warm,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 28, right: 28),
            child: Column(
              children: [
                const CosmicStarBadge(size: 52),
                const SizedBox(height: 20),
                Text(
                  AppStrings.tr('verify_number', lang),
                  style: AppTextStyles.displayMedium(
                      color: AppColors.cosmicGoldGlow),
                ),
                const SizedBox(height: 8),
                const CosmicDivider(),
                const SizedBox(height: 8),
                Text(
                  "${AppStrings.tr('we_sent_otp', lang)}\n${widget.phone}",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(
                      color: AppColors.cosmicGoldLight),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(child: _EmptyPhoneMockup()),
          ),
          _OtpCard(
            streamCtrl: _streamCtrl,
            otp: _otp,
            loading: _loading,
            error: _error,
            countdown: _countdown,
            onChanged: (v) => setState(() => _otp = v),
            onCompleted: (_) => _verify(),
            onVerify: _verify,
            onResend: _startCountdown,
          ),
        ],
      ),
    );
  }
}

class _EmptyPhoneMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 200,
      child: CustomPaint(painter: _EmptyPhonePainter()),
    );
  }
}

class _EmptyPhonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, cy),
              width: size.width,
              height: size.height),
          const Radius.circular(20)),
      Paint()..color = const Color(0xFF180E0A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy),
            width: size.width - 16,
            height: size.height - 28),
        const Radius.circular(14),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC47858), Color(0xFFD4A07A), Color(0xFFE8C090)],
        ).createShader(Rect.fromCenter(
            center: Offset(cx, cy),
            width: size.width - 16,
            height: size.height - 28)),
    );
    _planet(canvas, Offset(-12, size.height * 0.25), 22, ring: true);
    _planet(canvas, Offset(size.width + 10, size.height * 0.2), 16,
        ring: false);
    _planet(canvas, Offset(size.width + 6, size.height * 0.65), 12,
        ring: false);
  }

  void _planet(Canvas canvas, Offset c, double r, {required bool ring}) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFC09070));
    if (ring) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: r * 3, height: r * 0.7),
        Paint()
          ..color = AppColors.cosmicGold.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OtpCard extends ConsumerWidget {
  const _OtpCard({
    required this.streamCtrl,
    required this.otp,
    required this.loading,
    required this.countdown,
    required this.onChanged,
    required this.onCompleted,
    required this.onVerify,
    required this.onResend,
    this.error,
  });

  final StreamController<ErrorAnimationType> streamCtrl;
  final String otp;
  final bool loading;
  final int countdown;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.tr('enter_6_otp', lang),
              style:
                  AppTextStyles.labelLarge(color: AppColors.cosmicTextMid)),
          const SizedBox(height: 16),
          PinCodeTextField(
            appContext: context,
            length: 6,
            errorAnimationController: streamCtrl,
            onChanged: onChanged,
            onCompleted: onCompleted,
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(10),
              fieldHeight: 52,
              fieldWidth: 44,
              activeFillColor: AppColors.cardBgAlt,
              inactiveFillColor: AppColors.cardBgAlt,
              selectedFillColor: AppColors.cardBgAlt,
              activeColor: AppColors.cosmicGold,
              inactiveColor: AppColors.cardBorder,
              selectedColor: AppColors.cosmicGold,
              activeBorderWidth: 1.5,
            ),
            enableActiveFill: true,
            textStyle: AppTextStyles.headingMedium(),
            cursorColor: AppColors.cosmicGold,
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(error!,
                style: AppTextStyles.bodySmall(color: AppColors.error),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(AppStrings.tr('didnt_receive_code', lang),
                  style: AppTextStyles.bodySmall()),
              GestureDetector(
                onTap: countdown == 0 ? onResend : null,
                child: Text(
                  AppStrings.tr('resend_otp', lang),
                  style: AppTextStyles.bodySmall(
                    color: countdown == 0
                        ? AppColors.cosmicGold
                        : AppColors.cosmicTextLight,
                  ),
                ),
              ),
              if (countdown > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '(00:${countdown.toString().padLeft(2, '0')})',
                  style: AppTextStyles.bodySmall(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: loading ? null : onVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.btnBg,
                foregroundColor: AppColors.btnText,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              child: loading
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
                        Text(AppStrings.tr('verify_continue', lang),
                            style: AppTextStyles.buttonText(
                                color: AppColors.cosmicGoldLight)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward,
                            color: AppColors.cosmicGoldLight, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBgAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline,
                    size: 20, color: AppColors.cosmicTextLight),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySmall(),
                      children: [
                        const TextSpan(
                            text:
                                'Your privacy and security are our top priority. We '),
                        TextSpan(
                          text: 'never',
                          style: AppTextStyles.bodySmall(
                              color: AppColors.cosmicGold),
                        ),
                        const TextSpan(text: ' share your information.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
