import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../finance/repository/finance_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _ProfileHeader()),
        SliverToBoxAdapter(child: _AccountCard()),
        SliverToBoxAdapter(child: _MenuSection('Account', [
          _MI(Icons.person_outline_rounded,     'Personal Information', AppColors.primary,  () => _push(context, const _PersonalInfoPage())),
          _MI(Icons.verified_user_outlined,      'KYC Verification',     AppColors.success,  () => _push(context, const _KYCStatusPage())),
          _MI(Icons.receipt_long_outlined,       'Transaction History',  AppColors.accent,   () => _push(context, const _TransactionHistoryPage())),
          _MI(Icons.description_outlined,        'Documents',           AppColors.gold,     () => _push(context, const _DocumentsPage())),
        ])),
        SliverToBoxAdapter(child: _MenuSection('Security', [
          _MI(Icons.lock_outline_rounded,        'Change PIN',          AppColors.primary,  () => _push(context, const _ChangePinPage())),
          _MI(Icons.fingerprint_rounded,         'Biometric Settings',  AppColors.accent,   () => _push(context, const _BiometricPage())),
          _MI(Icons.security_rounded,            'Two-Factor Auth',     AppColors.success,  () => _push(context, const _TwoFAPage())),
          _MI(Icons.devices_outlined,            'Trusted Devices',     AppColors.warning,  () => _push(context, const _DevicesPage())),
        ])),
        SliverToBoxAdapter(child: _MenuSection('Trading', [
          _MI(Icons.tune_rounded,                'Account Settings',    AppColors.primary,  () => _push(context, const _AccountSettingsPage())),
          _MI(Icons.notifications_outlined,      'Notifications',       AppColors.accent,   () => _push(context, const _NotificationsSettingsPage())),
          _MI(Icons.bar_chart_rounded,           'Trading Reports',     AppColors.gold,     () => _push(context, const _TradingReportsPage())),
        ])),
        SliverToBoxAdapter(child: _MenuSection('Support', [
          _MI(Icons.headset_mic_outlined,        'Live Chat Support',   AppColors.primary,  () => _push(context, const _SupportPage())),
          _MI(Icons.help_outline_rounded,        'FAQ',                 AppColors.accent,   () => _push(context, const _FaqPage())),
          _MI(Icons.info_outline_rounded,        'About StockVala',     AppColors.textMuted,() => _push(context, const _AboutPage())),
        ])),
        SliverToBoxAdapter(child: _LogoutButton()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
    );
  }

  void _push(BuildContext ctx, Widget page) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final displayName = user?.name.isNotEmpty == true ? user!.name : 'Trader';
    final email = user?.email ?? '';
    final initials = user?.initials ?? 'T';
    final kycVerified = user?.kycVerified ?? false;
    final tier = user?.tier ?? 'Standard';

    return Consumer<Mt5AccountStore>(
      builder: (_, store, __) {
        final acc = store.active;
        return Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: Column(children: [
            // ── Top row: avatar + name/email + edit ────────────────────
            Row(children: [
              Stack(children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                if (kycVerified)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 11),
                    ),
                  ),
              ]),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    kycVerified ? '$tier · Verified ✓' : '$tier Account',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ])),
              IconButton(
                onPressed: () => _push(context, const _PersonalInfoPage()),
                icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
              ),
            ]),

            const SizedBox(height: 12),

            // ── Active account selector row ─────────────────────────────
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: store,
                    child: const _AccountSwitcherSheet(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  // Active indicator dot
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: acc?.isReal == true ? AppColors.success : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Account ID
                  Expanded(child: acc == null
                    ? const Text('No account — tap to create',
                        style: TextStyle(color: Colors.white60, fontSize: 13))
                    : Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            'MT5 #${acc.login}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3),
                          ),
                          Text(
                            '${acc.server}  ·  ${acc.type}  ·  ${acc.isReal ? 'REAL' : 'DEMO'}',
                            style: const TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ]),
                        const SizedBox(width: 12),
                        // Balance chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$${_fmt(acc.balance)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ]),
                  ),

                  // Switch indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${store.accounts.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    ).animate().fadeIn();
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(2);

  void _push(BuildContext ctx, Widget page) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
}

// ── ACCOUNT CARD (reactive to active MT5 account) ────────────────────────────
class _AccountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<Mt5AccountStore>(
      builder: (_, store, __) {
        final acc = store.active;

        // Loading state
        if (store.isLoading) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bg200,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
              SizedBox(width: 12),
              Text('Loading MT5 accounts...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ]),
          );
        }

        // No accounts linked
        if (acc == null) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bg200,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.textMuted, size: 36),
              const SizedBox(height: 10),
              const Text('No MT5 account yet',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                'Create a live or demo account to start trading.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Create Account button
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ChangeNotifierProvider.value(
                      value: store,
                      child: const _AddAccountSheet(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('Create Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                // Refresh button
                GestureDetector(
                  onTap: () => store.loadAccounts(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.refresh_rounded, color: AppColors.primary, size: 14),
                      SizedBox(width: 6),
                      Text('Refresh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                    ]),
                  ),
                ),
              ]),
            ]),
          ).animate().fadeIn(delay: 100.ms);
        }
        final plPositive = acc.openPL >= 0;
        return GestureDetector(
          onTap: () => _openSwitcher(context, store),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bg200,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              // Top row: login + server + SWITCH button
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('#${acc.login}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: acc.isReal ? AppColors.successBg : AppColors.warningBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(acc.isReal ? 'REAL' : 'DEMO',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                          color: acc.isReal ? AppColors.success : AppColors.warning)),
                    ),
                  ]),
                  Text('${acc.server} · ${acc.type} · ${acc.leverage}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ])),
                GestureDetector(
                  onTap: () => _openSwitcher(context, store),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text('SWITCH (${store.accounts.length})',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              // Balance stats
              Row(children: [
                _BalItem('Balance',    '\$${_fmt(acc.balance)}',    AppColors.textPrimary),
                _BalItem('Equity',     '\$${_fmt(acc.equity)}',     AppColors.bullish),
                _BalItem('Open P/L',   '${plPositive ? '+' : ''}\$${_fmt(acc.openPL.abs())}',
                  plPositive ? AppColors.bullish : AppColors.bearish),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _BalItem('Margin',       '\$${_fmt(acc.margin)}',     AppColors.warning),
                _BalItem('Free Margin',  '\$${_fmt(acc.freeMargin)}', AppColors.success),
                _BalItem('Margin Lv.',   '${acc.marginLevel.toStringAsFixed(1)}%', AppColors.primary),
              ]),
            ]),
          ),
        ).animate().fadeIn(delay: 100.ms);
      },
    );
  }

  String _fmt(double v) => v >= 1000
      ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 2)}k'
      : v.toStringAsFixed(2);

  void _openSwitcher(BuildContext context, Mt5AccountStore store) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: store,
        child: const _AccountSwitcherSheet(),
      ),
    );
  }
}

class _BalItem extends StatelessWidget {
  final String l, v; final Color c;
  const _BalItem(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
    const SizedBox(height: 2),
    Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
  ]));
}

// ── ACCOUNT SWITCHER SHEET ────────────────────────────────────────────────────
class _AccountSwitcherSheet extends StatelessWidget {
  const _AccountSwitcherSheet();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Mt5AccountStore>();
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Trading Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('${store.accounts.length} accounts linked to your profile',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: store,
                    child: const _AddAccountSheet(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: AppColors.primary, size: 16),
                  SizedBox(width: 4),
                  Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Account list
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            itemCount: store.accounts.length,
            itemBuilder: (_, i) => _AccountTile(
              account: store.accounts[i],
              isActive: i == store.activeIndex,
              onTap: () {
                store.switchTo(i);
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              onDelete: store.accounts[i].isCustom
                  ? () => store.removeAccount(store.accounts[i].id)
                  : null,
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 20),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ChangeNotifierProvider.value(
                  value: store,
                  child: const _AddAccountSheet(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('Create New MT5 Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _AccountTile extends StatefulWidget {
  final Mt5Account account;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const _AccountTile({required this.account, required this.isActive, required this.onTap, this.onDelete});
  @override
  State<_AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<_AccountTile> {
  bool _showDelete = false;

  @override
  Widget build(BuildContext context) {
    final acc = widget.account;
    final plPos = acc.openPL >= 0;

    return GestureDetector(
      onLongPress: widget.onDelete != null ? () {
        setState(() => _showDelete = !_showDelete);
        HapticFeedback.mediumImpact();
      } : null,
      onTap: widget.isActive ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.isActive ? AppColors.primaryLighter : AppColors.bg200,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isActive ? AppColors.primary : AppColors.border,
            width: widget.isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(children: [
          // Status dot / check
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: widget.isActive ? AppColors.primary : AppColors.bg300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isActive ? Icons.check_rounded : Icons.account_circle_outlined,
              color: widget.isActive ? Colors.white : AppColors.textMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('#${acc.login}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                  color: widget.isActive ? AppColors.primary : AppColors.textPrimary)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: acc.isReal ? AppColors.successBg : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(acc.isReal ? 'REAL' : 'DEMO',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800,
                    color: acc.isReal ? AppColors.success : AppColors.warning)),
              ),
              if (acc.isCustom) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.bg400, borderRadius: BorderRadius.circular(3)),
                  child: const Text('CUSTOM', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text('${acc.server} · ${acc.type} · ${acc.leverage}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Row(children: [
              _MiniStat('Bal', '\$${_fmtLarge(acc.balance)}'),
              const SizedBox(width: 14),
              _MiniStat('Eq', '\$${_fmtLarge(acc.equity)}'),
              const SizedBox(width: 14),
              _MiniStat('P/L',
                '${plPos ? '+' : '-'}\$${acc.openPL.abs().toStringAsFixed(0)}',
                color: plPos ? AppColors.bullish : AppColors.bearish),
            ]),
          ])),

          // Delete button (custom accounts only)
          if (_showDelete && widget.onDelete != null)
            GestureDetector(
              onTap: () { widget.onDelete!(); },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
              ),
            )
          else if (widget.isActive)
            const SizedBox.shrink()
          else
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        ]),
      ),
    );
  }

  String _fmtLarge(double v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

class _MiniStat extends StatelessWidget {
  final String l, v;
  final Color? color;
  const _MiniStat(this.l, this.v, {this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text('$l: ', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    Text(v, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
  ]);
}

// ── CREATE / LINK MT5 ACCOUNT SHEET ──────────────────────────────────────────
class _AddAccountSheet extends StatefulWidget {
  const _AddAccountSheet();
  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  // Tab: 0 = Create New, 1 = Link CRM Account
  int _tab = 0;

  // --- Create New tab ---
  String _accountType = 'live';
  int _leverage       = 100;

  // --- Link CRM tab ---
  final _loginCtrl = TextEditingController();
  String _linkType = 'live';
  int _linkLeverage = 100;

  bool _loading = false;

  static const _types = [
    {'key': 'live',         'label': 'Live',   'color': AppColors.success},
    {'key': 'demo',         'label': 'Demo',   'color': AppColors.warning},
    {'key': 'cent',         'label': 'Cent',   'color': AppColors.accent},
    {'key': 'copy_trading', 'label': 'Copy',   'color': AppColors.primary},
  ];
  static const _leverages = [100, 200, 500];

  @override
  void dispose() {
    _loginCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<Mt5AccountStore>();
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        // Tab switcher
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.bg200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            _TabBtn(label: 'Create New', selected: _tab == 0,
                onTap: () => setState(() => _tab = 0)),
            _TabBtn(label: 'Link CRM Account', selected: _tab == 1,
                onTap: () => setState(() => _tab = 1)),
          ]),
        ),
        const SizedBox(height: 20),

        if (_tab == 0) ..._buildCreateTab(store, context)
        else ..._buildLinkTab(store, context),
      ]),
    );
  }

  List<Widget> _buildCreateTab(Mt5AccountStore store, BuildContext context) => [
    // Account type grid
    const Align(alignment: Alignment.centerLeft,
      child: Text('Account Type',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
    const SizedBox(height: 8),
    Row(children: _types.map((t) {
      final key = t['key'] as String;
      final label = t['label'] as String;
      final color = t['color'] as Color;
      final selected = _accountType == key;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _accountType = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : AppColors.bg200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : AppColors.border,
                width: selected ? 1.5 : 1.0),
          ),
          child: Center(child: Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: selected ? color : AppColors.textMuted))),
        ),
      ));
    }).toList()),
    const SizedBox(height: 16),

    // Leverage
    const Align(alignment: Alignment.centerLeft,
      child: Text('Leverage',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
    const SizedBox(height: 8),
    Row(children: _leverages.map((lev) {
      final selected = _leverage == lev;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _leverage = lev),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLighter : AppColors.bg200,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1.0),
          ),
          child: Center(child: Text('1:$lev', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800,
            color: selected ? AppColors.primary : AppColors.textMuted))),
        ),
      ));
    }).toList()),
    const SizedBox(height: 24),

    _ActionButton(
      label: 'Create Account',
      loading: _loading,
      onTap: () => _create(context, store),
    ),
  ];

  List<Widget> _buildLinkTab(Mt5AccountStore store, BuildContext context) => [
    // Info banner
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Row(children: [
        Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
        SizedBox(width: 10),
        Expanded(child: Text(
          'Enter your MT5 login number from the CRM to link it to this app account.',
          style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
        )),
      ]),
    ),
    const SizedBox(height: 16),

    // MT5 Login input
    TextField(
      controller: _loginCtrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'MT5 Login Number (e.g. 3000001)',
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.primary, size: 18),
        filled: true, fillColor: AppColors.bg200,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        isDense: true,
      ),
    ),
    const SizedBox(height: 14),

    // Account type
    const Align(alignment: Alignment.centerLeft,
      child: Text('Account Type',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
    const SizedBox(height: 8),
    Row(children: _types.map((t) {
      final key = t['key'] as String;
      final label = t['label'] as String;
      final color = t['color'] as Color;
      final selected = _linkType == key;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _linkType = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : AppColors.bg200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : AppColors.border,
                width: selected ? 1.5 : 1.0),
          ),
          child: Center(child: Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: selected ? color : AppColors.textMuted))),
        ),
      ));
    }).toList()),
    const SizedBox(height: 14),

    // Leverage
    const Align(alignment: Alignment.centerLeft,
      child: Text('Leverage',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
    const SizedBox(height: 8),
    Row(children: _leverages.map((lev) {
      final selected = _linkLeverage == lev;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _linkLeverage = lev),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLighter : AppColors.bg200,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1.0),
          ),
          child: Center(child: Text('1:$lev', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800,
            color: selected ? AppColors.primary : AppColors.textMuted))),
        ),
      ));
    }).toList()),
    const SizedBox(height: 24),

    _ActionButton(
      label: 'Link Account',
      loading: _loading,
      onTap: () => _link(context, store),
    ),
  ];

  Future<void> _create(BuildContext context, Mt5AccountStore store) async {
    setState(() => _loading = true);
    try {
      final account = await store.createAccount(accountType: _accountType, leverage: _leverage);
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CredentialsDialog(account: account),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(context, e.toString());
    }
  }

  Future<void> _link(BuildContext context, Mt5AccountStore store) async {
    final login = _loginCtrl.text.trim();
    if (login.isEmpty) {
      _showError(context, 'Please enter your MT5 login number');
      return;
    }
    setState(() => _loading = true);
    try {
      await store.linkExistingAccount(
        mt5Login: login,
        accountType: _linkType,
        leverage: _linkLeverage,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('MT5 #$login linked successfully'),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(context, e.toString());
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 12))),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 5),
    ));
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.textMuted,
      ))),
    ),
  ));
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.loading, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: loading ? AppColors.primaryLighter : AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: loading ? [] : [BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.35),
          blurRadius: 16, offset: const Offset(0, 4),
        )],
      ),
      child: Center(child: loading
        ? const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
        : Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))),
    ),
  );
}

// ── CREDENTIALS DIALOG (shown after account creation) ───────────────────────
class _CredentialsDialog extends StatelessWidget {
  final Mt5Account account;
  const _CredentialsDialog({required this.account});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bg100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Success header
        Center(child: Column(children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
          ),
          const SizedBox(height: 12),
          const Text('Account Created!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Save your credentials below',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ])),
        const SizedBox(height: 20),

        // Warning banner
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'These passwords will NOT be shown again. Copy and save them now.',
              style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600),
            )),
          ]),
        ),
        const SizedBox(height: 16),

        // Credentials
        _CredRow('MT5 Login',         account.login),
        _CredRow('Server',            account.server),
        _CredRow('Account Type',      account.type),
        _CredRow('Leverage',          account.leverage),
        if (account.tradingPassword != null)
          _CredRow('Trading Password', account.tradingPassword!, copyable: true),
        if (account.investorPassword != null)
          _CredRow('Investor Password', account.investorPassword!, copyable: true),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Done — I saved my credentials',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _CredRow extends StatelessWidget {
  final String label, value;
  final bool copyable;
  const _CredRow(this.label, this.value, {this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 130,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        )),
        if (copyable)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$label copied'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.copy_rounded, color: AppColors.primary, size: 16),
            ),
          ),
      ]),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title; final List<_MI> items;
  const _MenuSection(this.title, this.items);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.4)),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.bg100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [BoxShadow(color: Color(0x060000FF), blurRadius: 8)],
        ),
        child: Column(children: items.asMap().entries.map((e) {
          final i = e.key; final item = e.value;
          return Column(children: [
            ListTile(
              onTap: item.onTap,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: item.color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(9)),
                child: Icon(item.icon, color: item.color, size: 18),
              ),
              title: Text(item.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
              dense: true,
            ),
            if (i < items.length - 1)
              const Divider(height: 1, indent: 56, endIndent: 16),
          ]);
        }).toList()),
      ),
    ]),
  ).animate().fadeIn(delay: 150.ms);
}

class _MI {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _MI(this.icon, this.label, this.color, this.onTap);
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
    child: GestureDetector(
      onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: AppTextStyles.headingSmall),
        content: const Text('Are you sure you want to sign out?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            context.read<AuthCubit>().logout();
            Navigator.pop(context);
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
          }, child: const Text('Sign Out', style: TextStyle(color: AppColors.error))),
        ],
      )),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha:0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Text('Sign Out', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
        ]),
      ),
    ),
  ).animate().fadeIn(delay: 400.ms);
}

// ── ALL PROFILE SUB-PAGES ─────────────────────────────────────────────────────

class _PersonalInfoPage extends StatelessWidget {
  const _PersonalInfoPage({super.key});

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final phone = user?.phone.isNotEmpty == true ? user!.phone : '—';
    final since = user != null ? _fmtDate(user.createdAt) : '—';

    return _SubPage('Personal Information', children: [
      _InfoTile('First Name', user?.firstName.isNotEmpty == true ? user!.firstName : '—'),
      _InfoTile('Last Name', user?.lastName.isNotEmpty == true ? user!.lastName : '—'),
      _InfoTile('Email', user?.email.isNotEmpty == true ? user!.email : '—'),
      _InfoTile('Phone', phone),
      _InfoTile('Account Tier', user?.tier ?? '—'),
      _InfoTile('Email Verified', user?.emailVerified == true ? 'Yes ✓' : 'No'),
      _InfoTile('2FA Enabled', user?.twoFAEnabled == true ? 'Yes ✓' : 'No'),
      _InfoTile('Member Since', since),
    ]);
  }
}

class _KYCStatusPage extends StatefulWidget {
  const _KYCStatusPage({super.key});
  @override
  State<_KYCStatusPage> createState() => _KYCStatusPageState();
}

class _KYCStatusPageState extends State<_KYCStatusPage> {
  KycStatus? _kyc;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final kyc = await FinanceRepository.instance.getKycStatus();
      if (mounted) setState(() { _kyc = kyc; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _SubPage('KYC Verification', children: [
        const Center(child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primary),
        )),
      ]);
    }

    if (_error != null) {
      return _SubPage('KYC Verification', children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 32),
            const SizedBox(height: 8),
            const Text('Could not load KYC status', style: TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      ]);
    }

    final status = _kyc?.status ?? 'not-submitted';
    final isVerified = status == 'verified';
    final isRejected = status == 'rejected';
    final isPending = status == 'pending';

    Color statusColor = isVerified ? AppColors.success
        : (isRejected ? AppColors.error : AppColors.warning);
    Color statusBg = isVerified ? AppColors.successBg
        : (isRejected ? AppColors.errorBg : AppColors.warningBg);
    IconData statusIcon = isVerified ? Icons.verified_rounded
        : (isRejected ? Icons.cancel_rounded
        : (isPending ? Icons.hourglass_empty_rounded : Icons.upload_file_rounded));
    String statusMsg = isVerified ? 'Your KYC is fully verified. You can trade without limits.'
        : (isRejected ? 'Your KYC was rejected. Please re-submit with correct documents.'
        : (isPending ? 'KYC documents are under review. Usually takes 1-2 business days.'
        : 'KYC not submitted yet. Complete verification to unlock full trading access.'));

    return _SubPage('KYC Verification', children: [
      // Live status badge
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isVerified ? 'Verified' : (isRejected ? 'Rejected' : (isPending ? 'Under Review' : 'Not Submitted')),
              style: TextStyle(color: statusColor, fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(statusMsg, style: TextStyle(color: statusColor.withValues(alpha: 0.8), fontSize: 12)),
          ])),
        ]),
      ),
      const SizedBox(height: 20),

      // Checklist
      _KYCRow('Identity Document', isVerified),
      _KYCRow('Proof of Address', isVerified),
      _KYCRow('Bank Account Linked', isVerified),
      _KYCRow('Selfie / Liveness Check', isVerified),
      _KYCRow('Risk Profile Completed', isVerified),

      if (!isVerified) ...[
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.kycStart),
          icon: Icon(isRejected ? Icons.refresh_rounded : Icons.upload_file_rounded),
          label: Text(isRejected ? 'Re-Submit KYC' : (isPending ? 'View KYC Status' : 'Start KYC Now')),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    ]);
  }
}

class _TransactionHistoryPage extends StatefulWidget {
  const _TransactionHistoryPage({super.key});
  @override
  State<_TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<_TransactionHistoryPage> {
  List<FinanceTransaction> _txns = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // 'all' | 'deposit' | 'withdrawal'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final txns = await FinanceRepository.instance.getTransactions();
      if (mounted) setState(() { _txns = txns; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month-1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'all' ? _txns
        : _txns.where((t) => t.type == _filter).toList();

    return _SubPage(
      'Transaction History',
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final f in ['all', 'deposit', 'withdrawal'])
              GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8, bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _filter == f ? AppColors.primaryLighter : AppColors.bg200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _filter == f ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(
                    f == 'all' ? 'All' : (f == 'deposit' ? 'Deposits' : 'Withdrawals'),
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: _filter == f ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
          ]),
        ),

        if (_loading)
          const Center(child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: AppColors.primary),
          ))
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 32),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ]),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(children: [
              const Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 48),
              const SizedBox(height: 12),
              Text(
                _filter == 'all'
                    ? 'No transactions yet.\nMake your first deposit to get started!'
                    : 'No ${_filter}s yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ]),
          )
        else
          ...filtered.map((t) {
            final isDeposit = t.isDeposit;
            final amtStr = '${isDeposit ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}';
            Color statusColor = t.isCompleted ? AppColors.success
                : (t.isRejected ? AppColors.error : AppColors.warning);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDeposit ? AppColors.successBg : AppColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: isDeposit ? AppColors.success : AppColors.error, size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isDeposit ? 'Deposit' : 'Withdrawal', style: AppTextStyles.labelLarge),
                  Text(
                    '${t.paymentMethodName.isNotEmpty ? t.paymentMethodName : 'Payment'} · ${_fmtDate(t.createdAt)}',
                    style: AppTextStyles.caption,
                  ),
                  if (t.reference != null)
                    Text('Ref: ${t.reference}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(amtStr, style: AppTextStyles.numericSmall.copyWith(
                      color: isDeposit ? AppColors.success : AppColors.error, fontSize: 14)),
                  Text(
                    t.status[0].toUpperCase() + t.status.substring(1),
                    style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ]),
              ]),
            );
          }),
      ],
    );
  }
}

class _DocumentsPage extends StatelessWidget {
  const _DocumentsPage({super.key});
  @override
  Widget build(BuildContext context) => _SubPage('Documents', children: [
    _DocRow('Passport / National ID', 'Verified', Icons.badge_outlined),
    _DocRow('Proof of Address', 'Verified', Icons.home_outlined),
    _DocRow('Bank Statement', 'Verified', Icons.account_balance_outlined),
    _DocRow('Tax Document', 'Pending', Icons.description_outlined),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.upload_file_outlined),
      label: const Text('Upload New Document'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    ),
  ]);
}

class _ChangePinPage extends StatelessWidget {
  const _ChangePinPage({super.key});
  @override
  Widget build(BuildContext context) => _SubPage('Change PIN', children: [
    const Text('Enter your current 6-digit PIN, then set a new one.', style: AppTextStyles.bodyMedium),
    const SizedBox(height: 24),
    _PinDots('Current PIN'),
    const SizedBox(height: 20),
    _PinDots('New PIN'),
    const SizedBox(height: 20),
    _PinDots('Confirm New PIN'),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Update PIN')),
  ]);
}

class _BiometricPage extends StatelessWidget {
  const _BiometricPage({super.key});
  @override
  Widget build(BuildContext context) => _SubPage('Biometric Settings', children: [
    _SwitchRow('Face ID / Fingerprint Login', true),
    _SwitchRow('Require biometric for trades', false),
    _SwitchRow('Require biometric for withdrawals', true),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primaryLighter, borderRadius: BorderRadius.circular(12)),
        child: const Text('Biometric data is stored securely on your device and never sent to our servers.', style: TextStyle(color: AppColors.primary, fontSize: 12))),
  ]);
}

class _TwoFAPage extends StatelessWidget {
  const _TwoFAPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final twoFA = user?.twoFAEnabled ?? false;
    final emailVerified = user?.emailVerified ?? false;

    return _SubPage('Two-Factor Authentication', children: [
      _SwitchRow('Enable 2FA', twoFA),
      _SwitchRow('SMS Authentication', twoFA),
      _SwitchRow('Authenticator App', false),
      _SwitchRow('Email Verification', emailVerified),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: twoFA ? AppColors.successBg : AppColors.warningBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          twoFA
              ? '2FA is active. Your account has extra security enabled.'
              : '2FA is not enabled. Enable it for added account security.',
          style: TextStyle(
            color: twoFA ? AppColors.success : AppColors.warning,
            fontSize: 12,
          ),
        ),
      ),
    ]);
  }
}

class _DevicesPage extends StatelessWidget {
  const _DevicesPage({super.key});
  @override
  Widget build(BuildContext context) => _SubPage('Trusted Devices', children: [
    _DeviceRow('iPhone 16 Pro · iOS 18', 'Mumbai, India · Active now', true),
    _DeviceRow('MacBook Air · Chrome', 'Mumbai, India · 2 hours ago', false),
    _DeviceRow('iPad Pro · Safari', 'Mumbai, India · 3 days ago', false),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
      label: const Text('Remove All Other Devices', style: TextStyle(color: AppColors.error)),
      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46), side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    ),
  ]);
}

class _AccountSettingsPage extends StatelessWidget {
  const _AccountSettingsPage({super.key});
  @override
  Widget build(BuildContext context) => _SubPage('Account Settings', children: [
    _InfoTile('Default Leverage', '1:500'),
    _InfoTile('Base Currency', 'USD'),
    _InfoTile('Account Type', 'Standard'),
    _InfoTile('Server', 'MT5-Live-1'),
    _SwitchRow('One-Click Trading', true),
    _SwitchRow('Show Profit in %', false),
    _SwitchRow('Confirm Before Order', true),
  ]);
}

class _NotificationsSettingsPage extends StatelessWidget {
  const _NotificationsSettingsPage({super.key});
  @override
  Widget build(BuildContext context) => _SubPage('Notifications', children: [
    _SwitchRow('Push Notifications', true),
    _SwitchRow('Order Executed', true),
    _SwitchRow('Position Closed', true),
    _SwitchRow('Price Alerts', true),
    _SwitchRow('Deposit / Withdrawal', true),
    _SwitchRow('News & Market Updates', false),
    _SwitchRow('Copy Trade Activity', true),
    _SwitchRow('Email Notifications', false),
  ]);
}

class _TradingReportsPage extends StatelessWidget {
  const _TradingReportsPage({super.key});
  @override
  Widget build(BuildContext context) => _SubPage('Trading Reports', children: [
    _StatCard2('Total Profit', '+\$2,456.20', AppColors.bullish),
    _StatCard2('Total Trades', '142', AppColors.primary),
    _StatCard2('Win Rate', '68.3%', AppColors.accent),
    _StatCard2('Best Month', '+\$840.00 (Mar)', AppColors.bullish),
    _StatCard2('Worst Month', '-\$210.00 (Apr)', AppColors.bearish),
    _StatCard2('Profit Factor', '2.14', AppColors.gold),
    const SizedBox(height: 16),
    ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.download_outlined),
      label: const Text('Download PDF Report'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    ),
  ]);
}

class _SupportPage extends StatelessWidget {
  const _SupportPage({super.key});
  @override
  Widget build(BuildContext context) => _SubPage('Live Support', children: [
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 40),
        const SizedBox(height: 8),
        const Text('24/7 Support Available', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const Text('Our team is always here to help', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Start Live Chat', style: TextStyle(fontWeight: FontWeight.w700))),
      ]),
    ),
    const SizedBox(height: 16),
    _ContactRow(Icons.email_outlined, 'Email Support', 'support@stockvala.com'),
    _ContactRow(Icons.phone_outlined, 'Phone Support', '+1 800 STOCKVALA'),
    _ContactRow(Icons.telegram, 'Telegram', '@StockValaSupport'),
  ]);
}

class _FaqPage extends StatelessWidget {
  const _FaqPage({super.key});
  final List<Map<String,String>> _faqs = const [
    {'q':'How do I deposit funds?','a':'Go to Home → Deposit, choose a payment method and follow the steps.'},
    {'q':'How long does withdrawal take?','a':'Bank transfers take 1-3 business days. Crypto withdrawals are processed within 24 hours.'},
    {'q':'What is copy trading?','a':'Copy trading lets you automatically replicate trades from expert traders in real time.'},
    {'q':'What is PAMM/MAM?','a':'PAMM/MAM accounts allow professional managers to trade on your behalf in pooled accounts.'},
    {'q':'How do I change my leverage?','a':'Go to Profile → Account Settings → Default Leverage.'},
  ];
  @override
  Widget build(BuildContext context) => _SubPage('FAQ', children: [
    ..._faqs.map((f) => ExpansionTile(
      title: Text(f['q']!, style: AppTextStyles.labelLarge),
      children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text(f['a']!, style: AppTextStyles.bodyMedium))],
    )),
  ]);
}

class _AboutPage extends StatelessWidget {
  const _AboutPage({super.key});
  @override
  Widget build(BuildContext context) => _SubPage('About StockVala', children: [
    Center(child: Column(children: [
      Container(width: 80, height: 80,
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.candlestick_chart_rounded, color: Colors.white, size: 40)),
      const SizedBox(height: 12),
      const Text('StockVala', style: AppTextStyles.headingLarge),
      const Text('Version 1.0.0', style: AppTextStyles.bodySmall),
    ])),
    const SizedBox(height: 24),
    _InfoTile('Platform', 'MT5 Powered'),
    _InfoTile('Headquarters', 'Dubai, UAE'),
    _InfoTile('Regulation', 'FSCA Licensed'),
    _InfoTile('Support Email', 'support@stockvala.com'),
    _InfoTile('Website', 'www.stockvala.com'),
    const SizedBox(height: 16),
    const Text('StockVala is an AI-native trading and investment platform powered by MetaTrader 5. We offer forex, commodities, indices, and crypto trading with copy trading and managed investment solutions.', style: AppTextStyles.bodyMedium),
  ]);
}

// ── SHARED WIDGETS ────────────────────────────────────────────────────────────

class _SubPage extends StatelessWidget {
  final String title; final List<Widget> children;
  const _SubPage(this.title, {required this.children, super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg100,
    appBar: AppBar(
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)),
      title: Text(title),
    ),
    body: ListView(padding: const EdgeInsets.all(20), children: children),
  );
}

class _InfoTile extends StatelessWidget {
  final String l, v;
  const _InfoTile(this.l, this.v);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
    child: Row(children: [
      Text(l, style: AppTextStyles.bodyMedium),
      const Spacer(),
      Text(v, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
    ]),
  );
}

class _KYCRow extends StatelessWidget {
  final String l; final bool done;
  const _KYCRow(this.l, this.done);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Container(width: 28, height: 28,
          decoration: BoxDecoration(color: done ? AppColors.success : AppColors.bg300, shape: BoxShape.circle),
          child: Icon(done ? Icons.check_rounded : Icons.access_time_rounded, color: Colors.white, size: 15)),
      const SizedBox(width: 12),
      Text(l, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary)),
    ]),
  );
}

class _DocRow extends StatelessWidget {
  final String l, status; final IconData icon;
  const _DocRow(this.l, this.status, this.icon);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.bg200, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Text(l, style: AppTextStyles.labelLarge)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: status == 'Verified' ? AppColors.successBg : AppColors.warningBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: status == 'Verified' ? AppColors.success : AppColors.warning)),
      ),
    ]),
  );
}

class _SwitchRow extends StatefulWidget {
  final String l; final bool init;
  const _SwitchRow(this.l, this.init);
  @override
  State<_SwitchRow> createState() => _SwitchRowState();
}

class _SwitchRowState extends State<_SwitchRow> {
  late bool _v;
  @override
  void initState() { super.initState(); _v = widget.init; }
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(widget.l, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary))),
      Switch(value: _v, onChanged: (v) => setState(() => _v = v)),
    ]),
  );
}

class _DeviceRow extends StatelessWidget {
  final String name, detail; final bool current;
  const _DeviceRow(this.name, this.detail, this.current);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: current ? AppColors.primaryLighter : AppColors.bg200,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: current ? AppColors.primary : AppColors.border),
    ),
    child: Row(children: [
      Icon(Icons.devices_rounded, color: current ? AppColors.primary : AppColors.textMuted, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: AppTextStyles.labelLarge),
        Text(detail, style: AppTextStyles.caption),
      ])),
      if (current) const Text('This device', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _PinDots extends StatelessWidget {
  final String label;
  const _PinDots(this.label);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: AppTextStyles.labelMedium),
    const SizedBox(height: 8),
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (_) => Container(
          width: 40, height: 48,
          decoration: BoxDecoration(color: AppColors.bg200, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
        ))),
  ]);
}

class _StatCard2 extends StatelessWidget {
  final String l, v; final Color c;
  const _StatCard2(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.bg200, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Text(l, style: AppTextStyles.bodyMedium),
      const Spacer(),
      Text(v, style: AppTextStyles.labelLarge.copyWith(color: c)),
    ]),
  );
}

class _ContactRow extends StatelessWidget {
  final IconData icon; final String l, v;
  const _ContactRow(this.icon, this.l, this.v);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.bg200, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: AppTextStyles.labelLarge),
        Text(v, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
      ]),
    ]),
  );
}
