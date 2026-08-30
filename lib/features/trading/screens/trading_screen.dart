import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../../../core/services/spark_cache.dart';
import '../../../shared/widgets/vantage.dart';
import '../../copy_trading/screens/copy_trading_screen.dart';
import '../models/trading_models.dart';
import '../repository/trading_repository.dart';
import '../repository/market_data_repository.dart';
import '../widgets/candle_chart.dart';

/// V2 Trade tab — Vantage-style order ticket + expandable chart.
/// All order/position plumbing is unchanged from V1.
class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});

  /// Cross-tab symbol hand-off (Markets taps land here).
  static final ValueNotifier<String> symbolRequest = ValueNotifier('EURUSD');
  static void selectSymbol(String sym) => symbolRequest.value = sym;

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen>
    with AutomaticKeepAliveClientMixin {
  int _topTab = 0; // 0 CFDs · 1 Copy
  String _selectedPair = 'EURUSD';
  String _selectedTf = '15m';
  bool _isBuy = true;
  String _orderType = 'Market';
  bool _placing = false;
  bool _chartOpen = true;
  bool _tpslOpen = false;
  double _lots = 0.01;
  final _slCtrl = TextEditingController();
  final _tpCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  static const _pairs = [
    'EURUSD', 'GBPUSD', 'USDJPY', 'AUDUSD', 'USDCAD', 'USDCHF',
    'XAUUSD', 'XAGUSD', 'BTCUSD', 'ETHUSD', 'US30', 'SPX500', 'GER40', 'USOIL',
  ];
  static const _tfs = ['1m', '5m', '15m', '30m', '1h', '4h', '1D'];

  Timer? _tickBackstop;
  Timer? _posTimer;
  List<TradingPosition> _positions = [];
  int _bottomTab = 0; // Positions | Pending

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WebSocketService.instance.subscribe(_pairs);
    _startTickBackstop();
    _loadPositions();
    _posTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadPositions());
    TradingScreen.symbolRequest.addListener(_onSymbolRequest);
  }

  void _onSymbolRequest() {
    final sym = TradingScreen.symbolRequest.value;
    if (sym != _selectedPair && mounted) {
      setState(() => _selectedPair = sym);
      WebSocketService.instance.subscribe([sym]);
      _startTickBackstop();
    }
  }

  /// v7 pattern — REST tick poll backstop feeding the shared pipeline.
  void _startTickBackstop() {
    _tickBackstop?.cancel();
    Future<void> poll() async {
      final sym = _selectedPair;
      final t = await MarketDataRepository.instance.getTick(sym);
      if (t != null) {
        WebSocketService.instance.ingestRest(sym, t.bid, t.ask, epochSecs: t.time);
      }
    }

    poll();
    _tickBackstop = Timer.periodic(const Duration(seconds: 3), (_) => poll());
  }

  Future<void> _loadPositions() async {
    final acc = Mt5AccountStore.instance.active;
    if (acc == null) return;
    try {
      final p = await TradingRepository.instance.getPositions(accountId: acc.id);
      if (mounted) setState(() => _positions = p);
    } catch (_) {}
  }

  @override
  void dispose() {
    TradingScreen.symbolRequest.removeListener(_onSymbolRequest);
    _tickBackstop?.cancel();
    _posTimer?.cancel();
    _slCtrl.dispose();
    _tpCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ── Sentiment: share of up-closes in the recent spark series ─────────────
  double get _sentiment {
    final s = SparkCache.peek(_selectedPair);
    if (s == null || s.length < 3) return .5;
    var ups = 0;
    for (var i = 1; i < s.length; i++) {
      if (s[i] >= s[i - 1]) ups++;
    }
    return ups / (s.length - 1);
  }

  void _pickSymbol() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 8),
              child: Text('Select Instrument',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ),
            for (final p in _pairs)
              ListTile(
                leading: SymbolAvatar(p, size: 36),
                title: Text(p,
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                trailing: p == _selectedPair
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  TradingScreen.selectSymbol(p);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _pickOrderType() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final t in const ['Market', 'Limit', 'Stop'])
            ListTile(
              title: Text(t,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: t == _orderType ? FontWeight.w800 : FontWeight.w500,
                    color: t == _orderType ? AppColors.primary : AppColors.textPrimary,
                  )),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _orderType = t);
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final acc = Mt5AccountStore.instance.active;
    if (acc == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No active MT5 account'), backgroundColor: AppColors.error));
      return;
    }
    final sl = double.tryParse(_slCtrl.text);
    final tp = double.tryParse(_tpCtrl.text);
    final orderType = switch (_orderType) {
      'Limit' => OrderType.limit,
      'Stop' => OrderType.stop,
      _ => OrderType.market,
    };
    final price = orderType != OrderType.market ? double.tryParse(_priceCtrl.text) : null;
    if (orderType != OrderType.market && price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a price for pending orders'),
          backgroundColor: AppColors.error));
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_isBuy ? 'Buy' : 'Sell'} $_selectedPair',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            VInfoRow('Order Type', _orderType),
            VInfoRow('Volume', '${_lots.toStringAsFixed(2)} Lots'),
            if (price != null) VInfoRow('Price', price.toString()),
            if (sl != null) VInfoRow('Stop Loss', sl.toString(), valueColor: AppColors.bearish),
            if (tp != null) VInfoRow('Take Profit', tp.toString(), valueColor: AppColors.bullish),
            const SizedBox(height: 18),
            VPill(
              label: 'Confirm ${_isBuy ? 'Buy' : 'Sell'}',
              dark: !_isBuy,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 6),
          ]),
        ),
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
        lots: _lots,
        price: price,
        stopLoss: sl,
        takeProfit: tp,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${_isBuy ? 'Buy' : 'Sell'} ${_lots.toStringAsFixed(2)} $_selectedPair'
            '${result.executedPrice != null ? ' @ ${result.executedPrice}' : ''} ✓'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      _loadPositions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('ApiException: ', '')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _closePosition(TradingPosition p) async {
    final acc = Mt5AccountStore.instance.active;
    if (acc == null) return;
    try {
      await TradingRepository.instance
          .closePosition(accountId: acc.id, ticket: p.ticket);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Position #${p.ticket} closed'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      _loadPositions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('ApiException: ', '')),
        backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final store = context.watch<Mt5AccountStore>();
    final acc = store.active;

    return SafeArea(
      bottom: false,
      child: Column(children: [
        // ── CFDs | Copy header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Expanded(
              child: VTextTabs(
                tabs: const ['CFDs', 'Copy'],
                selected: _topTab, big: true,
                onTap: (i) => setState(() => _topTab = i),
              ),
            ),
            Consumer<WebSocketService>(
              builder: (_, ws, __) => Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ws.isConnected ? AppColors.bullish : AppColors.warning,
                ),
              ),
            ),
          ]),
        ),

        Expanded(
          child: _topTab == 1
              ? const CopyTradingScreen()
              : ListView(
                  padding: const EdgeInsets.only(bottom: 110),
                  children: [
                    const SizedBox(height: 12),

                    // ── Account chip ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppColors.bg300,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(acc == null ? '—' : (acc.isReal ? 'Live' : 'Demo'),
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
                                    color: acc?.isReal == false
                                        ? const Color(0xFF7C5CFF)
                                        : AppColors.primary)),
                            const SizedBox(width: 6),
                            Text(acc == null ? 'No account' : acc.login,
                                style: const TextStyle(fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const Icon(Icons.arrow_drop_down_rounded,
                                size: 20, color: AppColors.textMuted),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // ── Symbol row ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        GestureDetector(
                          onTap: _pickSymbol,
                          child: Row(children: [
                            Text(_selectedPair,
                                style: const TextStyle(fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                            const Icon(Icons.arrow_drop_down_rounded,
                                size: 26, color: AppColors.textPrimary),
                          ]),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(() => _chartOpen = !_chartOpen),
                          icon: Icon(Icons.insert_chart_outlined_rounded,
                              color: _chartOpen ? AppColors.primary : AppColors.textPrimary),
                        ),
                      ]),
                    ),

                    // ── Chart (expandable) ─────────────────────────────
                    if (_chartOpen) ...[
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            for (final t in _tfs)
                              GestureDetector(
                                onTap: () => setState(() => _selectedTf = t),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(horizontal: 13),
                                  decoration: BoxDecoration(
                                    color: t == _selectedTf
                                        ? AppColors.bg300 : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(t,
                                      style: TextStyle(fontSize: 13.5,
                                          fontWeight: t == _selectedTf
                                              ? FontWeight.w800 : FontWeight.w500,
                                          color: t == _selectedTf
                                              ? AppColors.textPrimary
                                              : AppColors.textMuted)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 300,
                        child: CandleChart(symbol: _selectedPair, timeframe: _selectedTf),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // ── Sell/Buy split ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Consumer<WebSocketService>(builder: (_, ws, __) {
                        final tick = ws.tickFor(_selectedPair);
                        final spreadTxt = tick?.formattedSpread ?? '—';
                        return Column(children: [
                          Stack(alignment: Alignment.center, children: [
                            Row(children: [
                              Expanded(
                                child: _SideButton(
                                  label: 'Sell',
                                  price: tick?.formattedBid ?? '—',
                                  selected: !_isBuy,
                                  color: AppColors.bearish,
                                  left: true,
                                  onTap: () => setState(() => _isBuy = false),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: _SideButton(
                                  label: 'Buy',
                                  price: tick?.formattedAsk ?? '—',
                                  selected: _isBuy,
                                  color: AppColors.bullish,
                                  left: false,
                                  onTap: () => setState(() => _isBuy = true),
                                ),
                              ),
                            ]),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [BoxShadow(
                                    color: Color(0x14000000), blurRadius: 6)],
                              ),
                              child: Text(spreadTxt,
                                  style: const TextStyle(fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          // sentiment bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: SizedBox(
                              height: 4,
                              child: Row(children: [
                                Expanded(
                                    flex: (_sentiment * 100).round().clamp(1, 99),
                                    child: Container(color: AppColors.bullish)),
                                const SizedBox(width: 2),
                                Expanded(
                                    flex: (100 - (_sentiment * 100).round()).clamp(1, 99),
                                    child: Container(color: AppColors.bearish)),
                              ]),
                            ),
                          ),
                        ]);
                      }),
                    ),
                    const SizedBox(height: 14),

                    // ── Order type ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: VCard(
                        onTap: _pickOrderType,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        color: AppColors.bg300,
                        child: Row(children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 17, color: AppColors.textMuted),
                          Expanded(
                            child: Text(_orderType,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded,
                              color: AppColors.textMuted),
                        ]),
                      ),
                    ),

                    if (_orderType != 'Market') ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: VCard(
                          color: AppColors.bg300,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                            decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Trigger price',
                                hintStyle: TextStyle(color: AppColors.textMuted,
                                    fontWeight: FontWeight.w400)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // ── Volume stepper ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.bg300,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: .55)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Row(children: [
                          IconButton(
                            onPressed: () => setState(() =>
                                _lots = (_lots - 0.01).clamp(0.01, 100)),
                            icon: const Icon(Icons.remove_rounded,
                                color: AppColors.textSecondary),
                          ),
                          Expanded(
                            child: Column(children: [
                              const Text('Volume',
                                  style: TextStyle(fontSize: 12,
                                      color: AppColors.textMuted)),
                              Text(_lots.toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary)),
                            ]),
                          ),
                          IconButton(
                            onPressed: () => setState(() =>
                                _lots = (_lots + 0.01).clamp(0.01, 100)),
                            icon: const Icon(Icons.add_rounded,
                                color: AppColors.textSecondary),
                          ),
                          Container(width: 1, height: 30, color: AppColors.border),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Lots',
                                style: TextStyle(fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2.5,
                          activeTrackColor: AppColors.textPrimary,
                          inactiveTrackColor: AppColors.bg400,
                          thumbColor: Colors.white,
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 9, elevation: 3),
                        ),
                        child: Slider(
                          value: _lots.clamp(0.01, 5),
                          min: 0.01, max: 5,
                          onChanged: (v) => setState(() =>
                              _lots = (v * 100).round() / 100),
                        ),
                      ),
                    ),

                    // ── TP/SL ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        SizedBox(
                          width: 24, height: 24,
                          child: Checkbox(
                            value: _tpslOpen,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            onChanged: (v) => setState(() => _tpslOpen = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('TP/SL',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dashed,
                                decorationColor: AppColors.textDisabled)),
                      ]),
                    ),
                    if (_tpslOpen)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(children: [
                          Expanded(
                            child: VCard(
                              color: AppColors.bg300,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                controller: _tpCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                style: const TextStyle(fontSize: 15,
                                    fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Take Profit',
                                    hintStyle: TextStyle(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w400)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: VCard(
                              color: AppColors.bg300,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                controller: _slCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                style: const TextStyle(fontSize: 15,
                                    fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Stop Loss',
                                    hintStyle: TextStyle(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w400)),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    const SizedBox(height: 8),

                    // ── Info rows ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(children: [
                        VInfoRow('Free Margin',
                            acc == null ? '--' : acc.freeMargin.toStringAsFixed(2)),
                        VInfoRow('Margin Level',
                            acc == null || acc.marginLevel == 0
                                ? '--' : '${acc.marginLevel.toStringAsFixed(1)}%'),
                        VInfoRow('Leverage', acc?.leverage ?? '--'),
                      ]),
                    ),
                    const SizedBox(height: 10),

                    // ── CTA ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _placing
                                ? AppColors.bg300
                                : (_isBuy ? AppColors.bullish : AppColors.bearish),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: _placing ? null : _placeOrder,
                            child: Center(
                              child: _placing
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.2, color: AppColors.textMuted))
                                  : Text(
                                      '${_isBuy ? 'Buy' : 'Sell'} ${_lots.toStringAsFixed(2)} Lots',
                                      style: const TextStyle(fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Positions / Pending ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: VTextTabs(
                        tabs: ['Positions(${_positions.length})', 'Pending Orders(0)'],
                        selected: _bottomTab,
                        fontSize: 16,
                        onTap: (i) => setState(() => _bottomTab = i),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_bottomTab == 1 || _positions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                            child: Text('Nothing here yet',
                                style: TextStyle(fontSize: 14,
                                    color: AppColors.textMuted))),
                      )
                    else
                      ..._positions.map((p) => _PositionRow(
                            position: p,
                            onClose: () => _closePosition(p),
                          )),
                  ],
                ),
        ),
      ]),
    );
  }
}

class _SideButton extends StatelessWidget {
  final String label, price;
  final bool selected, left;
  final Color color;
  final VoidCallback onTap;
  const _SideButton({required this.label, required this.price,
      required this.selected, required this.color, required this.left,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: selected ? color : AppColors.bg300,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(left ? 16 : 4),
              right: Radius.circular(left ? 4 : 16),
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label,
                style: TextStyle(fontSize: 13,
                    color: selected ? Colors.white70 : AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(price,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.textPrimary)),
          ]),
        ),
      );
}

class _PositionRow extends StatelessWidget {
  final TradingPosition position;
  final VoidCallback onClose;
  const _PositionRow({required this.position, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final p = position;
    final isBuy = p.side == OrderSide.buy;
    final pc = p.profit >= 0 ? AppColors.bullish : AppColors.bearish;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: VCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(p.symbol,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isBuy ? AppColors.bullishBg : AppColors.bearishBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${isBuy ? 'Buy' : 'Sell'} ${p.lots.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: isBuy ? AppColors.bullish : AppColors.bearish)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('${p.openPrice} → ${p.currentPrice}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${p.profit >= 0 ? '+' : ''}${p.profit.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: pc)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.bg300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Close',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
