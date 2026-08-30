import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/services/watchlist_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/vantage.dart';

/// "Add to Watchlist" — search + category tabs + star toggles.
/// Curated instruments first; the broker's full symbol list merges in
/// from GET /trades/symbols so anything tradeable can be starred.
class AddWatchlistScreen extends StatefulWidget {
  const AddWatchlistScreen({super.key});
  @override
  State<AddWatchlistScreen> createState() => _AddWatchlistScreenState();
}

class _AddWatchlistScreenState extends State<AddWatchlistScreen> {
  String _search = '';
  String _cat = 'All';
  List<Map<String, String>> _rows = [];
  bool _loadingServer = true;

  static const _cats = ['All', 'Forex', 'Metals', 'Crypto', 'Indices', 'Energy'];

  static const _curated = [
    {'sym': 'EURUSD', 'name': 'Euro/US Dollar', 'cat': 'Forex'},
    {'sym': 'GBPUSD', 'name': 'Pound/US Dollar', 'cat': 'Forex'},
    {'sym': 'USDJPY', 'name': 'US Dollar/Yen', 'cat': 'Forex'},
    {'sym': 'AUDUSD', 'name': 'Aussie/US Dollar', 'cat': 'Forex'},
    {'sym': 'USDCAD', 'name': 'US Dollar/Loonie', 'cat': 'Forex'},
    {'sym': 'USDCHF', 'name': 'US Dollar/Franc', 'cat': 'Forex'},
    {'sym': 'NZDUSD', 'name': 'Kiwi/US Dollar', 'cat': 'Forex'},
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
  void initState() {
    super.initState();
    _rows = _curated.map((e) => e.cast<String, String>()).toList();
    _loadServerSymbols();
  }

  String _guessCat(String s) {
    if (RegExp(r'^(XAU|XAG|XPT|XPD)').hasMatch(s)) return 'Metals';
    if (RegExp(r'^(BTC|ETH|LTC|XRP|SOL|ADA|DOGE)').hasMatch(s)) return 'Crypto';
    if (RegExp(r'(US30|SPX|NAS|US100|GER|DAX|UK100|FTSE|JPN|NIK|HK50|AUS200)')
        .hasMatch(s)) return 'Indices';
    if (RegExp(r'(OIL|XTI|XBR|BRENT|WTI|NGAS)').hasMatch(s)) return 'Energy';
    return 'Forex';
  }

  Future<void> _loadServerSymbols() async {
    try {
      final res = await ApiClient.instance.get('/trades/symbols');
      final syms = (res.data?['data']?['symbols'] as List? ?? []);
      final known = _rows.map((r) => r['sym']).toSet();
      final extra = <Map<String, String>>[];
      for (final e in syms) {
        final raw = e is String ? e : (e as Map)['name']?.toString() ?? '';
        final base = raw.replaceAll(RegExp(r'\.[^.]*$'), '').toUpperCase();
        if (base.isEmpty || known.contains(base)) continue;
        known.add(base);
        extra.add({'sym': base, 'name': raw, 'cat': _guessCat(base)});
      }
      extra.sort((a, b) => a['sym']!.compareTo(b['sym']!));
      if (mounted) {
        setState(() {
          _rows = [..._rows, ...extra];
          _loadingServer = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingServer = false);
    }
  }

  List<Map<String, String>> get _visible {
    Iterable<Map<String, String>> rows = _rows;
    if (_cat != 'All') rows = rows.where((r) => r['cat'] == _cat);
    if (_search.isNotEmpty) {
      final s = _search.toUpperCase();
      rows = rows.where((r) =>
          r['sym']!.contains(s) || r['name']!.toUpperCase().contains(s));
    }
    return rows.toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = WatchlistStore.instance;
    final rows = _visible;
    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: AppBar(
        backgroundColor: AppColors.bg100,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: const Text('Add to Watchlist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) => Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
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
                if (_loadingServer)
                  const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textMuted)),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: VTextTabs(
                tabs: _cats,
                selected: _cats.indexOf(_cat),
                onTap: (i) => setState(() => _cat = _cats[i]),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 30),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                final sym = r['sym']!;
                final starred = store.contains(sym);
                final tick = WebSocketService.instance.tickFor(sym);
                return InkWell(
                  onTap: () => store.toggle(sym),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Icon(
                        starred ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: starred ? AppColors.gold : AppColors.textDisabled,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      SymbolAvatar(sym, size: 38),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sym,
                                  style: const TextStyle(fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 1),
                              Text(r['name']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5,
                                      color: AppColors.textMuted)),
                            ]),
                      ),
                      if (tick != null)
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(tick.formattedBid,
                              style: const TextStyle(fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                          Text(tick.formattedChange,
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tick.isBullish
                                      ? AppColors.bullish : AppColors.bearish)),
                        ]),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
