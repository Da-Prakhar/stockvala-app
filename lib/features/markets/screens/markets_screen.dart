import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../../trading/models/trading_models.dart';
import '../../trading/repository/trading_repository.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});
  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  String _search = '';
  String _cat = 'All';
  bool _searchOpen = false;
  StreamSubscription<QuoteTick>? _tickSub;
  final Map<String, QuoteTick> _liveTicks = {};

  static const _cats = ['All', 'Forex', 'Metals', 'Crypto', 'Indices', 'Energy'];

  static const _symbolConfig = [
    {'sym':'EUR/USD','bid':'1.1517','ask':'1.1526','change':'-0.77%','pips':'-89 pts','bull':false,'cat':'Forex',  'spread':'0.9','high':'1.1643','low':'1.1511','icon':'🇪🇺'},
    {'sym':'GBP/USD','bid':'1.3339','ask':'1.3342','change':'-0.60%','pips':'-80 pts','bull':false,'cat':'Forex',  'spread':'0.3','high':'1.3482','low':'1.3329','icon':'🇬🇧'},
    {'sym':'USD/JPY','bid':'160.21','ask':'160.37','change':'+0.13%','pips':'+21 pts','bull':true, 'cat':'Forex',  'spread':'1.6','high':'160.33','low':'159.71','icon':'🇯🇵'},
    {'sym':'AUD/USD','bid':'0.7038','ask':'0.7045','change':'-1.31%','pips':'-93 pts','bull':false,'cat':'Forex',  'spread':'0.7','high':'0.7142','low':'0.7036','icon':'🇦🇺'},
    {'sym':'USD/CAD','bid':'1.3930','ask':'1.3947','change':'+0.19%','pips':'+26 pts','bull':true, 'cat':'Forex',  'spread':'1.7','high':'1.3948','low':'1.3865','icon':'🇨🇦'},
    {'sym':'USD/CHF','bid':'0.7957','ask':'0.7968','change':'+0.97%','pips':'+77 pts','bull':true, 'cat':'Forex',  'spread':'1.1','high':'0.7966','low':'0.7870','icon':'🇨🇭'},
    {'sym':'XAU/USD','bid':'4329.43','ask':'4329.67','change':'-3.38%','pips':'-151 pts','bull':false,'cat':'Metals','spread':'0.2','high':'4475.85','low':'4311.77','icon':'🥇'},
    {'sym':'XAG/USD','bid':'67.81','ask':'67.84','change':'-8.26%','pips':'-610 pts','bull':false,'cat':'Metals','spread':'0.3','high':'74.13','low':'67.56','icon':'🥈'},
    {'sym':'XPT/USD','bid':'1770.02','ask':'1790.22','change':'-6.62%','pips':'-125 pts','bull':false,'cat':'Metals','spread':'20.2','high':'1903.93','low':'1770.02','icon':'⚪'},
    {'sym':'BTC/USD','bid':'60657','ask':'60658','change':'-1.55%','pips':'-955 pts','bull':false,'cat':'Crypto', 'spread':'1.0','high':'61758','low':'59758','icon':'₿'},
    {'sym':'ETH/USD','bid':'3842.10','ask':'3845.40','change':'+0.32%','pips':'+12 pts','bull':true, 'cat':'Crypto', 'spread':'3.3','high':'3890.00','low':'3800.00','icon':'Ξ'},
    {'sym':'US30','bid':'39421','ask':'39431','change':'+0.44%','pips':'+174 pts','bull':true, 'cat':'Indices','spread':'1.0','high':'39500','low':'39200','icon':'🇺🇸'},
    {'sym':'SPX500','bid':'5241.2','ask':'5243.4','change':'+0.28%','pips':'+15 pts','bull':true, 'cat':'Indices','spread':'0.2','high':'5260','low':'5200','icon':'📈'},
    {'sym':'GER40','bid':'18320.5','ask':'18325.5','change':'-0.18%','pips':'-33 pts','bull':false,'cat':'Indices','spread':'0.5','high':'18400','low':'18280','icon':'🇩🇪'},
    {'sym':'WTI Oil','bid':'78.42','ask':'78.45','change':'-0.67%','pips':'-53 pts','bull':false,'cat':'Energy', 'spread':'0.3','high':'79.20','low':'77.80','icon':'🛢️'},
  ];

  static String _wsKey(String sym) => sym.replaceAll('/', '');

  List<Map<String, dynamic>> get _filtered {
    return _symbolConfig.where((q) {
      final matchCat = _cat == 'All' || q['cat'] == _cat;
      final matchSearch = _search.isEmpty || (q['sym'] as String).toLowerCase().contains(_search.toLowerCase());
      return matchCat && matchSearch;
    }).map((q) {
      final tick = _liveTicks[_wsKey(q['sym'] as String)];
      if (tick == null) return Map<String, dynamic>.from(q);
      return {
        ...q,
        'bid': tick.formattedBid,
        'ask': tick.formattedAsk,
        'change': tick.formattedChange,
        'pips': tick.formattedPips,
        'bull': tick.isBullish,
        'spread': tick.spread.toStringAsFixed(1),
        'high': tick.high > 0 ? tick.high.toString() : q['high'],
        'low': tick.low > 0 ? tick.low.toString() : q['low'],
      };
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _fetchPriceSnapshot();
  }

  Future<void> _fetchPriceSnapshot() async {
    try {
      final wsSymbols = _symbolConfig.map((q) => _wsKey(q['sym'] as String)).join(',');
      final res = await ApiClient.instance.get('/public/prices?symbols=$wsSymbols');
      final body = res.data as Map<String, dynamic>;
      final list = (body['data'] as List<dynamic>?) ?? [];
      if (!mounted) return;
      setState(() {
        for (final item in list) {
          final j = item as Map<String, dynamic>;
          final sym = (j['symbol'] as String? ?? '').toUpperCase();
          if (sym.isEmpty) continue;
          final bid = (j['bid'] as num? ?? 0).toDouble();
          final ask = (j['ask'] as num? ?? bid).toDouble();
          if (bid <= 0) continue;
          _liveTicks[sym] = QuoteTick(
            sym: sym, bid: bid, ask: ask,
            spread: ask - bid, high: bid, low: bid,
            ts: ((j['t'] as num?)?.toInt() ?? 0) * 1000,
          );
        }
      });
    } catch (e) {
      debugPrint('[Markets] price snapshot fetch failed: $e');
    }
  }

  void _connectWebSocket() {
    final ws = WebSocketService.instance;
    final symbols = _symbolConfig.map((q) => q['sym'] as String).toList();
    ws.subscribe(symbols);
    for (final sym in symbols) {
      final existing = ws.tickFor(sym);
      if (existing != null) _liveTicks[_wsKey(sym)] = existing;
    }
    _tickSub = ws.tickStream.listen((tick) {
      if (mounted) setState(() => _liveTicks[tick.sym] = tick);
    });
  }

  @override
  void dispose() {
    _tickSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final wsConnected = context.watch<WebSocketService>().isConnected;

    int upCount = 0, downCount = 0;
    for (final q in _symbolConfig) {
      final tick = _liveTicks[_wsKey(q['sym'] as String)];
      final isBull = tick?.isBullish ?? (q['bull'] as bool);
      if (isBull) { upCount++; } else { downCount++; }
    }

    return Scaffold(
      backgroundColor: AppColors.bg100,
      body: Column(children: [
        // ─── Header ──────────────────────────────────────────────────────────
        Container(
          color: AppColors.bg100,
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
          child: Column(children: [
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Markets', style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 3),
                Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: wsConnected ? AppColors.success : AppColors.warning,
                      shape: BoxShape.circle,
                      boxShadow: wsConnected
                        ? [BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 5, spreadRadius: 1)]
                        : [],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    wsConnected ? 'Live' : 'Connecting...',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: wsConnected ? AppColors.success : AppColors.warning)),
                ]),
              ]),
              const Spacer(),
              // Market stats
              _StatPill(label: '↑ $upCount', color: AppColors.bullish),
              const SizedBox(width: 8),
              _StatPill(label: '↓ $downCount', color: AppColors.bearish),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _searchOpen = !_searchOpen),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _searchOpen ? AppColors.primary : AppColors.bg300,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _searchOpen ? AppColors.primary : AppColors.border),
                  ),
                  child: Icon(Icons.search_rounded,
                    color: _searchOpen ? Colors.white : AppColors.textMuted, size: 20),
                ),
              ),
            ]),
            // Search
            if (_searchOpen) ...[
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search EUR/USD, Gold, BTC...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                  suffixIcon: _search.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() => _search = ''),
                        child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted))
                    : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true, fillColor: AppColors.bg400,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Pill category tabs
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _cats.length,
                padding: EdgeInsets.zero,
                itemBuilder: (_, i) {
                  final selected = _cat == _cats[i];
                  return GestureDetector(
                    onTap: () => setState(() => _cat = _cats[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(right: i < _cats.length - 1 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.bg300,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                        boxShadow: selected
                          ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]
                          : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(_cats[i],
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AppColors.textMuted)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ]),
        ),

        // ─── Column labels ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(72, 0, 16, 6),
          child: Row(children: [
            const Expanded(child: Text('SYMBOL',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: AppColors.textMuted, letterSpacing: 0.8))),
            SizedBox(width: 86, child: Center(child: Text('BID',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.bearish.withValues(alpha: 0.7), letterSpacing: 0.8)))),
            const SizedBox(width: 1),
            SizedBox(width: 86, child: Center(child: Text('ASK',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.bullish.withValues(alpha: 0.7), letterSpacing: 0.8)))),
            const SizedBox(width: 8),
          ]),
        ),

        // ─── Quote list ───────────────────────────────────────────────────────
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: _filtered.length,
          itemBuilder: (_, i) => _QuoteCard(
            quote: _filtered[i],
            index: i,
            onBuy: () => _showTradeSheet(context, _filtered[i], true),
            onSell: () => _showTradeSheet(context, _filtered[i], false),
          ),
        )),
      ]),
    );
  }

  void _showTradeSheet(BuildContext context, Map<String, dynamic> q, bool isBuy) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _QuickTradeSheet(quote: q, isBuy: isBuy),
    );
  }
}

// ── Stat pill in header ───────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Text(label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
  );
}

// ── QUOTE CARD — BID/ASK terminal style ──────────────────────────────────────
class _QuoteCard extends StatelessWidget {
  final Map<String, dynamic> quote;
  final int index;
  final VoidCallback onBuy, onSell;
  const _QuoteCard({required this.quote, required this.index, required this.onBuy, required this.onSell});

  @override
  Widget build(BuildContext context) {
    final bull   = quote['bull'] as bool;
    final accent = bull ? AppColors.bullish : AppColors.bearish;
    final change = quote['change'] as String;

    return GestureDetector(
      onTap: () => _showDetail(context, quote),
      child: Container(
        height: 76,
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // Subtle directional tint from the left accent
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.06),
              AppColors.bg300,
            ],
            stops: const [0.0, 0.28],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Left accent stripe ──────────────────────────────────────
          Container(width: 3, color: accent),

          const SizedBox(width: 14),

          // ── Round icon avatar ───────────────────────────────────────
          Center(child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Text(quote['icon'] as String, style: const TextStyle(fontSize: 20)),
          )),

          const SizedBox(width: 12),

          // ── Symbol + change ─────────────────────────────────────────
          Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quote['sym'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                )),
              const SizedBox(height: 5),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  bull ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 11, color: accent),
                const SizedBox(width: 2),
                Text(change,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
              ]),
            ],
          )),

          // ── BID column (tap = sell) ─────────────────────────────────
          GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); onSell(); },
            child: Container(
              width: 86,
              color: Colors.transparent,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('BID',
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.bearish.withValues(alpha: 0.65),
                    letterSpacing: 1.2,
                  )),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(quote['bid'] as String,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: AppColors.bearish, letterSpacing: -0.3)),
                ),
              ]),
            ),
          ),

          // ── Separator ──────────────────────────────────────────────
          Center(child: Container(width: 1, height: 30, color: AppColors.border)),

          // ── ASK column (tap = buy) ──────────────────────────────────
          GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); onBuy(); },
            child: Container(
              width: 86,
              color: Colors.transparent,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('ASK',
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.bullish.withValues(alpha: 0.65),
                    letterSpacing: 1.2,
                  )),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(quote['ask'] as String,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: AppColors.bullish, letterSpacing: -0.3)),
                ),
              ]),
            ),
          ),

          const SizedBox(width: 8),
        ]),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 35)).slideX(begin: 0.05, end: 0);
  }

  void _showDetail(BuildContext context, Map<String, dynamic> q) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(quote: q),
    );
  }
}

// ── DETAIL SHEET ──────────────────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final Map<String, dynamic> quote;
  const _DetailSheet({required this.quote});

  @override
  Widget build(BuildContext context) {
    final bull = quote['bull'] as bool;
    final accentColor = bull ? AppColors.bullish : AppColors.bearish;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg200,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        // Header
        Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: Text(quote['icon'] as String, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(quote['sym'] as String, style: AppTextStyles.headingMedium),
            const SizedBox(height: 2),
            Text(quote['cat'] as String, style: AppTextStyles.caption),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(bull ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: accentColor, size: 14),
              const SizedBox(width: 4),
              Text(quote['change'] as String,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accentColor)),
            ]),
          ),
        ]),
        const SizedBox(height: 20),

        // Price panel
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bg300,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _DRow('BID', quote['bid'] as String, AppColors.bearish),
              _DRow('SPREAD', '${quote['spread']} pts', AppColors.textMuted),
              _DRow('ASK', quote['ask'] as String, AppColors.bullish),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Text(quote['low'] as String, style: AppTextStyles.caption),
              const SizedBox(width: 8),
              Expanded(child: Stack(children: [
                Container(height: 5,
                  decoration: BoxDecoration(color: AppColors.bg400, borderRadius: BorderRadius.circular(3))),
                FractionallySizedBox(
                  widthFactor: 0.62,
                  child: Container(height: 5,
                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(3))),
                ),
              ])),
              const SizedBox(width: 8),
              Text(quote['high'] as String, style: AppTextStyles.caption),
            ]),
            const SizedBox(height: 4),
            const Center(child: Text('Day Range',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.6))),
          ]),
        ),
        const SizedBox(height: 20),

        Row(children: [
          Expanded(child: _TradeBtn(
            label: 'SELL', price: quote['bid'] as String, color: AppColors.bearish,
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (_) => _QuickTradeSheet(quote: quote, isBuy: false));
            },
          )),
          const SizedBox(width: 10),
          Expanded(child: _TradeBtn(
            label: 'BUY', price: quote['ask'] as String, color: AppColors.bullish,
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (_) => _QuickTradeSheet(quote: quote, isBuy: true));
            },
          )),
        ]),
      ]),
    );
  }
}

class _DRow extends StatelessWidget {
  final String l, v; final Color c;
  const _DRow(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(l, style: const TextStyle(fontSize: 10, color: AppColors.textMuted,
      fontWeight: FontWeight.w600, letterSpacing: 0.8)),
    const SizedBox(height: 5),
    Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c)),
  ]);
}

class _TradeBtn extends StatelessWidget {
  final String label, price;
  final Color color;
  final VoidCallback onTap;
  const _TradeBtn({required this.label, required this.price, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.mediumImpact(); onTap(); },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(children: [
        Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: Colors.white70, letterSpacing: 1.5)),
        const SizedBox(height: 5),
        Text(price,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    ),
  );
}

// ── QUICK TRADE SHEET ─────────────────────────────────────────────────────────
class _QuickTradeSheet extends StatefulWidget {
  final Map<String, dynamic> quote;
  final bool isBuy;
  const _QuickTradeSheet({required this.quote, required this.isBuy});
  @override
  State<_QuickTradeSheet> createState() => _QuickTradeSheetState();
}

class _QuickTradeSheetState extends State<_QuickTradeSheet> {
  double _lots = 0.10;
  String _type = 'Market';
  final _slCtrl = TextEditingController();
  final _tpCtrl = TextEditingController();
  bool _executing = false;

  Color get _color => widget.isBuy ? AppColors.bullish : AppColors.bearish;
  String get _price => widget.isBuy ? widget.quote['ask'] as String : widget.quote['bid'] as String;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    final margin = (_lots * 1000).toStringAsFixed(2);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg200,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 18),

        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Text(widget.isBuy ? 'BUY' : 'SELL',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
          ),
          const SizedBox(width: 12),
          Text(widget.quote['sym'] as String, style: AppTextStyles.headingMedium),
          const Spacer(),
          Text(_price,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _color)),
        ]),
        const SizedBox(height: 18),

        // Order type
        Row(children: ['Market', 'Limit', 'Stop'].map((t) => GestureDetector(
          onTap: () => setState(() => _type = t),
          child: AnimatedContainer(
            duration: 150.ms,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _type == t ? AppColors.primaryLighter : AppColors.bg300,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _type == t ? AppColors.primary : AppColors.border),
            ),
            child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: _type == t ? AppColors.primaryLight : AppColors.textMuted)),
          ),
        )).toList()),
        const SizedBox(height: 16),

        // Lot stepper
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bg300, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Row(children: [
              const Text('Volume (Lots)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const Spacer(),
              Text('Margin ≈ \$$margin', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              GestureDetector(
                onTap: () { if (_lots > 0.01) setState(() => _lots = double.parse((_lots - 0.01).toStringAsFixed(2))); HapticFeedback.selectionClick(); },
                child: Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.bg400, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.remove_rounded, color: AppColors.textSecondary, size: 20)),
              ),
              Expanded(child: Center(child: Text(_lots.toStringAsFixed(2),
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textPrimary)))),
              GestureDetector(
                onTap: () { if (_lots < 100) setState(() => _lots = double.parse((_lots + 0.01).toStringAsFixed(2))); HapticFeedback.selectionClick(); },
                child: Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.bg400, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.add_rounded, color: AppColors.textSecondary, size: 20)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [0.01, 0.05, 0.10, 0.50, 1.00].map((v) => Expanded(child: GestureDetector(
              onTap: () { setState(() => _lots = v); HapticFeedback.selectionClick(); },
              child: AnimatedContainer(
                duration: 120.ms,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _lots == v ? AppColors.primaryLighter : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _lots == v ? AppColors.primary : AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text(v.toStringAsFixed(v < 1 ? 2 : 0),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _lots == v ? AppColors.primaryLight : AppColors.textMuted)),
              ),
            ))).toList()),
          ]),
        ),
        const SizedBox(height: 10),

        Row(children: [
          Expanded(child: _SLTPField(label: 'Stop Loss', hint: 'Optional', ctrl: _slCtrl, color: AppColors.bearish)),
          const SizedBox(width: 10),
          Expanded(child: _SLTPField(label: 'Take Profit', hint: 'Optional', ctrl: _tpCtrl, color: AppColors.bullish)),
        ]),
        const SizedBox(height: 18),

        GestureDetector(
          onTap: _executing ? null : _executeOrder,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: _executing ? _color.withValues(alpha: 0.6) : _color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _executing ? [] : [
                BoxShadow(color: _color.withValues(alpha: 0.40), blurRadius: 20, offset: const Offset(0, 6))
              ],
            ),
            child: _executing
              ? const Center(child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(widget.isBuy ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('${widget.isBuy ? 'BUY' : 'SELL'} ${_lots.toStringAsFixed(2)} lots',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(width: 12),
                  Text('@ $_price',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _executeOrder() async {
    final account = Mt5AccountStore.instance.active;
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No active MT5 account. Please link an account first.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    HapticFeedback.heavyImpact();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _executing = true);
    try {
      final sl = double.tryParse(_slCtrl.text);
      final tp = double.tryParse(_tpCtrl.text);
      final result = await TradingRepository.instance.placeOrder(OrderRequest(
        accountId: account.id,
        symbol: widget.quote['sym'] as String,
        type: OrderTypeExt.from(_type.toLowerCase()),
        side: widget.isBuy ? OrderSide.buy : OrderSide.sell,
        lots: _lots, stopLoss: sl, takeProfit: tp,
      ));
      if (mounted) {
        setState(() => _executing = false);
        nav.pop();
        messenger.showSnackBar(SnackBar(
          content: Row(children: [
            Icon(widget.isBuy ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(result.isFilled
              ? '${widget.isBuy ? 'BUY' : 'SELL'} ${_lots.toStringAsFixed(2)} lots ${widget.quote['sym']} @ ${result.executedPrice} — Ticket #${result.ticket}'
              : result.message ?? 'Order placed')),
          ]),
          backgroundColor: result.isFilled ? _color : AppColors.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _executing = false);
        messenger.showSnackBar(SnackBar(
          content: Text('Order failed: ${e.toString().replaceAll('ApiException', '').trim()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  void dispose() {
    _slCtrl.dispose(); _tpCtrl.dispose();
    super.dispose();
  }
}

class _SLTPField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final Color color;
  const _SLTPField({required this.label, required this.hint, required this.ctrl, required this.color});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      filled: true, fillColor: AppColors.bg300,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color.withValues(alpha: 0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: 1.5)),
      isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}
