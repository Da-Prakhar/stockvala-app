import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/widgets/app_button.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final _auth = LocalAuthentication();
  bool _isLoading = false;
  bool _faceIdAvailable = false;
  bool _fingerprintAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      setState(() {
        _faceIdAvailable = biometrics.contains(BiometricType.face);
        _fingerprintAvailable = biometrics.contains(BiometricType.fingerprint) ||
            biometrics.contains(BiometricType.strong);
      });
    } catch (_) {}
  }

  Future<void> _enableBiometric() async {
    setState(() => _isLoading = true);
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to enable biometric login',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (authenticated) {
        await SecureStorage().setBool('biometric_enabled', true);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.kycStart);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric setup failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Face ID / Fingerprint icon with glow
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.primary.withOpacity(0.2), Colors.transparent],
                      ),
                    ),
                  ),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 30)],
                    ),
                    child: Icon(
                      _faceIdAvailable ? Icons.face_unlock_outlined : Icons.fingerprint_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ],
              ).animate().scale(duration: 700.ms, curve: Curves.elasticOut),

              const SizedBox(height: 40),

              Text(
                _faceIdAvailable ? 'Enable Face ID' : 'Enable Fingerprint',
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 16),

              Text(
                'Use ${_faceIdAvailable ? 'Face ID' : 'fingerprint'} for quick, secure login.\nYour biometric data never leaves your device.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 48),

              // Security features
              _SecurityFeature(icon: Icons.shield_outlined, text: 'Military-grade encryption').animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),
              _SecurityFeature(icon: Icons.devices_rounded, text: 'Device-bound authentication').animate().fadeIn(delay: 450.ms),
              const SizedBox(height: 16),
              _SecurityFeature(icon: Icons.lock_clock_outlined, text: 'Auto-lock after inactivity').animate().fadeIn(delay: 500.ms),

              const Spacer(),

              AppButton(
                label: _faceIdAvailable ? 'Enable Face ID' : 'Enable Fingerprint',
                isLoading: _isLoading,
                onPressed: _enableBiometric,
                prefixIcon: _faceIdAvailable ? Icons.face_unlock_outlined : Icons.fingerprint_rounded,
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 12),

              AppButton(
                label: 'Skip for now',
                variant: ButtonVariant.ghost,
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.kycStart),
              ).animate().fadeIn(delay: 650.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityFeature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SecurityFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(text, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}
