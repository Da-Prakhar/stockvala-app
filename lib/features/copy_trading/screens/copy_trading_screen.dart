import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class CopyTradingScreen extends StatefulWidget {
  const CopyTradingScreen({super.key});
  @override
  State<CopyTradingScreen> createState() => _CopyTradingScreenState();
}

class _CopyTradingScreenState extends State<CopyTradingScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _filter = 'All';

  // Reactive copy state — tracks which traders are actively being copied
  late final Set<String> _copying;

  static const List<Map<String, dynamic>> _traders = [
    {'name':'AlphaTrade Pro','avatar':'AT','roi':'+142.3%','monthly':'+18.4%','followers':1284,'win':72.4,'dd':12.3,'risk':'Medium','verified':true,'color':AppColors.primary,'trades':2847,'since':'Jan 2023','desc':'Professional forex trader with 8+ years experience. Specializes in EUR/USD, Gold and indices with strict risk management.'},
    {'name':'GoldFX Master','avatar':'GF','roi':'+89.7%','monthly':'+11.2%','followers':892,'win':68.1,'dd':8.5,'risk':'Low','verified':true,'color':AppColors.gold,'trades':1423,'since':'Mar 2022','desc':'Conservative gold and commodity specialist. Low drawdown, consistent monthly returns.'},
    {'name':'CryptoKing 2024','avatar':'CK','roi':'+234.6%','monthly':'+24.7%','followers':3421,'win':65.3,'dd':28.4,'risk':'High','verified':true,'color':Color(0xFF7C3AED),'trades':5234,'since':'Aug 2021','desc':'Aggressive crypto and BTC trader. High risk, high reward approach for experienced investors only.'},
    {'name':'SafeHaven FX','avatar':'SH','roi':'+56.2%','monthly':'+7.8%','followers':654,'win':74.2,'dd':5.2,'risk':'Low','verified':false,'color':Color(0xFF0CAF60),'trades':987,'since':'Jun 2023','desc':'Ultra-conservative forex trader focused on capital preservation with slow steady growth.'},
    {'name':'SwingPro Elite','avatar':'SP','roi':'+108.4%','monthly':'+14.2%','followers':2103,'win':70.1,'dd':18.6,'risk':'Medium','verified':true,'color':Color(0xFFE53935),'trades':3102,'since':'Nov 2022','desc':'Swing trading specialist across forex and commodities. Holds positions for 1-5 days.'},
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    // Pre-seed with AlphaTrade Pro as already copying (demo state)
    _copying = {'AlphaTrade Pro'};
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _toggleCopy(String traderName) {
    setState(() {
      if (_copying.contains(traderName)) {
        _copying.remove(traderName);
      } else {
        _copying.add(traderName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg100,
      body: Column(children: [
        _CTHeader(tab: _tab),
        Expanded(child: TabBarView(controller: _tab, children: [
          _TopTradersList(
            traders: _traders,
            filter: _filter,
            onFilter: (f) => setState(() => _filter = f),
            copying: _copying,
            onToggleCopy: _toggleCopy,
          ),
          _CopyingList(
            traders: _traders,
            copying: _copying,
            onToggleCopy: _toggleCopy,
          ),
          const _SignalsTab(),
        ])),
      ]),
    );
  }
}

class _CTHeader extends StatelessWidget {
  final TabController tab;
  const _CTHeader({required this.tab});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              const Text('Copy Trading', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), borderRadius: BorderRadius.circular(20)),
                child: const Row(children: [
                  Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Filter', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: tab,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [Tab(text: 'Top Traders'), Tab(text: 'Copying'), Tab(text: 'My Signals')],
          ),
        ]),
      ),
    );
  }
}

class _TopTradersList extends StatelessWidget {
  final List<Map<String,dynamic>> traders;
  final String filter;
  final ValueChanged<String> onFilter;
  final Set<String> copying;
  final ValueChanged<String> onToggleCopy;
  const _TopTradersList({
    required this.traders, required this.filter, required this.onFilter,
    required this.copying, required this.onToggleCopy,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All','Low Risk','Medium Risk','High ROI','Most Followed'];
    return CustomScrollView(slivers: [
      // Stats banner
      SliverToBoxAdapter(child: _StatsBanner()),
      // Filter chips
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: filters.map((f) => GestureDetector(
            onTap: () => onFilter(f),
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: filter == f ? AppColors.primary : AppColors.bg200,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: filter == f ? AppColors.primary : AppColors.border),
              ),
              child: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: filter == f ? Colors.white : AppColors.textMuted)),
            ),
          )).toList()),
        ),
      )),
      SliverList(delegate: SliverChildBuilderDelegate(
        (ctx, i) => _TraderCard(
          trader: traders[i],
          index: i,
          isCopying: copying.contains(traders[i]['name'] as String),
          onToggleCopy: onToggleCopy,
        ),
        childCount: traders.length,
      )),
      const SliverToBoxAdapter(child: SizedBox(height: 80)),
    ]);
  }
}

class _StatsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha:0.2)),
      ),
      child: Row(children: [
        _SB('5,280+', 'Active Traders'),
        _SDivider(),
        _SB('\$24M+', 'Copy Volume'),
        _SDivider(),
        _SB('68.3%', 'Avg Win Rate'),
      ]),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}

class _SB extends StatelessWidget {
  final String v, l;
  const _SB(this.v, this.l);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(v, style: AppTextStyles.numericSmall.copyWith(color: AppColors.primary, fontSize: 16)),
    Text(l, style: AppTextStyles.caption),
  ]));
}

class _SDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 28, color: AppColors.primary.withValues(alpha:0.2));
}

class _TraderCard extends StatelessWidget {
  final Map<String,dynamic> trader;
  final int index;
  final bool isCopying;
  final ValueChanged<String> onToggleCopy;
  const _TraderCard({
    required this.trader,
    required this.index,
    required this.isCopying,
    required this.onToggleCopy,
  });

  @override
  Widget build(BuildContext context) {
    final color = trader['color'] as Color;
    final risk = trader['risk'] as String;
    final riskColor = risk == 'Low' ? AppColors.success : risk == 'Medium' ? AppColors.warning : AppColors.error;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => TraderDetailScreen(
          trader: trader,
          isCopying: isCopying,
          onToggleCopy: () => onToggleCopy(trader['name'] as String),
        ),
      )),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.bg100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isCopying ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          // Top section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              // Avatar
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                alignment: Alignment.center,
                child: Text(trader['avatar'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(trader['name'] as String, style: AppTextStyles.labelLarge),
                  if (trader['verified'] == true) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, color: AppColors.primary, size: 15),
                  ],
                  if (isCopying) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Copying', style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.people_outline_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text('${trader['followers']} followers', style: AppTextStyles.caption),
                  const SizedBox(width: 8),
                  const Icon(Icons.swap_horiz_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text('${trader['trades']} trades', style: AppTextStyles.caption),
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(trader['roi'] as String, style: AppTextStyles.numericSmall.copyWith(color: AppColors.bullish, fontSize: 18)),
                Text('Total ROI', style: AppTextStyles.caption),
              ]),
            ]),
          ),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.bg200,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(children: [
              _StatPill('Monthly', trader['monthly'] as String, AppColors.bullish),
              _StatPill('Win Rate', '${trader['win']}%', AppColors.primary),
              _StatPill('Max DD', '${trader['dd']}%', AppColors.warning),
              _RiskPill(risk, riskColor),
              const Spacer(),
              // CTA button
              GestureDetector(
                onTap: () => isCopying
                    ? _stopCopy(context, trader)
                    : _showCopySheet(context, trader),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isCopying ? null : AppColors.primaryGradient,
                    color: isCopying ? AppColors.errorBg : null,
                    borderRadius: BorderRadius.circular(10),
                    border: isCopying ? Border.all(color: AppColors.error) : null,
                    boxShadow: isCopying ? [] : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Text(
                    isCopying ? 'Stop' : 'Copy',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: isCopying ? AppColors.error : Colors.white),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ).animate().fadeIn(delay: Duration(milliseconds: index * 80)).slideY(begin: 0.15, end: 0),
    );
  }

  void _stopCopy(BuildContext ctx, Map<String,dynamic> t) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Stop Copying ${t['name']}?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text('Your open copy trades will remain open. No new trades will be copied.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onToggleCopy(t['name'] as String);
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text('Stopped copying ${t['name']}'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: const Text('Stop Copying', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showCopySheet(BuildContext ctx, Map<String,dynamic> t) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CopySheet(
        trader: t,
        onConfirm: () => onToggleCopy(t['name'] as String),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String l, v; final Color c;
  const _StatPill(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Column(children: [
      Text(v, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
      Text(l, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
    ]),
  );
}

class _RiskPill extends StatelessWidget {
  final String risk; final Color color;
  const _RiskPill(this.risk, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha:0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(risk, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
  );
}

// ── TRADER DETAIL SCREEN ──────────────────────────────────────────────────────
class TraderDetailScreen extends StatefulWidget {
  final Map<String,dynamic> trader;
  final bool isCopying;
  final VoidCallback onToggleCopy;
  const TraderDetailScreen({super.key, required this.trader, this.isCopying = false, required this.onToggleCopy});
  @override
  State<TraderDetailScreen> createState() => _TraderDetailScreenState();
}

class _TraderDetailScreenState extends State<TraderDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() { super.initState(); _tab = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  // Sample deals generated from CRM
  static const _deals = [
    {'sym':'EUR/USD','side':'buy','vol':'0.10','open':'1.08210','close':'1.08542','profit':33.20,'date':'2026-06-06 14:22'},
    {'sym':'XAU/USD','side':'buy','vol':'0.05','open':'2318.50','close':'2341.80','profit':116.50,'date':'2026-06-05 10:08'},
    {'sym':'GBP/USD','side':'sell','vol':'0.10','open':'1.27210','close':'1.26980','profit':23.00,'date':'2026-06-04 09:15'},
    {'sym':'EUR/USD','side':'buy','vol':'0.20','open':'1.07840','close':'1.07620','profit':-44.00,'date':'2026-06-03 18:41'},
    {'sym':'BTC/USD','side':'buy','vol':'0.01','open':'66800','close':'67420','profit':62.00,'date':'2026-06-02 22:10'},
    {'sym':'USD/JPY','side':'sell','vol':'0.10','open':'156.820','close':'156.420','profit':25.60,'date':'2026-06-01 11:55'},
    {'sym':'EUR/USD','side':'buy','vol':'0.15','open':'1.08010','close':'1.08190','profit':27.00,'date':'2026-05-31 08:33'},
    {'sym':'XAU/USD','side':'sell','vol':'0.03','open':'2335.20','close':'2358.40','profit':-69.60,'date':'2026-05-30 16:50'},
  ];

  @override
  Widget build(BuildContext context) {
    final t = widget.trader;
    final color = t['color'] as Color;
    final risk = t['risk'] as String;
    final riskColor = risk == 'Low' ? AppColors.success : risk == 'Medium' ? AppColors.warning : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.bg100,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: color,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(t['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.75), AppColors.primary],
                  ),
                ),
                child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 36),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 4)],
                    ),
                    alignment: Alignment.center,
                    child: Text(t['avatar'] as String, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(t['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    if (t['verified'] == true) ...[const SizedBox(width: 6), const Icon(Icons.verified_rounded, color: Colors.white, size: 16)],
                  ]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.people_outline_rounded, color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    Text('${t['followers']} followers', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                      child: Text('Since ${t['since']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
                      child: Text(risk, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ])),
              ),
            ),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              tabs: const [Tab(text: 'Overview'), Tab(text: 'Performance'), Tab(text: 'Deals'), Tab(text: 'Copiers')],
            ),
          ),
        ],
        body: TabBarView(controller: _tab, children: [
          _OverviewTab(trader: t),
          _PerformanceTab(trader: t),
          _DealsTab(deals: _deals),
          _CopiersTab(trader: t),
        ]),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: AppButton(
          label: widget.isCopying ? 'Stop Copying' : 'Copy This Trader',
          prefixIcon: widget.isCopying ? Icons.stop_circle_outlined : Icons.people_alt_rounded,
          onPressed: widget.isCopying
              ? () {
                  widget.onToggleCopy();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Stopped copying ${t['name']}'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                }
              : () => showModalBottomSheet(
                  context: context, isScrollControlled: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (_) => _CopySheet(trader: t, onConfirm: widget.onToggleCopy),
          ),
        ),
      ),
    );
  }
}

// ── OVERVIEW TAB ──────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final Map<String,dynamic> trader;
  const _OverviewTab({required this.trader});

  @override
  Widget build(BuildContext context) {
    final color = trader['color'] as Color;
    final riskColor = trader['risk'] == 'Low' ? AppColors.success : trader['risk'] == 'Medium' ? AppColors.warning : AppColors.error;

    return ListView(padding: const EdgeInsets.all(16), children: [
      // 3 key stats
      Row(children: [
        _BigStat('Total ROI', trader['roi'] as String, AppColors.bullish),
        const SizedBox(width: 10),
        _BigStat('Monthly', trader['monthly'] as String, AppColors.primary),
        const SizedBox(width: 10),
        _BigStat('Win Rate', '${trader['win']}%', AppColors.accent),
      ]).animate().fadeIn(delay: 50.ms),
      const SizedBox(height: 14),

      // Win/Loss ratio bar
      _WinLossBar(winPct: (trader['win'] as double) / 100).animate().fadeIn(delay: 100.ms),
      const SizedBox(height: 14),

      // Stats grid
      GridView.count(
        crossAxisCount: 3, shrinkWrap: true, mainAxisSpacing: 10, crossAxisSpacing: 10,
        childAspectRatio: 1.8, physics: const NeverScrollableScrollPhysics(),
        children: [
          _GridStat('Max DD', '${trader['dd']}%', AppColors.warning),
          _GridStat('Risk Level', trader['risk'] as String, riskColor),
          _GridStat('Total Trades', '${trader['trades']}', AppColors.textPrimary),
          _GridStat('Followers', '${trader['followers']}', color),
          _GridStat('Since', trader['since'] as String, AppColors.textSecondary),
          _GridStat('Verified', trader['verified'] == true ? 'Yes ✓' : 'No', trader['verified'] == true ? AppColors.success : AppColors.textMuted),
        ],
      ).animate().fadeIn(delay: 150.ms),
      const SizedBox(height: 14),

      // About
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('About', style: AppTextStyles.headingSmall),
        const SizedBox(height: 8),
        Text(trader['desc'] as String, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
      ])).animate().fadeIn(delay: 200.ms),
      const SizedBox(height: 14),

      // Monthly performance chart
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Monthly Returns', style: AppTextStyles.headingSmall),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
            child: const Text('2026', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Bar('Jan', 0.70, '+5.2%', AppColors.bullish),
            _Bar('Feb', 0.45, '+3.4%', AppColors.bullish),
            _Bar('Mar', 0.92, '+6.8%', AppColors.bullish),
            _Bar('Apr', -0.30, '-2.2%', AppColors.bearish),
            _Bar('May', 0.78, '+5.7%', AppColors.bullish),
            _Bar('Jun', 0.55, '+4.1%', AppColors.bullish),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _MiniInfo('Best Month', 'Mar +6.8%', AppColors.bullish),
          _MiniInfo('Worst Month', 'Apr -2.2%', AppColors.bearish),
          _MiniInfo('Avg Monthly', '+3.8%', AppColors.primary),
        ]),
      ])).animate().fadeIn(delay: 250.ms),

      const SizedBox(height: 80),
    ]);
  }
}

class _WinLossBar extends StatelessWidget {
  final double winPct;
  const _WinLossBar({required this.winPct});
  @override
  Widget build(BuildContext context) {
    final wins = (winPct * 100).toStringAsFixed(1);
    final losses = ((1 - winPct) * 100).toStringAsFixed(1);
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Win / Loss Ratio', style: AppTextStyles.headingSmall),
        const Spacer(),
        Text('$wins% : $losses%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      ]),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Row(children: [
          Expanded(flex: (winPct * 100).round(), child: Container(height: 10, color: AppColors.bullish)),
          Expanded(flex: ((1 - winPct) * 100).round(), child: Container(height: 10, color: AppColors.bearish)),
        ]),
      ),
      const SizedBox(height: 10),
      Row(children: [
        _WLDot(AppColors.bullish, '$wins% Wins'),
        const SizedBox(width: 20),
        _WLDot(AppColors.bearish, '$losses% Losses'),
        const Spacer(),
        Text('${(winPct / (1 - winPct)).toStringAsFixed(2)} ratio', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ]),
    ]));
  }
}

class _WLDot extends StatelessWidget {
  final Color c; final String l;
  const _WLDot(this.c, this.l);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(l, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
  ]);
}

// ── PERFORMANCE TAB ───────────────────────────────────────────────────────────
class _PerformanceTab extends StatelessWidget {
  final Map<String,dynamic> trader;
  const _PerformanceTab({required this.trader});

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [

    // Risk score meter
    _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Risk Score', style: AppTextStyles.headingSmall),
      const SizedBox(height: 12),
      _RiskMeter(risk: trader['risk'] as String),
      const SizedBox(height: 10),
      Text('Based on max drawdown, lot sizing, and trade frequency.', style: AppTextStyles.caption),
    ])).animate().fadeIn(delay: 50.ms),
    const SizedBox(height: 12),

    // Performance report
    _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Performance Report', style: AppTextStyles.headingSmall),
      const SizedBox(height: 10),
      _PRow('Net Profit (Total)', trader['roi'] as String, AppColors.bullish),
      _PRow('Avg Monthly Return', trader['monthly'] as String, AppColors.primary),
      _PRow('Win Rate', '${trader['win']}%', AppColors.bullish),
      _PRow('Max Drawdown', '${trader['dd']}%', AppColors.warning),
      _PRow('Profit Factor', '2.14', AppColors.primary),
      _PRow('Total Trades', '${trader['trades']}', AppColors.textPrimary),
      _PRow('Avg Trade Duration', '4h 22m', AppColors.textSecondary),
      _PRow('Avg Win Trade', '+\$38.40', AppColors.bullish),
      _PRow('Avg Loss Trade', '-\$19.20', AppColors.bearish),
      _PRow('Best Trade', '+\$248.50', AppColors.bullish),
      _PRow('Worst Trade', '-\$112.30', AppColors.bearish),
    ])).animate().fadeIn(delay: 100.ms),
    const SizedBox(height: 12),

    // Instruments traded
    _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Instruments Traded', style: AppTextStyles.headingSmall),
      const SizedBox(height: 12),
      _InstrumentBar('EUR/USD', 0.38, '38%'),
      const SizedBox(height: 8),
      _InstrumentBar('XAU/USD', 0.25, '25%'),
      const SizedBox(height: 8),
      _InstrumentBar('BTC/USD', 0.18, '18%'),
      const SizedBox(height: 8),
      _InstrumentBar('GBP/USD', 0.12, '12%'),
      const SizedBox(height: 8),
      _InstrumentBar('Others',  0.07, '7%'),
    ])).animate().fadeIn(delay: 150.ms),
    const SizedBox(height: 80),
  ]);
}

class _RiskMeter extends StatelessWidget {
  final String risk;
  const _RiskMeter({required this.risk});
  @override
  Widget build(BuildContext context) {
    final pct = risk == 'Low' ? 0.25 : risk == 'Medium' ? 0.55 : 0.85;
    final c = risk == 'Low' ? AppColors.success : risk == 'Medium' ? AppColors.warning : AppColors.error;
    return Column(children: [
      Stack(children: [
        Container(height: 10, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          gradient: const LinearGradient(colors: [AppColors.success, AppColors.warning, AppColors.error]),
        )),
        Positioned(left: (MediaQuery.of(context).size.width - 72) * pct - 5, top: -3, child:
          Container(width: 16, height: 16, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: c.withValues(alpha:0.4), blurRadius: 6)]))),
      ]),
      const SizedBox(height: 8),
      Row(children: const [
        Text('Low', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
        Spacer(),
        Text('Medium', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
        Spacer(),
        Text('High', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}

class _PRow extends StatelessWidget {
  final String l, v; final Color c;
  const _PRow(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Expanded(child: Text(l, style: AppTextStyles.bodyMedium)),
      Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
    ]),
  );
}

class _InstrumentBar extends StatelessWidget {
  final String label, pct; final double val;
  const _InstrumentBar(this.label, this.val, this.pct);
  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      SizedBox(width: 70, child: Text(label, style: AppTextStyles.labelMedium)),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: val, minHeight: 8,
          backgroundColor: AppColors.bg400,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        ),
      )),
      const SizedBox(width: 8),
      SizedBox(width: 32, child: Text(pct, style: AppTextStyles.caption, textAlign: TextAlign.right)),
    ]),
  ]);
}

// ── DEALS TAB ────────────────────────────────────────────────────────────────
class _DealsTab extends StatelessWidget {
  final List<Map<String,dynamic>> deals;
  const _DealsTab({required this.deals});

  double get totalProfit => deals.fold(0, (s, d) => s + (d['profit'] as double));
  int get wins => deals.where((d) => (d['profit'] as double) > 0).length;

  @override
  Widget build(BuildContext context) => Column(children: [
    // Summary bar
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: AppColors.bg200, border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        _DSummary('${deals.length} Deals', AppColors.textSecondary),
        _DSummary('$wins Wins', AppColors.bullish),
        _DSummary('${deals.length - wins} Losses', AppColors.bearish),
        const Spacer(),
        Text(totalProfit >= 0 ? '+${totalProfit.toStringAsFixed(2)}' : totalProfit.toStringAsFixed(2),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                color: totalProfit >= 0 ? AppColors.bullish : AppColors.bearish)),
      ]),
    ),
    // Column headers
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.bg300,
      child: Row(children: const [
        SizedBox(width: 90, child: Text('Symbol', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
        SizedBox(width: 50, child: Text('Side/Vol', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
        Expanded(child: Text('Open → Close', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
        Text('P/L', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
      ]),
    ),
    Expanded(child: ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: deals.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (_, i) => _DealRow(deal: deals[i], index: i),
    )),
  ]);
}

class _DSummary extends StatelessWidget {
  final String l; final Color c;
  const _DSummary(this.l, this.c);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 14),
    child: Text(l, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
  );
}

class _DealRow extends StatelessWidget {
  final Map<String,dynamic> deal; final int index;
  const _DealRow({required this.deal, required this.index});
  @override
  Widget build(BuildContext context) {
    final profit = deal['profit'] as double;
    final isBuy = deal['side'] == 'buy';
    final pColor = profit >= 0 ? AppColors.bullish : AppColors.bearish;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 90, child: Text(deal['sym'] as String, style: AppTextStyles.labelMedium)),
          SizedBox(width: 50, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isBuy ? AppColors.bullishBg : AppColors.bearishBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('${deal['side']} ${deal['vol']}',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isBuy ? AppColors.bullish : AppColors.bearish)),
          )),
          Expanded(child: Text('${deal['open']} → ${deal['close']}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))),
          Text(profit >= 0 ? '+${profit.toStringAsFixed(2)}' : profit.toStringAsFixed(2),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: pColor)),
        ]),
        const SizedBox(height: 3),
        Text(deal['date'] as String, style: AppTextStyles.caption),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 30));
  }
}

// ── COPIERS TAB ───────────────────────────────────────────────────────────────
class _CopiersTab extends StatelessWidget {
  final Map<String,dynamic> trader;
  const _CopiersTab({required this.trader});

  static const _copiers = [
    {'name':'Rahul M.','since':'Jun 1, 2026','amount':'\$2,500','profit':'+\$184.20','active':true},
    {'name':'Priya S.','since':'May 20, 2026','amount':'\$1,000','profit':'+\$73.80','active':true},
    {'name':'Alex K.', 'since':'May 12, 2026','amount':'\$5,000','profit':'+\$368.00','active':true},
    {'name':'Maria T.','since':'Apr 30, 2026','amount':'\$750', 'profit':'+\$55.10','active':false},
    {'name':'David L.','since':'Apr 15, 2026','amount':'\$3,000','profit':'+\$221.40','active':true},
  ];

  @override
  Widget build(BuildContext context) => Column(children: [
    // Summary
    Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: AppColors.bg200, border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        _BigStat('${trader['followers']}', 'Total Copiers', AppColors.primary),
        const SizedBox(width: 10),
        _BigStat('\$24M+', 'Copy Volume', AppColors.bullish),
        const SizedBox(width: 10),
        _BigStat('92%', 'Satisfaction', AppColors.accent),
      ]),
    ),
    Expanded(child: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _copiers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = _copiers[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg200, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text((c['name'] as String).substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(c['name'] as String, style: AppTextStyles.labelLarge),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c['active'] == true ? AppColors.successBg : AppColors.bg400,
                    borderRadius: BorderRadius.circular(6)),
                  child: Text(c['active'] == true ? 'Active' : 'Paused',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c['active'] == true ? AppColors.success : AppColors.textMuted)),
                ),
              ]),
              Text('Since ${c['since']} · Copy: ${c['amount']}', style: AppTextStyles.caption),
            ])),
            Text(c['profit'] as String, style: AppTextStyles.numericSmall.copyWith(color: AppColors.bullish, fontSize: 13)),
          ]),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
      },
    )),
  ]);
}

// ── SHARED DETAIL WIDGETS ─────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.bg200, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _MiniInfo extends StatelessWidget {
  final String l, v; final Color c;
  const _MiniInfo(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
    Text(v, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
  ]);
}

class _BigStat extends StatelessWidget {
  final String v, l; final Color c;
  const _BigStat(this.v, this.l, this.c);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: c.withValues(alpha: 0.2)),
    ),
    child: Column(children: [
      Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c)),
      const SizedBox(height: 3),
      Text(l, style: AppTextStyles.caption),
    ]),
  ));
}

class _GridStat extends StatelessWidget {
  final String l, v; final Color c;
  const _GridStat(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.bg200, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
      Text(l, style: AppTextStyles.caption),
    ]),
  );
}

class _Bar extends StatelessWidget {
  final String month, pct; final double h; final Color c;
  const _Bar(this.month, this.h, this.pct, this.c);
  @override
  Widget build(BuildContext context) {
    final height = h.abs() * 56;
    final isNeg = h < 0;
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(pct, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: c)),
      const SizedBox(height: 2),
      Container(
        width: 28, height: height,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.15),
          borderRadius: isNeg ? const BorderRadius.vertical(bottom: Radius.circular(6)) : const BorderRadius.vertical(top: Radius.circular(6)),
          border: Border.all(color: c.withValues(alpha: 0.4)),
        ),
      ),
      const SizedBox(height: 5),
      Text(month, style: AppTextStyles.caption),
    ]);
  }
}

// ── COPY SHEET ────────────────────────────────────────────────────────────────
class _CopySheet extends StatefulWidget {
  final Map<String,dynamic> trader;
  final VoidCallback onConfirm;
  const _CopySheet({required this.trader, required this.onConfirm});
  @override
  State<_CopySheet> createState() => _CopySheetState();
}

class _CopySheetState extends State<_CopySheet> {
  final _ctrl = TextEditingController(text: '500');
  bool _fixed = true;
  final List<double> _quickAmounts = [100, 250, 500, 1000, 2500];

  @override
  Widget build(BuildContext context) {
    final color = widget.trader['color'] as Color;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          // Trader mini card
          Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha:0.7)]), borderRadius: BorderRadius.circular(13)),
              alignment: Alignment.center,
              child: Text(widget.trader['avatar'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.trader['name'] as String, style: AppTextStyles.labelLarge),
              Text('${widget.trader['monthly']} monthly avg', style: AppTextStyles.bodySmall.copyWith(color: AppColors.bullish)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
              child: Text(widget.trader['roi'] as String, style: AppTextStyles.labelMedium.copyWith(color: AppColors.success)),
            ),
          ]),
          const SizedBox(height: 20),
          // Amount
          Text('Investment Amount', style: AppTextStyles.labelLarge),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg200, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Row(children: [
              Text('USD', style: AppTextStyles.headingSmall.copyWith(color: AppColors.primary)),
              const SizedBox(width: 12),
              Container(width: 1, height: 24, color: AppColors.border),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.numericMedium,
                decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00', isDense: true),
              )),
            ]),
          ),
          const SizedBox(height: 10),
          // Quick amounts
          Wrap(spacing: 8, children: _quickAmounts.map((a) => GestureDetector(
            onTap: () => setState(() => _ctrl.text = a.toInt().toString()),
            child: AnimatedContainer(
              duration: 150.ms,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _ctrl.text == a.toInt().toString() ? AppColors.primaryLighter : AppColors.bg200,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _ctrl.text == a.toInt().toString() ? AppColors.primary : AppColors.border),
              ),
              child: Text('\$${a.toInt()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: _ctrl.text == a.toInt().toString() ? AppColors.primary : AppColors.textMuted)),
            ),
          )).toList()),
          const SizedBox(height: 14),
          // Copy mode
          Row(children: [
            Expanded(child: _ModeBtn('Fixed Lots', Icons.lock_outline_rounded, _fixed, () => setState(() => _fixed = true))),
            const SizedBox(width: 10),
            Expanded(child: _ModeBtn('Proportional', Icons.percent_rounded, !_fixed, () => setState(() => _fixed = false))),
          ]),
          const SizedBox(height: 20),
          AppButton(label: 'Start Copying ${widget.trader['name']}', onPressed: () {
            widget.onConfirm(); // update parent copy state
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            messenger.showSnackBar(SnackBar(
              content: Text('Now copying ${widget.trader['name']}! ✓'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String l; final IconData icon; final bool sel; final VoidCallback onTap;
  const _ModeBtn(this.l, this.icon, this.sel, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: 180.ms,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sel ? AppColors.primaryLighter : AppColors.bg200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 1.5 : 1),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: sel ? AppColors.primary : AppColors.textMuted, size: 18),
        const SizedBox(width: 6),
        Text(l, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? AppColors.primary : AppColors.textMuted)),
      ]),
    ),
  );
}

// ── COPYING TAB ───────────────────────────────────────────────────────────────
class _CopyingList extends StatelessWidget {
  final List<Map<String,dynamic>> traders;
  final Set<String> copying;
  final ValueChanged<String> onToggleCopy;
  const _CopyingList({required this.traders, required this.copying, required this.onToggleCopy});

  @override
  Widget build(BuildContext context) {
    final active = traders.where((t) => copying.contains(t['name'] as String)).toList();
    if (active.isEmpty) {
      return const _EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'Not copying anyone yet',
        subtitle: 'Go to Top Traders tab to start copying',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: active.length,
      itemBuilder: (_, i) => _TraderCard(
        trader: active[i],
        index: i,
        isCopying: true,
        onToggleCopy: onToggleCopy,
      ),
    );
  }
}

// ── SIGNALS TAB ───────────────────────────────────────────────────────────────
class _SignalsTab extends StatelessWidget {
  const _SignalsTab();
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha:0.3), blurRadius: 24)],
        ),
        child: const Icon(Icons.signal_cellular_alt_rounded, color: Colors.white, size: 48),
      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      const SizedBox(height: 24),
      Text('Become a Signal Provider', style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text('Share your trades and earn commission\nfrom every follower who copies you.',
          style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 32),
      _BenefitRow(Icons.attach_money_rounded, 'Earn up to 30% commission on profits'),
      _BenefitRow(Icons.trending_up_rounded,  'Grow your follower base automatically'),
      _BenefitRow(Icons.shield_outlined,       'Protected by our copy trade guarantee'),
      const SizedBox(height: 32),
      AppButton(label: 'Apply as Signal Provider', onPressed: () {}),
    ]),
  ));
}

class _BenefitRow extends StatelessWidget {
  final IconData icon; final String text;
  const _BenefitRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primaryLighter, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primary, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppColors.primaryLighter, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary, size: 44)),
    const SizedBox(height: 16),
    Text(title, style: AppTextStyles.headingSmall),
    const SizedBox(height: 8),
    Text(subtitle, style: AppTextStyles.bodySmall),
  ]));
}
