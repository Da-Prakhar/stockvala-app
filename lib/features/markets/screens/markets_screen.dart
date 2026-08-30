import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/services/spark_cache.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/vantage.dart';
import '../../trading/screens/trading_screen.dart';

/// V2 Markets — Vantage "Watchlist | Explore" layout over the live feed.
class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});
  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen>
    with AutomaticKeepAliveClientMixin {
  int _tab = 1; // 0 Watchlist · 1 Explore (Vantage default highlights Explore)
  String _cat = 'All';
  String _search = '';
  bool _searchOpen = false;
  StreamSubscription<QuoteTick>? _tickSub;
  final Map<String, QuoteTick> _liveTicks = {};
  final Set<String> _favorites = {'EURUSD', 'XAUUSD', 'BTCUSD'};

  static const _cats = ['All', 'Forex', 'Metals', 'Crypto', 'Indices', 'Energy'];

  // Curated instrument list (name → display data); live prices overlay it.
  static const _symbolConfig = [
    {'sym': 'EURUSD', 'name': 'Euro/US Dollar', 'cat': 'Forex'},
    {'sym': 'GBPUSD', 'name': 'Pound/US Dollar', 'cat': 'Forex'},
    {'sym': 'USDJPY', 'name': 'US Dollar/Yen', 'cat': 'Forex'},
    {'sym': 'AUDUSD', 'name': 'Aussie/US Dollar', 'cat': 'Forex'},
    {'sym': 'USDCAD', 'name': 'US Dollar/Loonie', 'cat': 'Forex'},
    {'sym': 'USDCHF', 'name': 'US Dollar/Franc', 'cat': 'Forex'},
    {'sym': 'XAUUSD', 'name': 'Gold/US Dollar', 'cat': 'Metals'},
    {'sym': 'XAGUSD', 'name': 'Silver/US Dollar', 'cat': 'Metals'},
    {'sym': 'XPTUSD', 'name': 'Platinum/US Dollar', 'cat': 'Metals'},
    {'sym': 'BTCUSD', 'name': 'Bitcoin/US Dollar', 'cat': 'Crypto'},
    {'sym': 'ETHUSD', 'name': 'Ethereum/US Dollar', 'cat': 'Crypto'},
    {'sym': 'US30', 'name': 'Dow Jones Index Cash', 'cat': 'Indices'},
    {'sym': 'SPX500', 'name': 'S&P Index Cash CFD', 'cat': 'Indices'},
    {'sym': 'GER40', 'name': 'GER40 Cash', 'cat': 'Indices'},
    {'sym': 'USOIL', 'name': 'WTI Crude Oil', 'cat': 'Energy'},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _connect();
    _fetchSnapshot();
    for (final q in _symbolConfig) {
      SparkCache.get(q['sym']!).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _connect() {
    final ws = WebSocketService.instance;
    final symbols = _symbolConfig.map((q) => q['sym']!).toList();
    ws.subscribe(symbols);
    for (final sym in symbols) {
      final t = ws.tickFor(sym);
      if (t != null) _liveTicks[sym] = t;
    }
    _tickSub = ws.tickStream.listen((tick) {
      if (mounted && _liveTicks.containsKey(tick.sym) ||
          _symbolConfig.any((q) => q['sym'] == tick.sym)) {
        if (mounted) setState(() => _liveTicks[tick.sym] = tick);
      }
    });
  }

  Future<void> _fetchSnapshot() async {
    try {
      final syms = _symbolConfig.map((q) => q['sym']!).join(',');
      final res = await ApiClient.instance.get('/public/prices?symbols=$syms');
      final list = (res.data?['data'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        for (final item in list.whereType<Map>()) {
          final sym = (item['symbol'] as String? ?? '').toUpperCase();
          final bid = (item['bid'] as num? ?? 0).toDouble();
          if (sym.isEmpty || bid <= 0 || _liveTicks.containsKey(sym)) continue;
          final ask = (item['ask'] as num? ?? bid).toDouble();
          _liveTicks[sym] = QuoteTick(
            sym: sym, bid: bid, ask: ask, spread: ask - bid,
            high: bid, low: bid,
            ts: ((item['t'] as num?)?.toInt() ?? 0) * 1000,
          );
        }
      });
    } catch (_) {/* socket fills in */}
  }

  @override
  void dispose() {
    _tickSub?.cancel();
    super.dispose();
  }

  List<Map<String, String>> get _visible {
    Iterable<Map<String, String>> rows =
        _symbolConfig.map((e) => e.cast<String, String>());
    if (_tab == 0) rows = rows.where((q) => _favorites.contains(q['sym']));
    if (_cat != 'All') rows = rows.where((q) => q['cat'] == _cat);
    if (_search.isNotEmpty) {
      final s = _search.toUpperCase();
      rows = rows.where((q) =>
          q['sym']!.contains(s) || q['name']!.toUpperCase().contains(s));
    }
    return rows.toList();
  }

  void _openTrade(String symbol) {
    TradingScreen.selectSymbol(symbol);
    // Trade is tab index 2 in the shell — walk up via DefaultTabController-free path:
    // MainShell exposes switching through the bottom nav only, so just push a
    // lightweight full-screen trade view for this symbol.
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(
              backgroundColor: AppColors.bg100,
              appBar: AppBar(
                backgroundColor: AppColors.bg100,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                title: Text(symbol,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              body: const TradingScreen(),
            )));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    context.watch<WebSocketService>();
    final rows = _visible;

    return SafeArea(
      bottom: false,
      child: Column(children: [
        // ── Header: Watchlist | Explore + search ─────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
          child: Row(children: [
            Expanded(
              child: VTextTabs(
                tabs: const ['Watchlist', 'Explore'],
                selected: _tab, big: true,
                onTap: (i) => setState(() => _tab = i),
              ),
            ),
            IconButton(
              onPressed: () => setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) _search = '';
              }),
              icon: Icon(_searchOpen ? Icons.close_rounded : Icons.search_rounded,
                  color: AppColors.textPrimary, size: 26),
            ),
          ]),
        ),

        if (_searchOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.bg300,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(children: [
                const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Search instruments',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
                    ),
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                  ),
                ),
              ]),
            ),
          ),

        // ── Category tabs ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: VTextTabs(
              tabs: _cats,
              selected: _cats.indexOf(_cat),
              onTap: (i) => setState(() => _cat = _cats[i]),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // ── Rows ─────────────────────────────────────────────────────────
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('⭐', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  Text(_tab == 0 ? 'No favorites yet' : 'No instruments found',
                      style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 110),
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final q = rows[i];
                    final sym = q['sym']!;
                    final tick = _liveTicks[sym] ?? WebSocketService.instance.tickFor(sym);
                    final spark = SparkCache.peek(sym) ?? const <double>[];
                    return GestureDetector(
                      onLongPress: () => setState(() {
                        _favorites.contains(sym)
                            ? _favorites.remove(sym)
                            : _favorites.add(sym);
                      }),
                      child: SymbolRow(
                        symbol: sym,
                        subtitle: q['name']!,
                        price: tick?.formattedBid ?? '—',
                        changePct: tick?.changePct ?? 0,
                        spark: spark,
                        marketClosed: tick?.isStale ?? true,
                        onTap: () => _openTrade(sym),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
