import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../config/app_config.dart';

/// V2 onboarding — black stage, segmented progress, bold headline,
/// emoji hero art, orange Get Started pill.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardPage {
  final String headline;
  final String hero;      // big emoji composition
  final String heroSub;   // small floating emojis
  const _OnboardPage(this.headline, this.hero, this.heroSub);
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  Timer? _auto;

  static const _pages = [
    _OnboardPage('Your Trusted Broker — Chosen by Traders', '🪙', '💠  ₿  🍏'),
    _OnboardPage('Ultra-Fast Execution — Trade in Milliseconds', '⚡', '📈  💹  🔥'),
    _OnboardPage('Real-Time Global Markets — Act Before the Crowd', '🌐', '🕐  💵  📊'),
    _OnboardPage('All-in-One Financial Ecosystem — Capital Redefined', '📈', '🥇  🪙  💰'),
  ];

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _page = (_page + 1) % _pages.length);
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 18),
            // segmented progress
            Row(children: [
              for (var i = 0; i < _pages.length; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < _pages.length - 1 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.white : const Color(0xFF2A2A2E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(p.headline,
                  key: ValueKey(_page),
                  style: const TextStyle(fontSize: 28, height: 1.22,
                      fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const Spacer(),
            // hero art
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: Column(key: ValueKey('h$_page'), children: [
                  Container(
                    width: 210, height: 210,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        Color(0x33FF6118), Colors.transparent,
                      ]),
                    ),
                    alignment: Alignment.center,
                    child: Text(p.hero, style: const TextStyle(fontSize: 110)),
                  ),
                  const SizedBox(height: 12),
                  Text(p.heroSub,
                      style: const TextStyle(fontSize: 26, letterSpacing: 4)),
                ]),
              ),
            ),
            const Spacer(),
            Center(
              child: Text(AppConfig.appName.toUpperCase(),
                  style: const TextStyle(fontSize: 13, letterSpacing: 5,
                      fontWeight: FontWeight.w700, color: Color(0xFF6E6E73))),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: const Center(
                    child: Text('Get Started',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.register),
                child: const Text('Create Account',
                    style: TextStyle(fontSize: 15, color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}
