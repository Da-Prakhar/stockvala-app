import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../../../shared/widgets/vantage.dart';
import '../../deposit/screens/deposit_screen.dart';
import '../../finance/repository/finance_repository.dart';
import '../../trading/models/trading_models.dart';
import '../../trading/repository/trading_repository.dart';

/// V2 Funds tab — Vantage "Funds" layout over our MT5 accounts + fund history.
class FundsScreen extends StatefulWidget {
  const FundsScreen({super.key});
  @override
  State<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends State<FundsScreen> with AutomaticKeepAliveClientMixin {
  int _seg = 0; // 0 Overview · 1 Trade History · 2 Funding
  bool _hidden = false;
  List<FinanceTransaction> _txs = [];
  bool _txLoading = false;

  // ── Trade history + period P/L ──────────────────────────────────────────
  List<TradeHistory> _trades = [];
  bool _tradesLoading = false;
  int _period = 1; // index into _periods
  static const _periods = [
    ('1D', Duration(days: 1)),
    ('7D', Duration(days: 7)),
    ('1M', Duration(days: 30)),
    ('3M', Duration(days: 90)),
    ('All', Duration(days: 36500)),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTxs();
  }

  Future<void> _loadTrades() async {
    final acc = Mt5AccountStore.instance.active;
    if (acc == null) return;
    setState(() => _tradesLoading = _trades.isEmpty);
    try {
      final h = await TradingRepository.instance
          .getHistory(accountId: acc.id, limit: 200);
      if (mounted) setState(() { _trades = h; _tradesLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _tradesLoading = false);
    }
  }

  List<TradeHistory> get _periodTrades {
    final cutoff = DateTime.now().subtract(_periods[_period].$2);
    return _trades.where((t) => t.closeTime.isAfter(cutoff)).toList();
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
                tabs: const ['Overview', 'Trade History', 'Funding'],
                selected: _seg,
                big: true,
                fontSize: 19,
                onTap: (i) {
                  setState(() => _seg = i);
                  if (i == 1) _loadTrades();
                },
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

            if (_seg == 1) ...[
              // ── Period chips ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: VChipTabs(
                  tabs: _periods.map((p) => p.$1).toList(),
                  selected: _period,
                  onTap: (i) => setState(() => _period = i),
                ),
              ),
              const SizedBox(height: 14),
              // ── P/L summary card ───────────────────────────────────────
              Builder(builder: (context) {
                final rows = _periodTrades;
                final net = rows.fold<double>(
                    0, (s, t) => s + t.profit + t.swap + t.commission);
                final wins = rows.where((t) => t.profit > 0).length;
                final nc = net >= 0 ? AppColors.bullish : AppColors.bearish;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: VCard(
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_periods[_period].$1} Net P/L',
                                  style: const TextStyle(fontSize: 13,
                                      color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                  _hidden
                                      ? '••••'
                                      : '${net >= 0 ? '+' : ''}${net.toStringAsFixed(2)} USD',
                                  style: TextStyle(fontSize: 24,
                                      fontWeight: FontWeight.w800, color: nc)),
                            ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${rows.length} trades',
                            style: const TextStyle(fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 3),
                        Text(
                            rows.isEmpty
                                ? '—'
                                : '${(wins * 100 / rows.length).toStringAsFixed(0)}% win rate',
                            style: const TextStyle(fontSize: 12.5,
                                color: AppColors.textMuted)),
                      ]),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 14),
              if (_tradesLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.primary)),
                )
              else if (_periodTrades.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No closed trades in this period',
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted))),
                )
              else
                ..._periodTrades.map((t) => _TradeRow(trade: t, hidden: _hidden)),
            ] else if (_seg == 2) ...[
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

class _TradeRow extends StatelessWidget {
  final TradeHistory trade;
  final bool hidden;
  const _TradeRow({required this.trade, required this.hidden});

  @override
  Widget build(BuildContext context) {
    final t = trade;
    final isBuy = t.side == OrderSide.buy;
    final pc = t.profit >= 0 ? AppColors.bullish : AppColors.bearish;
    final d = t.closeTime;
    String two(int v) => v.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: VCard(
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          SymbolAvatar(t.symbol, size: 36),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(t.symbol,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isBuy ? AppColors.bullishBg : AppColors.bearishBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${isBuy ? 'Buy' : 'Sell'} ${t.lots.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                          color: isBuy ? AppColors.bullish : AppColors.bearish)),
                ),
              ]),
              const SizedBox(height: 3),
              Text(
                  '${t.openPrice} → ${t.closePrice} · ${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            ]),
          ),
          Text(hidden ? '••••' : '${t.profit >= 0 ? '+' : ''}${t.profit.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: pc)),
        ]),
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
