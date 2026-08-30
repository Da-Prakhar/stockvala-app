import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/vantage.dart';
import '../cubit/auth_cubit.dart';

/// V2 login — clean light layout: big title, Email tab, gray inputs, orange CTA.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
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

  InputDecoration _dec(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 16),
        filled: true,
        fillColor: AppColors.bg300,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

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
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 8),
                  Row(children: [
                    if (Navigator.canPop(context))
                      IconButton(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary, size: 22),
                      ),
                    const Spacer(),
                    const Icon(Icons.headset_mic_rounded,
                        color: AppColors.textPrimary, size: 24),
                  ]),
                  const SizedBox(height: 26),
                  Image.asset('assets/images/logo_light.png',
                      height: 42, alignment: Alignment.centerLeft),
                  const SizedBox(height: 26),
                  const Text('Log In',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 34),
                  const _EmailTab(),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                    decoration: _dec('Email'),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                    decoration: _dec('Password 8-16 characters',
                        suffix: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20, color: AppColors.textMuted),
                        )),
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Password too short' : null,
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.forgotPassword),
                    child: const Text('Forgot Password?',
                        style: TextStyle(fontSize: 14.5,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.dashed,
                            decorationColor: AppColors.textDisabled)),
                  ),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_errorMsg!,
                          style: const TextStyle(
                              fontSize: 13.5, color: AppColors.error)),
                    ),
                  ],
                  const SizedBox(height: 26),
                  VPill(label: 'Log In', loading: isLoading, onPressed: _submit),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, AppRoutes.register),
                      child: RichText(
                        text: const TextSpan(
                          text: 'New user? ',
                          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                          children: [
                            TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmailTab extends StatelessWidget {
  const _EmailTab();
  @override
  Widget build(BuildContext context) => const Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Email',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          SizedBox(height: 6),
          SizedBox(
            width: 30,
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.textPrimary),
              child: SizedBox(height: 3),
            ),
          ),
        ]),
      ]);
}
