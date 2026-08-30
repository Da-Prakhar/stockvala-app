import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../config/app_config.dart';
import '../cubit/auth_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _animDone = false;
  bool _authDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _animDone = true);
      _maybeNavigate();
    });
  }

  void _maybeNavigate() {
    if (!_animDone || !_authDone) return;
    final state = context.read<AuthCubit>().state;
    if (!mounted) return;
    if (state is AuthAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (state is AuthPinRequired) {
      Navigator.pushReplacementNamed(context, AppRoutes.pinLogin);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) return;
        _authDone = true;
        _maybeNavigate();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg100,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: Stack(
            children: [
              Positioned(
                top: -100, right: -100,
                child: Container(
                  width: 350, height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.15), Colors.transparent]),
                  ),
                ),
              ).animate().fadeIn(duration: 1200.ms),
              Positioned(
                bottom: -80, left: -80,
                child: Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [AppColors.accent.withOpacity(0.12), Colors.transparent]),
                  ),
                ),
              ).animate().fadeIn(duration: 1200.ms, delay: 300.ms),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 30, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.candlestick_chart_rounded, color: Colors.white, size: 46),
                    ).animate().scale(duration: 700.ms, curve: Curves.elasticOut).fadeIn(duration: 500.ms),
                    const SizedBox(height: 28),
                    Image.asset('assets/images/logo_light.png', height: 54)
                        .animate().fadeIn(delay: 300.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 8),
                    Text(AppConfig.brand.tagline, style: AppTextStyles.bodyMedium.copyWith(letterSpacing: 1.5))
                        .animate().fadeIn(delay: 700.ms, duration: 600.ms),
                  ],
                ),
              ),
              Positioned(
                bottom: 60, left: 0, right: 0,
                child: Column(children: [
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        backgroundColor: AppColors.bg400,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 3,
                      ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms),
                  const SizedBox(height: 16),
                  Text('Powered by MT5', style: AppTextStyles.caption.copyWith(letterSpacing: 1))
                      .animate().fadeIn(delay: 1200.ms),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
