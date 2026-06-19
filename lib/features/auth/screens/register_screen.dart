import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../cubit/auth_cubit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _phone = '';
  bool _agreed = false;
  String? _errorMsg;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpRequired) {
          Navigator.pushNamed(context, AppRoutes.otpVerify, arguments: state.target);
        } else if (state is AuthError) {
          setState(() => _errorMsg = state.message);
        } else if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.bg100,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 32),
                    Text('Create Account', style: AppTextStyles.displayMedium)
                        .animate().fadeIn().slideX(begin: -0.2, end: 0),
                    const SizedBox(height: 8),
                    Text('Start your trading journey today', style: AppTextStyles.bodyMedium)
                        .animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 24),

                    // Error banner
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
                          GestureDetector(
                            onTap: () { setState(() => _errorMsg = null); context.read<AuthCubit>().clearError(); },
                            child: const Icon(Icons.close, color: AppColors.error, size: 18),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(children: [
                      Expanded(child: AppInput(
                        label: 'First Name', hint: 'John', controller: _firstNameCtrl,
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted, size: 20),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: AppInput(
                        label: 'Last Name', hint: 'Doe', controller: _lastNameCtrl,
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted, size: 20),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      )),
                    ]).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 20),

                    AppInput(
                      label: 'Email Address', hint: 'john@example.com', controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
                      validator: (v) {
                        if (v!.isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ).animate().fadeIn(delay: 175.ms),

                    const SizedBox(height: 20),

                    AppInput(
                      label: 'Password', hint: '••••••••', controller: _passCtrl,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
                      validator: (v) {
                        if (v!.isEmpty) return 'Required';
                        if (v.length < 8) return 'Min 8 characters';
                        return null;
                      },
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 20),

                    Text('Phone Number', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bg500,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IntlPhoneField(
                        decoration: const InputDecoration(
                          hintText: 'Phone number',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        initialCountryCode: 'IN',
                        onChanged: (phone) => _phone = phone.completeNumber,
                        style: AppTextStyles.bodyLarge,
                        dropdownTextStyle: AppTextStyles.bodyLarge,
                        dropdownIcon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                        flagsButtonPadding: const EdgeInsets.only(left: 12),
                      ),
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () => setState(() => _agreed = !_agreed),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        AnimatedContainer(
                          duration: 200.ms, width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: _agreed ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _agreed ? AppColors.primary : AppColors.textMuted, width: 1.5),
                          ),
                          child: _agreed ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: RichText(text: TextSpan(style: AppTextStyles.bodySmall, children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(text: 'Terms of Service', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                          const TextSpan(text: ' and '),
                          TextSpan(text: 'Privacy Policy', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                        ]))),
                      ]),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 32),

                    AppButton(
                      label: 'Create Account',
                      isLoading: loading,
                      onPressed: loading ? null : _submit,
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 32),

                    Center(child: TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                      child: RichText(text: TextSpan(style: AppTextStyles.bodyMedium, children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(text: 'Sign In', style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ])),
                    )),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please agree to the terms'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _errorMsg = null);
    context.read<AuthCubit>().register(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phone.isNotEmpty ? _phone : null,
    );
  }
}
