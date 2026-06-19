import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/biometric_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../repository/auth_repository.dart';
import '../cubit/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _biometricLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
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
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.bg100,
          body: Stack(children: [
            // Decorative glow
            Positioned(
              top: -120, left: -60,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.1), Colors.transparent
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: -80, right: -40,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primaryLight.withValues(alpha: 0.08), Colors.transparent
                  ]),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // Logo
                      Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.candlestick_chart_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Text('StockVala', style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary)),
                      ]).animate().fadeIn(),

                      const SizedBox(height: 48),
                      Text('Welcome Back', style: AppTextStyles.displayMedium).animate().fadeIn(delay: 80.ms),
                      const SizedBox(height: 6),
                      Text('Sign in to continue trading', style: AppTextStyles.bodyMedium).animate().fadeIn(delay: 120.ms),

                      // Error banner
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMsg!, style: const TextStyle(
                                fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w500))),
                            GestureDetector(
                              onTap: () {
                                setState(() => _errorMsg = null);
                                context.read<AuthCubit>().clearError();
                              },
                              child: const Icon(Icons.close_rounded, color: AppColors.error, size: 16),
                            ),
                          ]),
                        ).animate().fadeIn().shakeX(),
                      ],

                      const SizedBox(height: 32),

                      AppInput(
                        label: 'Email Address',
                        hint: 'john@example.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ).animate().fadeIn(delay: 160.ms),

                      const SizedBox(height: 16),

                      AppInput(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passCtrl,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
                        validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                        onFieldSubmitted: (_) => _submit(),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                          child: Text('Forgot Password?',
                              style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                        ),
                      ).animate().fadeIn(delay: 240.ms),

                      const SizedBox(height: 20),

                      AppButton(
                        label: 'Sign In',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _submit,
                      ).animate().fadeIn(delay: 280.ms),

                      const SizedBox(height: 24),

                      // Biometric button
                      Center(
                        child: Column(children: [
                          GestureDetector(
                            onTap: _biometricLogin,
                            child: AnimatedContainer(
                              duration: 200.ms,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _biometricLoading ? AppColors.primaryLighter : AppColors.bg300,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: _biometricLoading
                                  ? const SizedBox(
                                      width: 32, height: 32,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                                    )
                                  : const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 32),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('Use Biometrics', style: AppTextStyles.bodySmall),
                        ]),
                      ).animate().fadeIn(delay: 320.ms),

                      const SizedBox(height: 40),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.register),
                          child: RichText(
                            text: TextSpan(style: AppTextStyles.bodyMedium, children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Sign Up',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary, fontWeight: FontWeight.w700),
                              ),
                            ]),
                          ),
                        ),
                      ).animate().fadeIn(delay: 360.ms),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _biometricLogin() async {
    final hasSaved = await AuthRepository.instance.hasSavedSession();
    if (!hasSaved) {
      setState(() => _errorMsg = 'No saved session. Please log in with credentials first.');
      return;
    }
    setState(() => _biometricLoading = true);
    try {
      final authed = await BiometricService.authenticate();
      if (!mounted) return;
      if (authed) {
        Navigator.pushReplacementNamed(context, AppRoutes.pinLogin);
      } else {
        setState(() { _biometricLoading = false; _errorMsg = 'Biometric authentication failed.'; });
      }
    } catch (_) {
      if (mounted) setState(() => _biometricLoading = false);
    }
  }
}
