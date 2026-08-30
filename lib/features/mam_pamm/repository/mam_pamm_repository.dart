import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

/// MAM + PAMM funds against the v7 backend:
///   GET    /mam/managers            GET    /pamm/pools
///   GET    /mam/investments         GET    /pamm/investments
///   POST   /mam/invest {managerId, mt5AccountId, amount}
///   POST   /pamm/invest {poolId, amount}
///   DELETE /mam/investments/:id     DELETE /pamm/investments/:id
class MamPammRepository {
  static final MamPammRepository instance = MamPammRepository._();
  MamPammRepository._();

  final _api = ApiClient.instance;

  static const _colors = [AppColors.primary, AppColors.gold, Color(0xFFE53935), Color(0xFF0CAF60)];

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  static String _money(double v) {
    if (v.abs() >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (v.abs() >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  static String _pct(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%';

  /// Map one manager/pool record into the fund-card shape the UI consumes.
  static Map<String, dynamic> _fundCard(Map<String, dynamic> r, String kind, int i) {
    final user = (r['user'] as Map?) ?? {};
    final managerName =
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final aum = kind == 'PAMM'
        ? _num(r['totalAum'] ?? r['liveEquity'])
        : _num(r['liveEquity'] ?? r['liveBalance']);
    final profitPct = _num(r['avgProfit'] ?? r['totalProfit']);
    return {
      'id': r['id'],
      'kind': kind,
      'name': (r['name'] ?? 'Fund').toString(),
      'manager': managerName.isEmpty ? 'Fund Manager' : managerName,
      'type': kind,
      'minInvest': _num(r['minInvestment']).toInt(),
      'roi12m': _pct(profitPct),
      'monthlyAvg': _pct(_num(r['winRate'])),
      'investors': _num(r['investorCount']).toInt(),
      'aum': _money(aum),
      'dd': 0.0,
      'color': _colors[i % _colors.length],
      'perfFee': _num(r['performanceFeePct']),
      'mgmtFee': _num(r['managementFeePct']),
      'description': (r['description'] ?? '').toString(),
      'totalTrades': _num(r['totalTrades']).toInt(),
      'winRate': _num(r['winRate']),
    };
  }

  /// Both MAM managers and PAMM pools as one card list.
  Future<List<Map<String, dynamic>>> getFunds() async {
    final results = await Future.wait([
      _api.get('/mam/managers'),
      _api.get('/pamm/pools'),
    ]);
    final funds = <Map<String, dynamic>>[];
    var i = 0;
    for (final m in (results[0].data?['data'] as List? ?? []).whereType<Map>()) {
      funds.add(_fundCard(m.cast<String, dynamic>(), 'MAM', i++));
    }
    for (final p in (results[1].data?['data'] as List? ?? []).whereType<Map>()) {
      funds.add(_fundCard(p.cast<String, dynamic>(), 'PAMM', i++));
    }
    return funds;
  }

  /// My investments across both products.
  /// Each row: {id, kind, fundId, fundName, amount, status}.
  Future<List<Map<String, dynamic>>> getInvestments() async {
    final results = await Future.wait([
      _api.get('/mam/investments'),
      _api.get('/pamm/investments'),
    ]);
    final out = <Map<String, dynamic>>[];
    for (final r in (results[0].data?['data'] as List? ?? []).whereType<Map>()) {
      final m = r.cast<String, dynamic>();
      final mgr = (m['manager'] as Map?) ?? {};
      out.add({
        'id': m['id'],
        'kind': 'MAM',
        'fundId': mgr['id'] ?? m['managerId'],
        'fundName': (mgr['name'] ?? 'MAM Fund').toString(),
        'amount': _num(m['amount'] ?? m['investedAmount'] ?? m['allocationAmount']),
        'status': (m['status'] ?? 'active').toString(),
      });
    }
    for (final r in (results[1].data?['data'] as List? ?? []).whereType<Map>()) {
      final p = r.cast<String, dynamic>();
      final pool = (p['pool'] as Map?) ?? (p['manager'] as Map?) ?? {};
      out.add({
        'id': p['id'],
        'kind': 'PAMM',
        'fundId': pool['id'] ?? p['poolId'] ?? p['pammManagerId'],
        'fundName': (pool['name'] ?? 'PAMM Pool').toString(),
        'amount': _num(p['investedAmount'] ?? p['amount']),
        'status': (p['status'] ?? 'active').toString(),
      });
    }
    return out;
  }

  Future<void> invest({
    required String kind,
    required int fundId,
    required double amount,
    int? mt5AccountId,
  }) async {
    try {
      if (kind == 'PAMM') {
        await _api.post('/pamm/invest', data: {'poolId': fundId, 'amount': amount});
      } else {
        await _api.post('/mam/invest', data: {
          'managerId': fundId,
          if (mt5AccountId != null) 'mt5AccountId': mt5AccountId,
          'amount': amount,
        });
      }
    } catch (e) {
      throw extractApiException(e);
    }
  }

  Future<void> withdraw({required String kind, required int investmentId}) async {
    try {
      await _api.delete(
          kind == 'PAMM' ? '/pamm/investments/$investmentId' : '/mam/investments/$investmentId');
    } catch (e) {
      throw extractApiException(e);
    }
  }
}
