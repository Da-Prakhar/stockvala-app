import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardPage> _pages = [
    _OnboardPage(
      icon: Icons.candlestick_chart_rounded,
      gradient: AppColors.primaryGradient,
      title: 'Trade Global\nMarkets',
      subtitle: 'Access Forex, Commodities, Indices & Crypto.\nAll powered by MT5.',
    ),
    _OnboardPage(
      icon: Icons.people_alt_rounded,
      gradient: AppColors.accentGradient,
      title: 'Copy Expert\nTraders',
      subtitle: 'Follow top signal providers and auto-copy\ntheir trades in real-time.',
    ),
    _OnboardPage(
      icon: Icons.account_balance_rounded,
      gradient: AppColors.goldGradient,
      title: 'Invest in\nMAM & PAMM',
      subtitle: 'Let professionals manage your money and\nearn returns while you sleep.',
    ),
    _OnboardPage(
      icon: Icons.shield_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      ),
      title: 'Secure &\nCompliant',
      subtitle: 'Face ID, PIN lock, 2FA, KYC-verified accounts.\nYour funds are always protected.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardPageView(page: _pages[i]),
          ),
          Positioned(
            top: 56,
            right: 24,
            child: _currentPage < _pages.length - 1
                ? TextButton(
                    onPressed: _finish,
                    child: Text('Skip', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMuted)),
                  )
                : const SizedBox(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.bg100.withOpacity(0.98)],
                ),
              ),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: 300.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? AppColors.primary : AppColors.textMuted,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_currentPage == _pages.length - 1) ...[
                    AppButton(label: 'Get Started', onPressed: _finish),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'I already have an account',
                      variant: ButtonVariant.ghost,
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                    ),
                  ] else
                    AppButton(
                      label: 'Next',
                      onPressed: () => _controller.nextPage(
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                      ),
                      suffixIcon: Icons.arrow_forward_rounded,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    await SecureStorage().setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.register);
  }
}

class _OnboardPageView extends StatelessWidget {
  final _OnboardPage page;
  const _OnboardPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 100, 32, 220),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: page.gradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: (page.gradient as LinearGradient).colors.first.withOpacity(0.35),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(page.icon, color: Colors.white, size: 60),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String subtitle;
  const _OnboardPage({required this.icon, required this.gradient, required this.title, required this.subtitle});
}
