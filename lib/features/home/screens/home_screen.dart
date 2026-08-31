import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/services/spark_cache.dart';
import '../../../core/services/watchlist_store.dart';
import '../../../shared/widgets/vantage.dart';
import '../../copy_trading/repository/copy_trading_repository.dart';
import '../../copy_trading/screens/copy_trading_screen.dart';
import '../../deposit/screens/deposit_screen.dart';
import '../../mam_pamm/screens/mam_pamm_screen.dart';
import '../../markets/screens/markets_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../trading/screens/trading_screen.dart';
import '../../funds/screens/funds_screen.dart';

/// V2 shell — Vantage-style floating pill nav over an IndexedStack.
/// Tabs: Home · Markets · Trade · Earn (copy) · Funds
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Debug convenience: --dart-define=DEV_TAB=2 opens straight on Trade.
  int _idx = const int.fromEnvironment('DEV_TAB', defaultValue: 0);

  void switchTab(int index) => setState(() => _idx = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onSwitchTab: switchTab),
      const MarketsScreen(),
      const TradingScreen(),
      const CopyTradingScreen(),
      const FundsScreen(),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg100,
      extendBody: true,
      body: IndexedStack(index: _idx, children: screens),
      bottomNavigationBar: VBottomNav(current: _idx, onTap: (i) => setState(() => _idx = i)),
    );
  }
}

/// Vantage-style Home: Total Value + Deposit pill, quick actions,
/// promo carousel, Best Overall Strategies, watchlist preview.
class HomeScreen extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  const HomeScreen({super.key, this.onSwitchTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  static const _watchSymbols = ['EURUSD', 'GBPUSD', 'XAUUSD', 'BTCUSD', 'USDJPY', 'US30'];
  static const _subtitles = {
    'EURUSD': 'Euro/US Dollar',
    'GBPUSD': 'Pound/US Dollar',
    'XAUUSD': 'Gold/US Dollar',
    'BTCUSD': 'Bitcoin/US Dollar',
    'USDJPY': 'US Dollar/Yen',
    'US30': 'Dow Jones Index',
  };

  List<Map<String, dynamic>> _strategies = [];
  bool _valueHidden = false;
  int _promoPage = 0;
  final _promoCtrl = PageController();
  Timer? _promoTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WatchlistStore.instance.load();
    WatchlistStore.instance.addListener(_onWatchlist);
    _initMarket();
    _loadStrategies();
    for (final s in _watchSymbols) {
      SparkCache.get(s).then((_) {
        if (mounted) setState(() {});
      });
    }
    _promoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_promoCtrl.hasClients) return;
      final next = (_promoPage + 1) % 2;
      _promoCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  void _onWatchlist() {
    if (!mounted) return;
    final syms = WatchlistStore.instance.symbols;
    WebSocketService.instance.subscribe(syms);
    for (final s in syms) {
      SparkCache.get(s).then((_) { if (mounted) setState(() {}); });
    }
    setState(() {});
  }

  @override
  void dispose() {
    WatchlistStore.instance.removeListener(_onWatchlist);
    _promoTimer?.cancel();
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _initMarket() async {
    final ws = WebSocketService.instance;
    if (!ws.isConnected) await ws.connect();
    ws.subscribe(_watchSymbols);
  }

  Future<void> _loadStrategies() async {
    try {
      final top = await CopyTradingRepository.instance.getTopTraders();
      if (mounted) setState(() => _strategies = top.traders);
    } catch (_) {/* strategies section just stays empty */}
  }

  String _fmtMoney(double v) {
    final s = v.abs().toStringAsFixed(2);
    final parts = s.split('.');
    final b = StringBuffer();
    final digits = parts[0];
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
      b.write(digits[i]);
    }
    return '${v < 0 ? '-' : ''}$b.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final store = context.watch<Mt5AccountStore>();
    final acc = store.active;
    final totalValue = acc?.equity ?? 0;
    final pnl = acc?.openPL ?? 0;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Mt5AccountStore.instance.loadAccounts();
          await _loadStrategies();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            // ── Top bar: avatar + search + messages ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: Container(
                    width: 38, height: 38,
                    decoration: const BoxDecoration(
                        color: AppColors.bg300, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Text('🦏', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => widget.onSwitchTab?.call(1),
                  icon: const Icon(Icons.search_rounded,
                      color: AppColors.textPrimary, size: 26),
                ),
                IconButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  icon: const Icon(Icons.chat_bubble_rounded,
                      color: AppColors.textPrimary, size: 23),
                ),
              ]),
            ),

            // ── Total value + Deposit ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GestureDetector(
                      onTap: () => setState(() => _valueHidden = !_valueHidden),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text('Total Value',
                            style: TextStyle(fontSize: 14, color: AppColors.textMuted,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dashed,
                                decorationColor: AppColors.textDisabled)),
                        const SizedBox(width: 6),
                        Icon(_valueHidden ? Icons.visibility_off_rounded : Icons.remove_red_eye_rounded,
                            size: 15, color: AppColors.textMuted),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Flexible(
                        child: Text(_valueHidden ? '••••' : _fmtMoney(totalValue),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 36, height: 1.05,
                                fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 6, bottom: 5),
                        child: Text('USD',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Icon(Icons.arrow_drop_down_rounded,
                            color: AppColors.textMuted, size: 22),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text("Today's PnL",
                          style: TextStyle(fontSize: 14, color: AppColors.textMuted,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.dashed,
                              decorationColor: AppColors.textDisabled)),
                      const SizedBox(width: 6),
                      Text(_valueHidden ? '••••' : '${_fmtMoney(pnl)} USD',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: pnl == 0
                                  ? AppColors.textPrimary
                                  : (pnl > 0 ? AppColors.bullish : AppColors.bearish))),
                      const Icon(Icons.arrow_drop_down_rounded,
                          color: AppColors.textMuted, size: 20),
                    ]),
                  ]),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DepositScreen())),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 22),
                        child: Center(
                          child: Text('Deposit',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 22),

            // ── Quick actions ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  VQuickAction(
                    icon: Icons.add_rounded, label: 'Deposit',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const DepositScreen())),
                  ),
                  VQuickAction(
                    icon: Icons.remove_rounded, label: 'Withdraw',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const DepositScreen(isWithdraw: true))),
                  ),
                  VQuickAction(
                    icon: Icons.people_alt_rounded, label: 'Copy Trade', badge: 'New',
                    onTap: () => widget.onSwitchTab?.call(3),
                  ),
                  VQuickAction(
                    icon: Icons.account_balance_rounded, label: 'PAMM',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MamPammScreen())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Promo carousel ──────────────────────────────────────────
            SizedBox(
              height: 96,
              child: PageView(
                controller: _promoCtrl,
                onPageChanged: (i) => setState(() => _promoPage = i),
                children: [
                  _PromoCard(
                    emoji: '🏆',
                    title: 'Top Performing\nSignal Providers',
                    page: '${_promoPage + 1} / 2',
                    onTap: () => widget.onSwitchTab?.call(3),
                  ),
                  _PromoCard(
                    emoji: '⏰',
                    title: 'XAUUSD — Trade\nGold Anytime',
                    page: '${_promoPage + 1} / 2',
                    onTap: () => widget.onSwitchTab?.call(2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Best Overall Strategies ─────────────────────────────────
            if (_strategies.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: VSectionHeader('Best Overall Strategies',
                    onMore: () => widget.onSwitchTab?.call(3)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _strategies.length,
                  itemBuilder: (_, i) => _StrategyCard(
                    trader: _strategies[i],
                    onTap: () => widget.onSwitchTab?.call(3),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Watchlist preview ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VSectionHeader('Watchlist', onMore: () => widget.onSwitchTab?.call(1)),
            ),
            const SizedBox(height: 4),
            Consumer<WebSocketService>(
              builder: (_, ws, __) => Column(
                children: [
                  for (final sym in (WatchlistStore.instance.symbols.isEmpty
                      ? _watchSymbols
                      : WatchlistStore.instance.symbols))
                    Builder(builder: (context) {
                      final tick = ws.tickFor(sym);
                      final spark = SparkCache.peek(sym) ?? const <double>[];
                      final pct = tick?.changePct ?? 0;
                      return SymbolRow(
                        symbol: sym,
                        subtitle: _subtitles[sym] ?? sym,
                        price: tick?.formattedBid ?? '—',
                        changePct: pct,
                        spark: spark,
                        marketClosed: tick?.isStale ?? false,
                        onTap: () {
                          TradingScreen.selectSymbol(sym);
                          widget.onSwitchTab?.call(2);
                        },
                      );
                    }),
                ],
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => widget.onSwitchTab?.call(1),
                child: const Text('View More  ›',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String page;
  final VoidCallback onTap;
  const _PromoCard({required this.emoji, required this.title, required this.page, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: VCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 16.5, height: 1.25,
                          fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  const Text('View more',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            Text(page, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
      );
}

class _StrategyCard extends StatelessWidget {
  final Map<String, dynamic> trader;
  final VoidCallback onTap;
  const _StrategyCard({required this.trader, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = trader['color'] as Color? ?? AppColors.primary;
    final roi = (trader['roi'] as String?) ?? '+0.0%';
    final up = !roi.startsWith('-');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 236,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text((trader['avatar'] as String?) ?? '?',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((trader['name'] as String?) ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bg300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text((trader['risk'] as String?) ?? 'CFD',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ),
              ]),
            ),
          ]),
          const Spacer(),
          const Text('30D Return',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(roi,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800,
                  color: up ? AppColors.bullish : AppColors.bearish)),
        ]),
      ),
    );
  }
}
