import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/storage/secure_storage.dart';

class SetPinScreen extends StatefulWidget {
  final bool isChange;
  const SetPinScreen({super.key, this.isChange = false});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  List<int> _pin = [];
  List<int> _confirmPin = [];
  bool _confirming = false;
  String? _error;

  void _onKey(int digit) {
    setState(() {
      _error = null;
      if (!_confirming) {
        if (_pin.length < 6) {
          _pin.add(digit);
          if (_pin.length == 6) {
            Future.delayed(300.ms, () => setState(() => _confirming = true));
          }
        }
      } else {
        if (_confirmPin.length < 6) {
          _confirmPin.add(digit);
          if (_confirmPin.length == 6) _validatePin();
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = null;
      if (_confirming) {
        if (_confirmPin.isNotEmpty) _confirmPin.removeLast();
      } else {
        if (_pin.isNotEmpty) _pin.removeLast();
      }
    });
  }

  Future<void> _validatePin() async {
    if (_pin.join() == _confirmPin.join()) {
      await SecureStorage().setString('app_pin', _pin.join());
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.biometricSetup);
    } else {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _confirmPin = [];
        Future.delayed(400.ms, () {
          if (mounted) setState(() { _pin = []; _confirming = false; });
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _confirming ? _confirmPin : _pin;
    return Scaffold(
      backgroundColor: AppColors.bg100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Icon
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20)],
                ),
                child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 36),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 32),

              AnimatedSwitcher(
                duration: 300.ms,
                child: Column(
                  key: ValueKey(_confirming),
                  children: [
                    Text(
                      _confirming ? 'Confirm PIN' : 'Set Your PIN',
                      style: AppTextStyles.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _confirming ? 'Enter the same PIN again' : 'Choose a 6-digit PIN for quick access',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < currentPin.length;
                  return AnimatedContainer(
                    duration: 200.ms,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: filled ? AppColors.primary : AppColors.textMuted,
                        width: 2,
                      ),
                      boxShadow: filled ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8)] : [],
                    ),
                  );
                }),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))
                    .animate().shakeX(),
              ],

              const SizedBox(height: 48),

              // Numpad
              _NumPad(onKey: _onKey, onDelete: _onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  List<int> _pin = [];
  String? _error;

  void _onKey(int digit) {
    if (_pin.length < 6) {
      setState(() { _pin.add(digit); _error = null; });
      if (_pin.length == 6) _verify();
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) setState(() => _pin.removeLast());
  }

  Future<void> _verify() async {
    final stored = await SecureStorage().getString('app_pin');
    // No PIN stored (web/fresh install) — go straight to home
    if (stored == null || stored.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    }
    if (stored == _pin.join()) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      setState(() { _pin = []; _error = 'Incorrect PIN. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 25)],
                ),
                child: const Icon(Icons.candlestick_chart_rounded, color: Colors.white, size: 40),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text('Enter PIN', style: AppTextStyles.displayMedium),
              const SizedBox(height: 8),
              Text('Welcome back! Enter your PIN to continue', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: 200.ms,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: filled ? AppColors.primary : AppColors.textMuted, width: 2),
                      boxShadow: filled ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8)] : [],
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)).animate().shakeX(),
              ],
              const SizedBox(height: 48),
              _NumPad(onKey: _onKey, onDelete: _onDelete),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                label: Text('Use Biometrics', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final ValueChanged<int> onKey;
  final VoidCallback onDelete;
  const _NumPad({required this.onKey, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.6,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ...List.generate(9, (i) => _Key(label: '${i + 1}', onTap: () => onKey(i + 1))),
        const SizedBox(),
        _Key(label: '0', onTap: () => onKey(0)),
        _DeleteKey(onTap: onDelete),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Key({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg300,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.headingMedium),
      ),
    );
  }
}

class _DeleteKey extends StatelessWidget {
  final VoidCallback onTap;
  const _DeleteKey({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg400,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.backspace_outlined, color: AppColors.textSecondary, size: 22),
      ),
    );
  }
}
