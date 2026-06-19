import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../../../features/trading/models/trading_models.dart';
import '../../../features/trading/repository/trading_repository.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<TradingPosition> _positions = [];
  List<TradeHistory> _history = [];
  bool _posLoading = true;
  bool _histLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _posLoading = true; _histLoading = true; _error = null; });
    final store = Mt5AccountStore.instance;
    final acc = store.active;
    if (acc == null) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _load();
      return;
    }
    try {
      final positions = await TradingRepository.instance.getPositions(accountId: acc.id);
      if (mounted) setState(() { _positions = positions; _posLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _posLoading = false; _error = e.toString(); });
    }
    try {
      final history = await TradingRepository.instance.getHistory(accountId: acc.id, limit: 50);
      if (mounted) setState(() { _history = history; _histLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _histLoading = false; });
    }
  }

  Future<void> _closePosition(TradingPosition pos) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Close Position'),
        content: Text('Close ${pos.side.name.toUpperCase()} ${pos.symbol} ${pos.lots} lots?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final store = Mt5AccountStore.instance;
    try {
      await TradingRepository.instance.closePosition(accountId: store.active?.id ?? '', ticket: pos.ticket);
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Position closed successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        _load();
        store.refreshActiveAccount();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to close: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _closeAll() async {
    if (_positions.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Close All Positions'),
        content: Text('Close all ${_positions.length} open positions?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Close All'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final store = Mt5AccountStore.instance;
      await TradingRepository.instance.closeAllPositions(store.active?.id ?? '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('All positions closed'), backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        _load();
        store.refreshActiveAccount();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Mt5AccountStore>(
      builder: (_, store, __) {
        final acc = store.active;
        final openPL = acc?.openPL ?? 0.0;
        final equity = acc?.equity ?? 0.0;
        final freeMargin = acc?.freeMargin ?? 0.0;

        return Scaffold(
          backgroundColor: AppColors.bg100,
          appBar: AppBar(
            title: const Text('Portfolio'),
            actions: [
              if (_positions.isNotEmpty)
                TextButton(
                  onPressed: _closeAll,
                  child: Text('Close All', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
                ),
              IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
            ],
            bottom: TabBar(
              controller: _tab,
              tabs: [
                Tab(text: 'Open (${_positions.length})'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: Column(children: [
            // Summary strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.bg200,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(children: [
                _SummaryChip('Open P/L', '${openPL >= 0 ? '+' : ''}\$${openPL.abs().toStringAsFixed(2)}',
                    openPL >= 0 ? AppColors.bullish : AppColors.bearish),
                const SizedBox(width: 16),
                _SummaryChip('Equity', '\$${equity.toStringAsFixed(2)}', AppColors.primary),
                const SizedBox(width: 16),
                _SummaryChip('Free Margin', '\$${freeMargin.toStringAsFixed(2)}', AppColors.textSecondary),
              ]),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: TabBarView(controller: _tab, children: [
                  _OpenPositionsTab(
                    positions: _positions,
                    loading: _posLoading,
                    error: _error,
                    onClose: _closePosition,
                    onRetry: _load,
                  ),
                  _HistoryTab(history: _history, loading: _histLoading),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChip(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: AppTextStyles.caption),
    Text(value, style: AppTextStyles.labelMedium.copyWith(color: color)),
  ]);
}

// ── OPEN POSITIONS ────────────────────────────────────────────────────────────
class _OpenPositionsTab extends StatelessWidget {
  final List<TradingPosition> positions;
  final bool loading;
  final String? error;
  final ValueChanged<TradingPosition> onClose;
  final VoidCallback onRetry;
  const _OpenPositionsTab({required this.positions, required this.loading, this.error, required this.onClose, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (error != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 48),
      const SizedBox(height: 12),
      const Text('Failed to load positions', style: AppTextStyles.bodyMedium),
      const SizedBox(height: 8),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ]));
    if (positions.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: AppColors.primaryLighter, shape: BoxShape.circle),
          child: const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 48)),
      const SizedBox(height: 16),
      const Text('No open positions', style: AppTextStyles.headingSmall),
      const SizedBox(height: 8),
      const Text('Your open trades will appear here', style: AppTextStyles.bodySmall),
    ]));

    final totalPL = positions.fold(0.0, (s, p) => s + p.totalProfit);

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Text('${positions.length} positions', style: AppTextStyles.labelMedium),
          const Spacer(),
          Text('${totalPL >= 0 ? '+' : ''}\$${totalPL.toStringAsFixed(2)}',
              style: AppTextStyles.labelMedium.copyWith(color: totalPL >= 0 ? AppColors.bullish : AppColors.bearish)),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          itemCount: positions.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
          itemBuilder: (_, i) => _PositionCard(position: positions[i], index: i, onClose: onClose),
        ),
      ),
    ]);
  }
}

class _PositionCard extends StatelessWidget {
  final TradingPosition position;
  final int index;
  final ValueChanged<TradingPosition> onClose;
  const _PositionCard({required this.position, required this.index, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isBuy = position.side == OrderSide.buy;
    final profit = position.totalProfit;
    final profitPos = profit >= 0;
    final pips = ((position.currentPrice - position.openPrice) * (isBuy ? 1 : -1) * 10000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isBuy ? AppColors.bullishBg : AppColors.bearishBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(isBuy ? 'BUY' : 'SELL',
              style: TextStyle(fontSize: 11, color: isBuy ? AppColors.bullish : AppColors.bearish, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(position.symbol, style: AppTextStyles.labelLarge),
          Text('${position.lots} lots · #${position.ticket}', style: AppTextStyles.caption),
          Text('Open: ${position.openPrice}  Now: ${position.currentPrice}',
              style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${profitPos ? '+' : ''}\$${profit.toStringAsFixed(2)}',
              style: AppTextStyles.numericSmall.copyWith(
                  fontSize: 14, color: profitPos ? AppColors.bullish : AppColors.bearish)),
          Text('${profitPos ? '+' : ''}$pips pts',
              style: AppTextStyles.caption.copyWith(color: profitPos ? AppColors.bullish : AppColors.bearish)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); onClose(position); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: const Text('Close', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 40));
  }
}

// ── HISTORY TAB ───────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final List<TradeHistory> history;
  final bool loading;
  const _HistoryTab({required this.history, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (history.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 48),
      const SizedBox(height: 12),
      const Text('No trade history', style: AppTextStyles.bodyMedium),
    ]));

    final totalNet = history.fold(0.0, (s, t) => s + t.netProfit);

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Text('${history.length} trades', style: AppTextStyles.labelMedium),
          const Spacer(),
          Text('Net: ${totalNet >= 0 ? '+' : ''}\$${totalNet.toStringAsFixed(2)}',
              style: AppTextStyles.labelMedium.copyWith(color: totalNet >= 0 ? AppColors.bullish : AppColors.bearish)),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          itemCount: history.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
          itemBuilder: (_, i) => _HistoryRow(trade: history[i], index: i),
        ),
      ),
    ]);
  }
}

class _HistoryRow extends StatelessWidget {
  final TradeHistory trade;
  final int index;
  const _HistoryRow({required this.trade, required this.index});

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.side == OrderSide.buy;
    final profit = trade.netProfit;
    final profitPos = profit >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(trade.symbol, style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isBuy ? AppColors.bullishBg : AppColors.bearishBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${isBuy ? 'buy' : 'sell'} ${trade.lots}',
                  style: TextStyle(fontSize: 10, color: isBuy ? AppColors.bullish : AppColors.bearish, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 3),
          Text('${trade.openPrice.toStringAsFixed(5)} → ${trade.closePrice.toStringAsFixed(5)}',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          Text(_fmt(trade.closeTime), style: AppTextStyles.caption),
        ])),
        Text(
          '${profitPos ? '+' : ''}\$${profit.abs().toStringAsFixed(2)}',
          style: AppTextStyles.numericSmall.copyWith(color: profitPos ? AppColors.bullish : AppColors.bearish, fontSize: 14),
        ),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 25));
  }

  String _fmt(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2,'0')}.${dt.day.toString().padLeft(2,'0')} '
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
}
