import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/vantage.dart';
import '../../auth/cubit/auth_cubit.dart';

/// V2 settings — plain rows with values/chevrons, dark Log Out pill,
/// Delete Account as quiet text.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '—';
  bool _biometric = false;
  bool _biometricAvailable = false;
  String _cacheSize = '—';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait<dynamic>([
      PackageInfo.fromPlatform(),
      BiometricService.isAvailable(),
      SecureStorage().getString('biometric_enabled'),
      SharedPreferences.getInstance(),
    ]);
    final info = results[0] as PackageInfo;
    final prefs = results[3] as SharedPreferences;
    // Rough cache footprint: the persisted price snapshot + spark/candle entries.
    final priceBytes = (prefs.getString('sv_price_cache_v1') ?? '').length;
    if (!mounted) return;
    setState(() {
      _version = 'V${info.version} (${info.buildNumber})';
      _biometricAvailable = results[1] as bool;
      _biometric = (results[2] as String?) == 'true';
      _cacheSize = priceBytes < 1024
          ? '${priceBytes}B'
          : '${(priceBytes / 1024).toStringAsFixed(1)}K';
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _toggleBiometric(bool on) async {
    if (on) {
      final ok = await BiometricService.authenticate(
          reason: 'Confirm to enable biometric login');
      if (!ok) return;
    }
    await SecureStorage()
        .setString('biometric_enabled', on ? 'true' : 'false');
    if (mounted) setState(() => _biometric = on);
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sv_price_cache_v1');
    imageCache.clear();
    imageCache.clearLiveImages();
    if (!mounted) return;
    setState(() => _cacheSize = '0B');
    _snack('Cache cleared');
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
            },
            child: const Text('Log Out',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: const Text(
            'Account deletion is handled by the broker for regulatory reasons. '
            'Contact support and your account and data will be removed after '
            'open balances are settled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: AppBar(
        backgroundColor: AppColors.bg100,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: const Text('Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
        children: [
          const _Row(label: 'Language', value: 'English (US)'),
          const _Row(label: 'Theme', value: 'Light Theme'),
          if (_biometricAvailable)
            _Row(
              label: 'Biometric Log In',
              trailing: Switch(
                value: _biometric,
                
                activeTrackColor: AppColors.ink,
                onChanged: _toggleBiometric,
              ),
            ),
          _Row(label: 'Trading PIN', chevron: true,
              onTap: () => Navigator.pushNamed(context, AppRoutes.setPin)),
          _Row(label: 'Clear Cache', value: _cacheSize, onTap: _clearCache),
          _Row(label: 'Version', value: _version),
          const SizedBox(height: 40),
          VPill(label: 'Log Out', dark: true, onPressed: _logout),
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: _deleteAccount,
              child: const Text('Delete Account',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String? value;
  final bool chevron;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _Row({required this.label, this.value, this.chevron = false,
      this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
            if (value != null)
              Text(value!,
                  style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
            if (trailing != null) trailing!,
            if (chevron || onTap != null && trailing == null && value == null)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textMuted),
              ),
          ]),
        ),
      );
}
