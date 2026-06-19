import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../../trading/models/trading_models.dart';
import '../../trading/repository/trading_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<TradeHistory> _history = [];
  bool _loading = true;
  String? _error;
  String _filter = 'All';
  static const _filters = ['All', 'Today', 'Week', 'Month'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final acc = Mt5AccountStore.instance.active;
    if (acc == null) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _load();
      return;
    }
    DateTime? from;
    final now = DateTime.now();
    if (_filter == 'Today') from = DateTime(now.year, now.month, now.day);
    if (_filter == 'Week') from = now.subtract(const Duration(days: 7));
    if (_filter == 'Month') from = DateTime(now.year, now.month, 1);

    try {
      final history = await TradingRepository.instance.getHistory(
        accountId: acc.id, from: from, limit: 100,
      );
      if (mounted) setState(() { _history = history; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<TradeHistory> get _closedPositions => _history;
  double get _totalProfit => _history.fold(0.0, (s, t) => s + t.netProfit);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: AppBar(
        title: const Text('History'),
        leading: IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Positions'),
            Tab(text: 'Orders'),
            Tab(text: 'Deals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildPositionsTab(),
          _OrdersTab(),
          _buildDealsTab(),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Filter by Period', style: AppTextStyles.headingMedium),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: _filters.map((f) => GestureDetector(
            onTap: () {
              Navigator.pop(context);
              setState(() => _filter = f);
              _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _filter == f ? AppColors.primaryLighter : AppColors.bg200,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _filter == f ? AppColors.primary : AppColors.border),
              ),
              child: Text(f, style: TextStyle(fontWeight: FontWeight.w600,
                  color: _filter == f ? AppColors.primary : AppColors.textPrimary)),
            ),
          )).toList()),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _buildPositionsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);
    if (_closedPositions.isEmpty) return const _EmptyState(label: 'No closed positions in this period');

    return Column(children: [
      // Summary bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(color: AppColors.bg200, border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [
          Text('${_closedPositions.length} positions · $_filter', style: AppTextStyles.labelMedium),
          const Spacer(),
          Text(
            '${_totalProfit >= 0 ? '+' : ''}\$${_totalProfit.abs().toStringAsFixed(2)}',
            style: AppTextStyles.numericSmall.copyWith(
              color: _totalProfit >= 0 ? AppColors.bullish : AppColors.bearish,
            ),
          ),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView.separated(
            itemCount: _closedPositions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
            itemBuilder: (_, i) => _PositionRow(trade: _closedPositions[i], index: i),
          ),
        ),
      ),
    ]);
  }

  Widget _buildDealsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);
    if (_history.isEmpty) return const _EmptyState(label: 'No deals in this period');

    final deposit = _history.fold(0.0, (s, t) => s + (t.profit > 0 ? t.profit : 0));
    final loss = _history.fold(0.0, (s, t) => s + (t.profit < 0 ? t.profit : 0));
    final swap = _history.fold(0.0, (s, t) => s + t.swap);
    final commission = _history.fold(0.0, (s, t) => s + t.commission);
    final net = _totalProfit;

    return ListView.builder(
      itemCount: _history.length + 1,
      itemBuilder: (_, i) {
        if (i < _history.length) return _DealRow(trade: _history[i], index: i);
        return _DealsSummary(deposit: deposit, loss: loss, swap: swap, commission: commission, net: net);
      },
    );
  }
}

class _PositionRow extends StatelessWidget {
  final TradeHistory trade;
  final int index;
  const _PositionRow({required this.trade, required this.index});

  @override
  Widget build(BuildContext context) {
    final profit = trade.netProfit;
    final isBuy = trade.side == OrderSide.buy;
    final profitColor = profit >= 0 ? AppColors.bullish : AppColors.bearish;

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
              child: Text(
                '${isBuy ? 'buy' : 'sell'} ${trade.lots}',
                style: TextStyle(fontSize: 10, color: isBuy ? AppColors.bullish : AppColors.bearish, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 3),
          Text('${trade.openPrice.toStringAsFixed(5)} → ${trade.closePrice.toStringAsFixed(5)}',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          Text(_fmt(trade.closeTime), style: AppTextStyles.caption),
        ])),
        Text(
          '${profit >= 0 ? '+' : ''}\$${profit.abs().toStringAsFixed(2)}',
          style: AppTextStyles.numericSmall.copyWith(color: profitColor, fontSize: 14),
        ),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 30));
  }

  String _fmt(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2,'0')}.${dt.day.toString().padLeft(2,'0')} '
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';
}

class _DealRow extends StatelessWidget {
  final TradeHistory trade;
  final int index;
  const _DealRow({required this.trade, required this.index});

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.side == OrderSide.buy;
    final profit = trade.netProfit;
    final profitColor = profit >= 0 ? AppColors.bullish : AppColors.bearish;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
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
          Text('${trade.openPrice.toStringAsFixed(5)} → ${trade.closePrice.toStringAsFixed(5)}',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          Text(_fmt(trade.closeTime), style: AppTextStyles.caption),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${profit >= 0 ? '+' : ''}\$${profit.abs().toStringAsFixed(2)}',
              style: AppTextStyles.numericSmall.copyWith(color: profitColor, fontSize: 14)),
          Text('#${trade.ticket}', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        ]),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 25));
  }

  String _fmt(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2,'0')}.${dt.day.toString().padLeft(2,'0')} '
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
}

class _DealsSummary extends StatelessWidget {
  final double deposit, loss, swap, commission, net;
  const _DealsSummary({required this.deposit, required this.loss, required this.swap, required this.commission, required this.net});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg200, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        _SR('Gross Profit', '\$${deposit.toStringAsFixed(2)}', AppColors.bullish),
        _SR('Gross Loss',   '\$${loss.abs().toStringAsFixed(2)}', AppColors.bearish),
        _SR('Swap',        '\$${swap.toStringAsFixed(2)}', AppColors.textMuted),
        _SR('Commission',  '\$${commission.abs().toStringAsFixed(2)}', AppColors.bearish),
        const Divider(height: 16),
        _SR('Net P/L', '${net >= 0 ? '+' : ''}\$${net.toStringAsFixed(2)}', net >= 0 ? AppColors.bullish : AppColors.bearish, bold: true),
      ]),
    );
  }
}

class _SR extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;
  const _SR(this.label, this.value, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Text(label, style: bold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium),
      const Spacer(),
      Text(value, style: (bold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium).copyWith(color: color)),
    ]),
  );
}

class _OrdersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const _EmptyState(label: 'No orders in history');
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppColors.primaryLighter, shape: BoxShape.circle),
        child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 48)),
    const SizedBox(height: 16),
    Text(label, style: AppTextStyles.headingSmall),
  ]));
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 48),
    const SizedBox(height: 12),
    const Text('Failed to load history', style: AppTextStyles.bodyMedium),
    const SizedBox(height: 8),
    TextButton(onPressed: onRetry, child: const Text('Retry')),
  ]));
}
