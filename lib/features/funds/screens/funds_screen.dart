import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../../../shared/widgets/vantage.dart';
import '../../deposit/screens/deposit_screen.dart';
import '../../finance/repository/finance_repository.dart';

/// V2 Funds tab — Vantage "Funds" layout over our MT5 accounts + fund history.
class FundsScreen extends StatefulWidget {
  const FundsScreen({super.key});
  @override
  State<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends State<FundsScreen> with AutomaticKeepAliveClientMixin {
  int _seg = 0; // 0 Overview · 1 CFDs · 2 History
  bool _hidden = false;
  List<FinanceTransaction> _txs = [];
  bool _txLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTxs();
  }

  Future<void> _loadTxs() async {
    setState(() => _txLoading = true);
    try {
      final results = await Future.wait([
        FinanceRepository.instance.getDeposits(),
        FinanceRepository.instance.getWithdrawals(),
      ]);
      final all = [...results[0], ...results[1]]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) setState(() { _txs = all; _txLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _txLoading = false);
    }
  }

  String _fmt(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final store = context.watch<Mt5AccountStore>();
    final accounts = store.accounts;
    final total = accounts.fold<double>(0, (s, a) => s + a.equity);
    final available = accounts.fold<double>(0, (s, a) => s + a.freeMargin);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Mt5AccountStore.instance.loadAccounts();
          await _loadTxs();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: VTextTabs(
                tabs: const ['Overview', 'CFDs', 'History'],
                selected: _seg,
                big: true,
                onTap: (i) => setState(() => _seg = i),
              ),
            ),
            const SizedBox(height: 18),

            // ── Total value ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () => setState(() => _hidden = !_hidden),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Total Value',
                        style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                    const SizedBox(width: 6),
                    Icon(_hidden ? Icons.visibility_off_rounded : Icons.remove_red_eye_rounded,
                        size: 15, color: AppColors.textMuted),
                  ]),
                ),
                const SizedBox(height: 4),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_hidden ? '••••' : _fmt(total),
                      style: const TextStyle(fontSize: 34, height: 1.05,
                          fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const Padding(
                    padding: EdgeInsets.only(left: 6, bottom: 4),
                    child: Text('USD', style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('Available  ${_hidden ? '••••' : _fmt(available)} USD',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Action chips ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _ActionChip(label: 'Withdraw', onTap: () =>
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const DepositScreen(isWithdraw: true)))),
                const SizedBox(width: 10),
                _ActionChip(label: 'History', onTap: () => setState(() => _seg = 2)),
                const Spacer(),
                SizedBox(
                  height: 46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(23),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DepositScreen())),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Center(
                          child: Text('Deposit', style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            if (_seg == 2) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: VSectionHeader('Transactions'),
              ),
              const SizedBox(height: 6),
              if (_txLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.primary)),
                )
              else if (_txs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No transactions yet',
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted))),
                )
              else
                ..._txs.take(30).map((t) => _TxRow(tx: t)),
            ] else ...[
              // ── Accounts ──────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: VSectionHeader('Trading Accounts'),
              ),
              const SizedBox(height: 6),
              if (accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No trading accounts yet',
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted))),
                )
              else
                ...accounts.map((a) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: VCard(
                        onTap: () {
                          final i = store.accounts.indexWhere((x) => x.id == a.id);
                          if (i >= 0) Mt5AccountStore.instance.switchTo(i);
                        },
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Container(
                            width: 42, height: 42,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: const Text('💼', style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(a.isReal ? 'Live' : 'Demo',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                            color: a.isReal ? AppColors.primary : const Color(0xFF7C5CFF))),
                                    const SizedBox(width: 6),
                                    Text('#${a.login}',
                                        style: const TextStyle(fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary)),
                                    if (store.active?.id == a.id) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.successBg,
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: const Text('Active',
                                            style: TextStyle(fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.success)),
                                      ),
                                    ],
                                  ]),
                                  const SizedBox(height: 2),
                                  Text('${a.server} · ${a.leverage}',
                                      style: const TextStyle(fontSize: 12.5,
                                          color: AppColors.textMuted)),
                                ]),
                          ),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(_hidden ? '••••' : _fmt(a.balance),
                                style: const TextStyle(fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text('≈ ${_hidden ? '••••' : _fmt(a.equity)} USD',
                                style: const TextStyle(fontSize: 12.5,
                                    color: AppColors.textMuted)),
                          ]),
                        ]),
                      ),
                    )),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 46,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bg300,
            borderRadius: BorderRadius.circular(23),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(23),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Text(label, style: const TextStyle(fontSize: 15.5,
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
            ),
          ),
        ),
      );
}

class _TxRow extends StatelessWidget {
  final FinanceTransaction tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isDep = tx.type == 'deposit';
    final sc = switch (tx.status) {
      'approved' || 'completed' => AppColors.success,
      'rejected' || 'failed' => AppColors.error,
      _ => AppColors.warning,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(color: AppColors.bg300, shape: BoxShape.circle),
          child: Icon(isDep ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 19, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isDep ? 'Deposit' : 'Withdrawal',
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(tx.createdAt.toString().split('.').first,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${isDep ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800,
                  color: isDep ? AppColors.bullish : AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(tx.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sc)),
        ]),
      ]),
    );
  }
}
