import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../models/trading_models.dart';
import '../repository/trading_repository.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});
  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> with SingleTickerProviderStateMixin {
  String _selectedPair = 'EURUSD';
  String _selectedTf   = '1h';
  bool   _isBuy        = true;
  String _orderType    = 'Market';
  bool   _placing      = false;
  final _lotCtrl = TextEditingController(text: '0.10');
  final _slCtrl  = TextEditingController();
  final _tpCtrl  = TextEditingController();

  // Internal symbol → display name
  static const _pairs = ['EURUSD','GBPUSD','USDJPY','XAUUSD','BTCUSD','US30'];
  static const _displayNames = {
    'EURUSD': 'EUR/USD', 'GBPUSD': 'GBP/USD', 'USDJPY': 'USD/JPY',
    'XAUUSD': 'XAU/USD', 'BTCUSD': 'BTC/USD', 'US30': 'US30',
  };
  static const _tfs = ['1m','5m','15m','1h','4h','1D'];

  @override
  void initState() {
    super.initState();
    WebSocketService.instance.subscribe(_pairs);
  }

  @override
  void dispose() { _lotCtrl.dispose(); _slCtrl.dispose(); _tpCtrl.dispose(); super.dispose(); }

  String get _displayPair => _displayNames[_selectedPair] ?? _selectedPair;

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketService>(
      builder: (_, ws, __) {
        final tick = ws.tickFor(_selectedPair);
        return Scaffold(
          backgroundColor: AppColors.bg100,
          appBar: AppBar(
            title: _PairSelector(
              selected: _displayPair, pairs: _pairs.map((p) => _displayNames[p] ?? p).toList(),
              onChanged: (name) {
                final sym = _displayNames.entries.firstWhere((e) => e.value == name, orElse: () => MapEntry(name, name)).key;
                setState(() => _selectedPair = sym);
                WebSocketService.instance.subscribe([sym]);
              },
            ),
            actions: [
              // WS status indicator
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ws.isConnected ? AppColors.success : AppColors.warning,
                  ),
                )),
              ),
            ],
          ),
          body: Column(children: [
            _PriceHeader(tick: tick, pair: _displayPair),
            _TimeframeBar(tfs: _tfs, selected: _selectedTf, onSelect: (t) => setState(() => _selectedTf = t)),
            const Expanded(flex: 5, child: _ChartArea()),
            Expanded(flex: 4, child: _OrderTicket(
              isBuy: _isBuy, orderType: _orderType,
              lotCtrl: _lotCtrl, slCtrl: _slCtrl, tpCtrl: _tpCtrl,
              tick: tick,
              placing: _placing,
              onToggle: () => setState(() => _isBuy = !_isBuy),
              onOrderType: (t) => setState(() => _orderType = t),
              onPlace: _placeOrder,
              pair: _displayPair,
            )),
          ]),
        );
      },
    );
  }

  Future<void> _placeOrder() async {
    final store = Mt5AccountStore.instance;
    final acc = store.active;
    if (acc == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No active MT5 account'), backgroundColor: AppColors.error));
      return;
    }
    final lots = double.tryParse(_lotCtrl.text) ?? 0.1;
    final sl = double.tryParse(_slCtrl.text);
    final tp = double.tryParse(_tpCtrl.text);
    final orderType = switch (_orderType) {
      'Limit' => OrderType.limit,
      'Stop' => OrderType.stop,
      _ => OrderType.market,
    };
    final limitPrice = orderType != OrderType.market ? double.tryParse(_tpCtrl.text) : null;

    // Show confirm sheet first
    if (!mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ConfirmSheet(
        pair: _displayPair, isBuy: _isBuy, lots: _lotCtrl.text,
        orderType: _orderType, sl: sl, tp: tp,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _placing = true);
    try {
      final result = await TradingRepository.instance.placeOrder(OrderRequest(
        accountId: acc.id,
        symbol: _selectedPair,
        type: orderType,
        side: _isBuy ? OrderSide.buy : OrderSide.sell,
        lots: lots,
        price: limitPrice,
        stopLoss: sl,
        takeProfit: tp,
      ));
      if (!mounted) return;
      store.refreshActiveAccount();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.isFilled
            ? '${_isBuy ? 'BUY' : 'SELL'} $_displayPair filled @ ${result.executedPrice}'
            : result.message ?? 'Order placed'),
        backgroundColor: result.isFilled ? (_isBuy ? AppColors.bullish : AppColors.bearish) : AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.userMessage : 'Order failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }
}

class _PairSelector extends StatelessWidget {
  final String selected; final List<String> pairs; final ValueChanged<String> onChanged;
  const _PairSelector({required this.selected, required this.pairs, required this.onChanged});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Select Symbol', style: AppTextStyles.headingMedium),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: pairs.map((p) => GestureDetector(
            onTap: () { onChanged(p); Navigator.pop(context); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: p == selected ? AppColors.primaryLighter : AppColors.bg200,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p == selected ? AppColors.primary : AppColors.border),
              ),
              child: Text(p, style: TextStyle(fontWeight: FontWeight.w600,
                  color: p == selected ? AppColors.primary : AppColors.textPrimary)),
            ),
          )).toList()),
          const SizedBox(height: 16),
        ]),
      ),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(selected, style: AppTextStyles.headingMedium),
      const SizedBox(width: 4),
      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 20),
    ]),
  );
}

class _PriceHeader extends StatelessWidget {
  final QuoteTick? tick;
  final String pair;
  const _PriceHeader({required this.tick, required this.pair});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: const BoxDecoration(color: AppColors.bg200, border: Border(bottom: BorderSide(color: AppColors.border))),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tick?.formattedBid ?? '—',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
        if (tick != null)
          Row(children: [
            Icon(tick!.isBullish ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: tick!.isBullish ? AppColors.bullish : AppColors.bearish, size: 12),
            Text(tick!.formattedChange,
                style: TextStyle(color: tick!.isBullish ? AppColors.bullish : AppColors.bearish, fontSize: 11, fontWeight: FontWeight.w600)),
          ])
        else
          const Text('Connecting...', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]),
      const Spacer(),
      if (tick != null) ...[
        _PStat('Spread', tick!.spread.toStringAsFixed(1)),
        const SizedBox(width: 16),
        _PStat('High', tick!.formattedBid),
        const SizedBox(width: 16),
        _PStat('Low', tick!.formattedAsk),
      ],
    ]),
  );
}

class _PStat extends StatelessWidget {
  final String l, v;
  const _PStat(this.l, this.v);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(l, style: AppTextStyles.caption),
    Text(v, style: AppTextStyles.labelLarge),
  ]);
}

class _TimeframeBar extends StatelessWidget {
  final List<String> tfs; final String selected; final ValueChanged<String> onSelect;
  const _TimeframeBar({required this.tfs, required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) => Container(
    height: 38, color: AppColors.bg200,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: tfs.map((t) => GestureDetector(
        onTap: () => onSelect(t),
        child: AnimatedContainer(
          duration: 200.ms,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: selected == t ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: selected == t ? Colors.white : AppColors.textMuted)),
        ),
      )).toList()),
    ),
  );
}

class _ChartArea extends StatelessWidget {
  const _ChartArea();
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bg100,
    child: Stack(children: [
      Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: AppColors.primaryLighter, shape: BoxShape.circle),
            child: const Icon(Icons.candlestick_chart_rounded, color: AppColors.primary, size: 56)),
        const SizedBox(height: 12),
        const Text('Live MT5 Chart', style: AppTextStyles.bodyMedium),
        const Text('Embed WebView with MT5 Web Terminal', style: AppTextStyles.bodySmall),
      ])),
      Positioned(top: 8, right: 8, child: Row(children: [
        _CTool(Icons.show_chart_rounded),
        const SizedBox(width: 6),
        _CTool(Icons.draw_rounded),
        const SizedBox(width: 6),
        _CTool(Icons.settings_outlined),
      ])),
    ]),
  );
}

class _CTool extends StatelessWidget {
  final IconData icon;
  const _CTool(this.icon);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: AppColors.bg200, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
    child: Icon(icon, color: AppColors.textMuted, size: 18),
  );
}

class _OrderTicket extends StatelessWidget {
  final bool isBuy, placing;
  final String orderType, pair;
  final TextEditingController lotCtrl, slCtrl, tpCtrl;
  final QuoteTick? tick;
  final VoidCallback onToggle, onPlace;
  final ValueChanged<String> onOrderType;

  const _OrderTicket({
    required this.isBuy, required this.orderType, required this.pair,
    required this.lotCtrl, required this.slCtrl, required this.tpCtrl,
    required this.tick, required this.placing,
    required this.onToggle, required this.onOrderType, required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    final askPrice = tick?.formattedAsk ?? '—';
    final bidPrice = tick?.formattedBid ?? '—';

    return Container(
      decoration: const BoxDecoration(color: AppColors.bg200, border: Border(top: BorderSide(color: AppColors.border))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            Expanded(child: _SideBtn('BUY', askPrice, isBuy,  true,  () { if (!isBuy) onToggle(); })),
            const SizedBox(width: 8),
            Expanded(child: _SideBtn('SELL', bidPrice, !isBuy, false, () { if (isBuy) onToggle(); })),
          ]),
          const SizedBox(height: 10),
          Row(children: ['Market','Limit','Stop'].map((t) => Expanded(child: GestureDetector(
            onTap: () => onOrderType(t),
            child: AnimatedContainer(
              duration: 200.ms, margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: orderType == t ? AppColors.primaryLighter : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: orderType == t ? AppColors.primary : AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: orderType == t ? AppColors.primary : AppColors.textMuted)),
            ),
          ))).toList()),
          const SizedBox(height: 10),
          Row(children: [
            Text('Volume (Lots)', style: AppTextStyles.labelMedium),
            const Spacer(),
            _LotStepper(ctrl: lotCtrl),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _SmIn('Stop Loss', slCtrl)),
            const SizedBox(width: 8),
            Expanded(child: _SmIn('Take Profit', tpCtrl)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: isBuy
                    ? [AppColors.bullish, const Color(0xFF0A9050)]
                    : [AppColors.bearish, const Color(0xFFCC0000)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: (isBuy ? AppColors.bullish : AppColors.bearish).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                onPressed: placing ? null : onPlace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: placing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('${isBuy ? 'BUY' : 'SELL'} $pair',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SideBtn extends StatelessWidget {
  final String label, price; final bool selected, isBuy; final VoidCallback onTap;
  const _SideBtn(this.label, this.price, this.selected, this.isBuy, this.onTap);
  @override
  Widget build(BuildContext context) {
    final color = isBuy ? AppColors.bullish : AppColors.bearish;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.bg100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? color : AppColors.textMuted)),
          Text(price, style: TextStyle(fontSize: 11, color: color)),
        ]),
      ),
    );
  }
}

class _LotStepper extends StatelessWidget {
  final TextEditingController ctrl;
  const _LotStepper({required this.ctrl});
  @override
  Widget build(BuildContext context) => Row(children: [
    _SBtn(Icons.remove, () { final v = double.tryParse(ctrl.text) ?? 0.1; if (v > 0.01) ctrl.text = (v - 0.01).toStringAsFixed(2); }),
    SizedBox(width: 60, child: TextField(
      controller: ctrl, textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.labelLarge,
      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
    )),
    _SBtn(Icons.add, () { final v = double.tryParse(ctrl.text) ?? 0.1; ctrl.text = (v + 0.01).toStringAsFixed(2); }),
  ]);
}

class _SBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _SBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: AppColors.bg300, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
        child: Icon(icon, color: AppColors.textMuted, size: 16)),
  );
}

class _SmIn extends StatelessWidget {
  final String label; final TextEditingController ctrl;
  const _SmIn(this.label, this.ctrl);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: AppTextStyles.caption),
    const SizedBox(height: 4),
    TextField(
      controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.labelMedium,
      decoration: InputDecoration(
        hintText: '0.00000', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true, fillColor: AppColors.bg100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
      ),
    ),
  ]);
}

class _ConfirmSheet extends StatelessWidget {
  final String pair, lots, orderType;
  final bool isBuy;
  final double? sl, tp;
  const _ConfirmSheet({required this.pair, required this.lots, required this.orderType, required this.isBuy, this.sl, this.tp});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 20),
      Text('Confirm Order', style: AppTextStyles.headingMedium),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bg200, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(children: [
          _CR('Symbol', pair),
          _CR('Side', isBuy ? 'BUY' : 'SELL', valueColor: isBuy ? AppColors.bullish : AppColors.bearish),
          _CR('Order Type', orderType),
          _CR('Volume', '$lots lots'),
          _CR('Price', orderType == 'Market' ? 'Market Price' : 'Limit/Stop'),
          if (sl != null) _CR('Stop Loss', sl!.toStringAsFixed(5)),
          if (tp != null) _CR('Take Profit', tp!.toStringAsFixed(5)),
        ]),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel'))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: isBuy ? AppColors.bullish : AppColors.bearish),
          child: Text('Place ${isBuy ? 'BUY' : 'SELL'}'),
        )),
      ]),
      const SizedBox(height: 8),
    ]),
  );
}

class _CR extends StatelessWidget {
  final String l, v; final Color? valueColor;
  const _CR(this.l, this.v, {this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Text(l, style: AppTextStyles.bodyMedium),
      const Spacer(),
      Text(v, style: AppTextStyles.labelLarge.copyWith(color: valueColor ?? AppColors.textPrimary)),
    ]),
  );
}
