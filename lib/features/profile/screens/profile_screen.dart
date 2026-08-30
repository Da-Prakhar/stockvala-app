import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/vantage.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/repository/auth_repository.dart';
import '../../finance/repository/finance_repository.dart';
import '../../funds/screens/funds_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../wallet_verification/screens/wallet_verification_screen.dart';
import '../../../core/network/api_exception.dart';

/// V2 profile — avatar header with UID + status chips, grouped row cards,
/// dark Log Out pill.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _kycStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadKyc();
  }

  Future<void> _loadKyc() async {
    try {
      final k = await FinanceRepository.instance.getKycStatus();
      if (mounted) setState(() => _kycStatus = k.status);
    } catch (_) {}
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _changePassword() async {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Change Log In Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: curCtrl, obscureText: true,
              decoration: _dec('Current password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newCtrl, obscureText: true,
              decoration: _dec('New password (min 8 characters)'),
            ),
            const SizedBox(height: 18),
            VPill(label: 'Update Password', onPressed: () => Navigator.pop(ctx, true)),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    if (newCtrl.text.length < 8) {
      _snack('New password must be at least 8 characters', error: true);
      return;
    }
    try {
      await AuthRepository.instance.changePassword(
          current: curCtrl.text, newPass: newCtrl.text);
      _snack('Password updated ✓');
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Could not update password', error: true);
    }
  }

  static InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        filled: true,
        fillColor: AppColors.bg300,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

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
              Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login, (r) => false);
            },
            child: const Text('Log Out',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final name = user == null
        ? '—'
        : '${user.firstName} ${user.lastName}'.trim();
    final verified = _kycStatus == 'verified';

    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: AppBar(
        backgroundColor: AppColors.bg100,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.headset_mic_rounded, size: 23),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                  color: AppColors.bg300, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('🦏', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                GestureDetector(
                  onTap: () {
                    if (user != null) {
                      Clipboard.setData(ClipboardData(text: user.id));
                      _snack('UID copied');
                    }
                  },
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('UID : ${user?.id ?? '—'}',
                        style: const TextStyle(fontSize: 13,
                            color: AppColors.textMuted)),
                    const SizedBox(width: 4),
                    const Icon(Icons.copy_rounded, size: 13,
                        color: AppColors.textMuted),
                  ]),
                ),
                const SizedBox(height: 7),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: verified ? AppColors.successBg : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(verified ? '✓ Verified' : 'KYC ${_kycStatus.replaceAll('-', ' ')}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: verified ? AppColors.success : AppColors.warning)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(user?.tier ?? 'Standard',
                        style: const TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 22),

          // ── Account group ─────────────────────────────────────────────
          _Group(rows: [
            _RowSpec('🪪', 'KYC Verification',
                trailing: verified ? '✓' : null,
                onTap: () => Navigator.pushNamed(context, AppRoutes.kycStart)),
            _RowSpec('👛', 'Payout Wallets',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const WalletVerificationScreen()))),
            _RowSpec('🧾', 'Transaction History',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => Scaffold(
                          backgroundColor: AppColors.bg100,
                          appBar: AppBar(
                            backgroundColor: AppColors.bg100,
                            foregroundColor: AppColors.textPrimary,
                            elevation: 0,
                            title: const Text('Funds',
                                style: TextStyle(fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                          ),
                          body: const FundsScreen(),
                        )))),
          ]),
          const SizedBox(height: 14),

          // ── Security group ────────────────────────────────────────────
          _Group(rows: [
            _RowSpec('🔒', 'Change Log In Password', onTap: _changePassword),
            _RowSpec('🔢', 'Trading PIN',
                onTap: () => Navigator.pushNamed(context, AppRoutes.setPin)),
            _RowSpec('💬', 'Messages',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const NotificationsScreen()))),
          ]),
          const SizedBox(height: 26),

          VPill(label: 'Log Out', dark: true, onPressed: _logout),
          const SizedBox(height: 14),
          Center(
            child: Text('${user?.email ?? ''}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _RowSpec {
  final String emoji;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  const _RowSpec(this.emoji, this.label, {this.trailing, required this.onTap});
}

class _Group extends StatelessWidget {
  final List<_RowSpec> rows;
  const _Group({required this.rows});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.bg200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            InkWell(
              onTap: rows[i].onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(children: [
                  Text(rows[i].emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(rows[i].label,
                        style: const TextStyle(fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ),
                  if (rows[i].trailing != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(rows[i].trailing!,
                          style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success)),
                    ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.textMuted),
                ]),
              ),
            ),
            if (i < rows.length - 1)
              const Divider(height: 1, indent: 46, color: AppColors.borderLight),
          ],
        ]),
      );
}
