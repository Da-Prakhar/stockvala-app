import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/app_button.dart';
import '../cubit/auth_cubit.dart';
import '../repository/auth_repository.dart';

class OtpScreen extends StatefulWidget {
  final String target; // email or phone
  const OtpScreen({super.key, required this.target});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  int _timerSeconds = 30;
  late Timer _timer;
  String _otp = '';
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds == 0) { t.cancel(); } else { setState(() => _timerSeconds--); }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else if (state is AuthPinRequired) {
          Navigator.pushReplacementNamed(context, AppRoutes.pinLogin);
        } else if (state is AuthError) {
          setState(() => _errorMsg = state.message);
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.bg100,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bg300,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                  ),
                ),
                const SizedBox(height: 40),

                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20)],
                  ),
                  child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 36),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 28),
                Text('Verify Your Email', style: AppTextStyles.displayMedium).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 8),
                RichText(text: TextSpan(style: AppTextStyles.bodyMedium, children: [
                  const TextSpan(text: 'We sent a 6-digit code to\n'),
                  TextSpan(text: widget.target, style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
                ])).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 32),

                // Error
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMsg!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  onChanged: (v) { _otp = v; setState(() => _errorMsg = null); },
                  onCompleted: (v) { _otp = v; _verify(); },
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 56, fieldWidth: 48,
                    activeFillColor: AppColors.bg400,
                    inactiveFillColor: AppColors.bg300,
                    selectedFillColor: AppColors.bg400,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.border,
                    selectedColor: AppColors.primary,
                  ),
                  enableActiveFill: true,
                  keyboardType: TextInputType.number,
                  textStyle: AppTextStyles.headingMedium,
                  cursorColor: AppColors.primary,
                  animationType: AnimationType.scale,
                  enabled: !loading,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 12),

                Center(
                  child: _timerSeconds > 0
                      ? Text('Resend code in 0:${_timerSeconds.toString().padLeft(2, '0')}', style: AppTextStyles.bodySmall)
                      : TextButton(
                          onPressed: loading ? null : _resend,
                          child: Text('Resend OTP', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                        ),
                ).animate().fadeIn(delay: 300.ms),

                const Spacer(),

                AppButton(
                  label: 'Verify & Continue',
                  isLoading: loading,
                  onPressed: (_otp.length == 6 && !loading) ? _verify : null,
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        );
      },
    );
  }

  void _verify() {
    if (_otp.length < 6) return;
    setState(() => _errorMsg = null);
    context.read<AuthCubit>().verifyOtp(target: widget.target, otp: _otp, purpose: 'register');
  }

  Future<void> _resend() async {
    setState(() { _timerSeconds = 30; _otpController.clear(); _otp = ''; });
    _startTimer();
    try {
      await AuthRepository.instance.resendOtp(target: widget.target);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('OTP resent successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Failed to resend OTP. Try again.');
    }
  }
}
