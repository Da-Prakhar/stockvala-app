import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_card.dart';

class MamPammScreen extends StatefulWidget {
  const MamPammScreen({super.key});

  @override
  State<MamPammScreen> createState() => _MamPammScreenState();
}

class _MamPammScreenState extends State<MamPammScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Reactive investment state — tracks which funds have been invested in
  final Set<String> _invested = {};
  final Map<String, double> _myAmounts = {};

  static const List<Map<String, dynamic>> _funds = [
    {
      'name': 'AlphaGrowth PAMM',
      'manager': 'AlphaTrade Capital',
      'type': 'PAMM',
      'minInvest': 500,
      'roi12m': '+48.3%',
      'monthlyAvg': '+3.8%',
      'investors': 234,
      'aum': '\$2.4M',
      'dd': 14.2,
      'color': AppColors.primary,
    },
    {
      'name': 'SafeYield MAM',
      'manager': 'SafeHaven Capital',
      'type': 'MAM',
      'minInvest': 1000,
      'roi12m': '+28.7%',
      'monthlyAvg': '+2.2%',
      'investors': 89,
      'aum': '\$890K',
      'dd': 6.4,
      'color': AppColors.gold,
    },
    {
      'name': 'AggroFX PAMM',
      'manager': 'FX Masters LLC',
      'type': 'PAMM',
      'minInvest': 250,
      'roi12m': '+96.4%',
      'monthlyAvg': '+7.2%',
      'investors': 521,
      'aum': '\$4.1M',
      'dd': 32.8,
      'color': AppColors.error,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    // Pre-seed AlphaGrowth PAMM as already invested (demo state)
    _invested.add('AlphaGrowth PAMM');
    _myAmounts['AlphaGrowth PAMM'] = 2500.0;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _invest(String fundName, double amount) {
    setState(() {
      _invested.add(fundName);
      _myAmounts[fundName] = amount;
    });
  }

  void _withdraw(String fundName) {
    setState(() {
      _invested.remove(fundName);
      _myAmounts.remove(fundName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final investedFunds = _funds.where((f) => _invested.contains(f['name'] as String)).toList();
    final totalInvested = _myAmounts.values.fold(0.0, (s, a) => s + a);

    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: AppBar(
        title: const Text('MAM & PAMM'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'Available Funds'),
            Tab(text: investedFunds.isEmpty ? 'My Investments' : 'My Investments (${investedFunds.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _FundsList(
            funds: _funds,
            invested: _invested,
            myAmounts: _myAmounts,
            onInvest: _invest,
            onWithdraw: _withdraw,
          ),
          _MyInvestments(
            funds: investedFunds,
            myAmounts: _myAmounts,
            totalInvested: totalInvested,
            onWithdraw: _withdraw,
          ),
        ],
      ),
    );
  }
}

class _FundsList extends StatelessWidget {
  final List<Map<String, dynamic>> funds;
  final Set<String> invested;
  final Map<String, double> myAmounts;
  final void Function(String, double) onInvest;
  final ValueChanged<String> onWithdraw;

  const _FundsList({
    required this.funds,
    required this.invested,
    required this.myAmounts,
    required this.onInvest,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AppCard(
              gradient: AppColors.cardGradient,
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('What is PAMM?', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Text('Invest in expert-managed accounts.\nEarn proportional profit/loss.', style: AppTextStyles.caption),
                ])),
                const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              ]),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _FundCard(
              fund: funds[i],
              index: i,
              isInvested: invested.contains(funds[i]['name'] as String),
              myAmount: myAmounts[funds[i]['name'] as String],
              onInvest: onInvest,
              onWithdraw: onWithdraw,
            ),
            childCount: funds.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _FundCard extends StatelessWidget {
  final Map<String, dynamic> fund;
  final int index;
  final bool isInvested;
  final double? myAmount;
  final void Function(String, double) onInvest;
  final ValueChanged<String> onWithdraw;

  const _FundCard({
    required this.fund,
    required this.index,
    required this.isInvested,
    required this.onInvest,
    required this.onWithdraw,
    this.myAmount,
  });

  @override
  Widget build(BuildContext context) {
    final color = fund['color'] as Color;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => PammDetailScreen(
          fund: fund,
          isInvested: isInvested,
          myAmount: myAmount,
          onInvest: onInvest,
          onWithdraw: onWithdraw,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bg200,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isInvested ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6),
                ),
                child: Text(fund['type'] as String, style: AppTextStyles.labelSmall.copyWith(color: color)),
              ),
              const SizedBox(width: 8),
              if (isInvested) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(6)),
                child: Text('Investing', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
              ),
              const Spacer(),
              Text(fund['roi12m'] as String, style: AppTextStyles.numericSmall.copyWith(color: AppColors.bullish)),
            ]),
            const SizedBox(height: 14),
            Text(fund['name'] as String, style: AppTextStyles.headingSmall),
            Text('by ${fund['manager']}', style: AppTextStyles.caption),
            if (isInvested && myAmount != null) ...[
              const SizedBox(height: 6),
              Text('My investment: \$${myAmount!.toStringAsFixed(2)}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 14),
            Row(children: [
              _FundStat('Monthly Avg', fund['monthlyAvg'] as String, AppColors.bullish),
              _FundStat('Max DD', '${fund['dd']}%', AppColors.warning),
              _FundStat('Investors', '${fund['investors']}', AppColors.primary),
              _FundStat('AUM', fund['aum'] as String, AppColors.textPrimary),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Min. Investment', style: AppTextStyles.caption),
                Text('\$${fund['minInvest']}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
              ])),
              SizedBox(
                width: 140,
                height: 40,
                child: isInvested
                    ? OutlinedButton(
                        onPressed: () => _confirmWithdraw(context),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text('Withdraw'),
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                        child: ElevatedButton(
                          onPressed: () => _showInvestSheet(context),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: Text('Invest Now', style: AppTextStyles.buttonMedium.copyWith(color: Colors.white)),
                        ),
                      ),
              ),
            ]),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: index * 80)).slideY(begin: 0.2, end: 0),
    );
  }

  void _showInvestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvestSheet(
        fund: fund,
        onConfirm: (amount) => onInvest(fund['name'] as String, amount),
      ),
    );
  }

  void _confirmWithdraw(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Withdraw Investment?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('Withdraw your investment from ${fund['name']}? Funds will be returned to your MT5 account within 1-3 business days.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onWithdraw(fund['name'] as String);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Withdrawal from ${fund['name']} initiated'),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: const Text('Withdraw', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _FundStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FundStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: AppTextStyles.labelMedium.copyWith(color: color)),
      Text(label, style: AppTextStyles.caption),
    ]));
  }
}

class _MyInvestments extends StatelessWidget {
  final List<Map<String, dynamic>> funds;
  final Map<String, double> myAmounts;
  final double totalInvested;
  final ValueChanged<String> onWithdraw;

  const _MyInvestments({
    required this.funds,
    required this.myAmounts,
    required this.totalInvested,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    if (funds.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.account_balance_outlined, color: AppColors.textMuted, size: 64),
        const SizedBox(height: 16),
        Text('No active investments', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 8),
        Text('Invest in a PAMM/MAM fund to start earning', style: AppTextStyles.caption),
      ]));
    }

    final totalFmt = totalInvested >= 1000
        ? '\$${(totalInvested / 1000).toStringAsFixed(2)}k'
        : '\$${totalInvested.toStringAsFixed(2)}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        AppCard(
          gradient: AppColors.cardGradient,
          child: Column(children: [
            Row(children: [
              Text('Total Invested', style: AppTextStyles.labelMedium),
              const Spacer(),
              Text('${funds.length} active fund${funds.length != 1 ? 's' : ''}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
            ]),
            const SizedBox(height: 8),
            Text(totalFmt, style: AppTextStyles.numericMedium),
            const SizedBox(height: 4),
            Text('Across ${funds.map((f) => f['type']).toSet().join(' & ')} accounts',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          ]),
        ),
        const SizedBox(height: 16),
        ...funds.asMap().entries.map((e) => _FundCard(
          fund: e.value,
          index: e.key,
          isInvested: true,
          myAmount: myAmounts[e.value['name'] as String],
          onInvest: (_, __) {},
          onWithdraw: onWithdraw,
        )),
      ],
    );
  }
}

class PammDetailScreen extends StatelessWidget {
  final Map<String, dynamic> fund;
  final bool isInvested;
  final double? myAmount;
  final void Function(String, double) onInvest;
  final ValueChanged<String> onWithdraw;
  const PammDetailScreen({
    super.key,
    required this.fund,
    this.isInvested = false,
    this.myAmount,
    required this.onInvest,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final color = fund['color'] as Color;
    return Scaffold(
      backgroundColor: AppColors.bg100,
      appBar: AppBar(title: Text(fund['name'] as String)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppCard(
            gradient: LinearGradient(colors: [color.withOpacity(0.2), AppColors.bg200]),
            child: Column(children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(fund['type'] as String, style: AppTextStyles.labelMedium.copyWith(color: color))),
                const Spacer(),
                Text(fund['roi12m'] as String, style: AppTextStyles.numericMedium.copyWith(color: AppColors.bullish)),
              ]),
              const SizedBox(height: 16),
              Text(fund['name'] as String, style: AppTextStyles.headingLarge),
              Text('Managed by ${fund['manager']}', style: AppTextStyles.bodySmall),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Fund Statistics', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, mainAxisSpacing: 12, crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard('12M Return', fund['roi12m'] as String, AppColors.bullish),
              _StatCard('Monthly Avg', fund['monthlyAvg'] as String, AppColors.primary),
              _StatCard('Max Drawdown', '${fund['dd']}%', AppColors.warning),
              _StatCard('Total Investors', '${fund['investors']}', AppColors.accent),
              _StatCard('AUM', fund['aum'] as String, AppColors.gold),
              _StatCard('Min Investment', '\$${fund['minInvest']}', AppColors.textPrimary),
            ],
          ),
          const SizedBox(height: 24),
          if (isInvested) ...[
            if (myAmount != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success),
                  const SizedBox(width: 10),
                  Text('You have \$${myAmount!.toStringAsFixed(2)} invested in this fund',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                ]),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                onWithdraw(fund['name'] as String);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Withdrawal from ${fund['name']} initiated'),
                  backgroundColor: AppColors.warning,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Withdraw Investment', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ] else
            AppButton(
              label: 'Invest in This Fund',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _InvestSheet(
                  fund: fund,
                  onConfirm: (amount) {
                    onInvest(fund['name'] as String, amount);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Invested \$${amount.toStringAsFixed(2)} in ${fund['name']}! ✓'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg200, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: AppTextStyles.numericSmall.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption),
      ]),
    );
  }
}

class _InvestSheet extends StatefulWidget {
  final Map<String, dynamic> fund;
  final void Function(double amount) onConfirm;
  const _InvestSheet({required this.fund, required this.onConfirm});

  @override
  State<_InvestSheet> createState() => _InvestSheetState();
}

class _InvestSheetState extends State<_InvestSheet> {
  final _amountCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invest in ${widget.fund['name']}', style: AppTextStyles.headingSmall),
            const SizedBox(height: 6),
            Text('Min. investment: \$${widget.fund['minInvest']}', style: AppTextStyles.bodySmall),
            const SizedBox(height: 20),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: AppTextStyles.numericMedium,
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: AppTextStyles.headingSmall.copyWith(color: AppColors.primary),
                hintText: '0.00',
                filled: true, fillColor: AppColors.bg400,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(backgroundColor: AppColors.warningBg, child: Text(
              'Your funds will be allocated to the fund manager. Returns are proportional to your investment share.',
              style: AppTextStyles.caption.copyWith(color: AppColors.warning),
            )),
            const SizedBox(height: 20),
            AppButton(label: 'Confirm Investment', onPressed: () {
              final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
              final minInvest = (widget.fund['minInvest'] as int? ?? 0).toDouble();
              if (amount < minInvest) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Minimum investment is \$${widget.fund['minInvest']}'),
                  backgroundColor: AppColors.error,
                ));
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              widget.onConfirm(amount);
              messenger.showSnackBar(SnackBar(
                content: Text('Invested \$${amount.toStringAsFixed(2)} in ${widget.fund['name']}! ✓'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
