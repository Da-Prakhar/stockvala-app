import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../../../core/network/websocket_service.dart';
import '../../../features/auth/cubit/auth_cubit.dart';
import '../../../features/trading/models/trading_models.dart';
import '../../../features/trading/repository/trading_repository.dart';
import '../../markets/screens/markets_screen.dart';
import '../../trading/screens/trading_screen.dart';
import '../../portfolio/screens/portfolio_screen.dart';
import '../../profile/screens/profile_screen.dart';

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
      const PortfolioScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg100,
      body: IndexedStack(index: _idx, children: screens),
      bottomNavigationBar: _BottomNav(current: _idx, onTap: (i) => setState(() => _idx = i)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded,       'label': 'Home'},
      {'icon': Icons.bar_chart_rounded,  'label': 'Markets'},
      {'icon': Icons.swap_horiz_rounded, 'label': 'Trade'},
      {'icon': Icons.pie_chart_rounded,  'label': 'Portfolio'},
      {'icon': Icons.person_rounded,     'label': 'Profile'},
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg200,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Color(0x408B5CF6), blurRadius: 24, offset: Offset(0, -6))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = i == current;
              if (i == 2) {
                return GestureDetector(
                  onTap: () => onTap(i),
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 26),
                  ),
                );
              }
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryLighter : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item['icon'] as IconData,
                          color: selected ? AppColors.primary : AppColors.textMuted, size: 22),
                    ),
                    const SizedBox(height: 2),
                    Text(item['label'] as String,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: selected ? AppColors.primary : AppColors.textMuted)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── HOME SCREEN ───────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  const HomeScreen({super.key, this.onSwitchTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TradeHistory> _recentTrades = [];
  bool _tradesLoading = true;

  @override
  void initState() {
    super.initState();
    _initMarket();
    _loadRecentTrades();
  }

  // Reconnect WebSocket (to pick up auth token stored during login) and subscribe
  // to the 4 market symbols shown on the home screen.
  Future<void> _initMarket() async {
    final ws = WebSocketService.instance;
    if (!ws.isConnected) {
      await ws.connect();
    }
    ws.subscribe(['EURUSD', 'GBPUSD', 'XAUUSD', 'BTCUSD']);
  }

  Future<void> _loadRecentTrades() async {
    // Wait briefly for accounts to load (but don't loop forever)
    int attempts = 0;
    while (Mt5AccountStore.instance.active == null && attempts < 6) {
      await Future.delayed(const Duration(milliseconds: 300));
      attempts++;
    }
    if (!mounted) return;

    final acc = Mt5AccountStore.instance.active;
    if (acc == null) {
      setState(() => _tradesLoading = false);
      return;
    }

    try {
      final trades = await TradingRepository.instance.getHistory(
        accountId: acc.id, limit: 5,
      );
      if (mounted) setState(() { _recentTrades = trades; _tradesLoading = false; });
    } catch (_) {
      // Trading API not yet implemented on backend — show empty state
      if (mounted) setState(() => _tradesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<Mt5AccountStore>().refreshActiveAccount();
          _initMarket();
          await _loadRecentTrades();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _HomeHeader(onSwitchTab: widget.onSwitchTab)),
            SliverToBoxAdapter(child: const _BalanceCard()),
            SliverToBoxAdapter(child: _QuickActions()),
            SliverToBoxAdapter(child: _MarketOverview(onSeeAll: () => widget.onSwitchTab?.call(1))),
            SliverToBoxAdapter(child: _InvestmentProducts()),
            SliverToBoxAdapter(child: _RecentTrades(trades: _recentTrades, loading: _tradesLoading)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final void Function(int)? onSwitchTab;
  const _HomeHeader({this.onSwitchTab});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final firstName = authState is AuthAuthenticated ? authState.user.firstName : 'Trader';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_greeting(), style: AppTextStyles.bodyMedium),
          Text('$firstName 👋', style: AppTextStyles.headingLarge),
        ]),
        const Spacer(),
        Stack(children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bg200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
            ),
          ),
          Positioned(top: 6, right: 6,
              child: Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle))),
        ]),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => onSwitchTab?.call(4),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Builder(builder: (_) {
              final state = context.read<AuthCubit>().state;
              final initials = state is AuthAuthenticated ? state.user.initials : 'T';
              return Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15));
            })),
          ),
        ),
      ]),
    ).animate().fadeIn();
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<Mt5AccountStore>(
      builder: (_, store, __) {
        final isLoading = store.isLoading;
        final acc = store.active;
        final balance = acc?.balance ?? 0.0;
        final equity = acc?.equity ?? 0.0;
        final margin = acc?.margin ?? 0.0;
        final openPL = acc?.openPL ?? 0.0;
        final plPositive = openPL >= 0;

        String fmt(double v) => v >= 1000
            ? '\$${(v / 1000).toStringAsFixed(2)}k'
            : '\$${v.toStringAsFixed(2)}';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Total Equity', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                if (acc != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(plPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: Colors.white, size: 12),
                      Text(' ${plPositive ? '+' : ''}\$${openPL.abs().toStringAsFixed(2)} P/L',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ]),
              const SizedBox(height: 12),
              // Loading → spinner; no accounts → link prompt; account exists → balance
              if (isLoading)
                const SizedBox(height: 36,
                    child: Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)))
              else if (acc == null)
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('No MT5 account linked',
                      style: TextStyle(color: Colors.white60, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.deposit),
                    child: const Text('Go to Profile → Link MT5 Account',
                        style: TextStyle(color: Colors.white38, fontSize: 11,
                            decoration: TextDecoration.underline, decorationColor: Colors.white38)),
                  ),
                ])
              else
                Text(fmt(equity), style: const TextStyle(color: Colors.white, fontSize: 32,
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 20),
              Row(children: [
                _MiniStat('Balance', fmt(balance)),
                _VSep(),
                _MiniStat('Equity',  fmt(equity)),
                _VSep(),
                _MiniStat('Margin',  fmt(margin)),
              ]),
            ]),
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0);
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
  ]));
}

class _VSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 28, color: Colors.white24);
}

class _QuickActions extends StatelessWidget {
  final List<Map<String, dynamic>> actions = const [
    {'icon': Icons.add_rounded,              'label': 'Deposit',    'route': AppRoutes.deposit,     'color': AppColors.primary},
    {'icon': Icons.remove_rounded,           'label': 'Withdraw',   'route': AppRoutes.withdraw,    'color': AppColors.accent},
    {'icon': Icons.people_alt_outlined,      'label': 'Copy Trade', 'route': AppRoutes.copyTrading, 'color': Color(0xFF7C3AED)},
    {'icon': Icons.account_balance_outlined, 'label': 'PAMM',       'route': AppRoutes.mamPamm,     'color': AppColors.gold},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((a) => GestureDetector(
          onTap: () => Navigator.pushNamed(context, a['route'] as String),
          child: Column(children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: (a['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (a['color'] as Color).withValues(alpha: 0.25)),
              ),
              child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(a['label'] as String, style: AppTextStyles.caption),
          ]),
        )).toList(),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _MarketOverview extends StatelessWidget {
  final VoidCallback? onSeeAll;
  const _MarketOverview({this.onSeeAll});

  static const _symbols = ['EURUSD', 'GBPUSD', 'XAUUSD', 'BTCUSD'];
  static const _displayNames = {'EURUSD': 'EUR/USD', 'GBPUSD': 'GBP/USD', 'XAUUSD': 'XAU/USD', 'BTCUSD': 'BTC/USD'};

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketService>(
      builder: (_, ws, __) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Market Watch', style: AppTextStyles.headingSmall),
              const Spacer(),
              TextButton(onPressed: onSeeAll,
                  child: Text('See All', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary))),
            ]),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _symbols.map((sym) {
                final tick = ws.tickFor(sym);
                return _MarketChip(
                  symbol: _displayNames[sym] ?? sym,
                  price: tick?.formattedBid ?? '—',
                  change: tick?.formattedChange ?? '—',
                  isBull: tick?.isBullish ?? true,
                );
              }).toList()),
            ),
          ]),
        ).animate().fadeIn(delay: 300.ms);
      },
    );
  }
}

class _MarketChip extends StatelessWidget {
  final String symbol, price, change;
  final bool isBull;
  const _MarketChip({required this.symbol, required this.price, required this.change, required this.isBull});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg200,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(symbol, style: AppTextStyles.labelLarge),
        const SizedBox(height: 6),
        Text(price, style: AppTextStyles.numericSmall),
        const SizedBox(height: 4),
        Row(children: [
          Icon(isBull ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isBull ? AppColors.bullish : AppColors.bearish, size: 12),
          Text(change, style: AppTextStyles.caption.copyWith(color: isBull ? AppColors.bullish : AppColors.bearish)),
        ]),
      ]),
    );
  }
}

class _InvestmentProducts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Investment Products', style: AppTextStyles.headingSmall),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _ProductCard(
            title: 'Copy Trading', subtitle: 'Follow top traders',
            icon: Icons.people_alt_rounded, color: AppColors.primary, roi: '+18.4% avg',
            onTap: () => Navigator.pushNamed(context, AppRoutes.copyTrading),
          )),
          const SizedBox(width: 12),
          Expanded(child: _ProductCard(
            title: 'PAMM/MAM', subtitle: 'Managed accounts',
            icon: Icons.account_balance_rounded, color: AppColors.gold, roi: '+24.7% avg',
            onTap: () => Navigator.pushNamed(context, AppRoutes.mamPamm),
          )),
        ]),
      ]),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _ProductCard extends StatelessWidget {
  final String title, subtitle, roi;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ProductCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.roi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.labelLarge),
          Text(subtitle, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(6)),
            child: Text(roi, style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

class _RecentTrades extends StatelessWidget {
  final List<TradeHistory> trades;
  final bool loading;
  const _RecentTrades({required this.trades, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Recent Trades', style: AppTextStyles.headingSmall),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: Text('View All', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 12),
        if (loading)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(color: AppColors.primary),
          ))
        else if (trades.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Column(children: [
              const Icon(Icons.swap_horiz_rounded, color: AppColors.textMuted, size: 40),
              const SizedBox(height: 8),
              Text('No recent trades', style: AppTextStyles.bodySmall),
            ]),
          )
        else
          ...trades.map((t) {
            final isBuy = t.side == OrderSide.buy;
            final profit = t.netProfit;
            final profitPositive = profit >= 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
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
                  Text(t.symbol, style: AppTextStyles.labelLarge),
                  Text('${t.lots} lots', style: AppTextStyles.caption),
                ])),
                Text('${profitPositive ? '+' : ''}\$${profit.abs().toStringAsFixed(2)}',
                    style: AppTextStyles.numericSmall.copyWith(
                        color: profitPositive ? AppColors.bullish : AppColors.bearish)),
              ]),
            );
          }),
      ]),
    ).animate().fadeIn(delay: 500.ms);
  }
}
