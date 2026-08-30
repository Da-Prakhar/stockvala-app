import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

/// Copy trading against the v7 backend:
///   GET    /copy-trading/discover                    — leaderboards + platform totals
///   GET    /copy-trading/masters                     — approved masters (full records)
///   GET    /copy-trading/masters/:id                 — detail + liveAccount + livePositions
///   GET    /copy-trading/masters/:id/copiers         — masked copier list
///   POST   /copy-trading/follow/:id                  — {allocationAmount, followerMt5AccountId, lotMode, ...}
///   DELETE /copy-trading/unfollow/:id
///   GET    /copy-trading/followings                  — my subscriptions
///   GET    /copy-trading/copy-trades                 — my copied trades
///   POST   /copy-trading/apply-master                — become a signal provider
class CopyTradingRepository {
  static final CopyTradingRepository instance = CopyTradingRepository._();
  CopyTradingRepository._();

  final _api = ApiClient.instance;

  static const _cardColors = [
    AppColors.primary,
    AppColors.gold,
    Color(0xFF7C3AED),
    Color(0xFF0CAF60),
    Color(0xFFE53935),
    Color(0xFF0EA5E9),
  ];

  // ── helpers ────────────────────────────────────────────────────────────────
  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static String _riskLabel(double band) => band <= 3 ? 'Low' : band <= 6 ? 'Medium' : 'High';

  static String _sinceLabel(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '—';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }

  static String _pct(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%';

  /// Build the Map shape the existing card/detail widgets consume.
  static Map<String, dynamic> _card({
    required Map<String, dynamic> master,
    Map<String, dynamic>? discover,
    required int colorIndex,
  }) {
    final name = (master['displayName'] ?? discover?['name'] ?? 'Trader').toString();
    final winRate = discover != null ? _num(discover['winRate']) : _num(master['winRate']);
    final ret30 = discover != null ? _num(discover['return30d']) : 0.0;
    final dd = discover != null ? _num(discover['maxDrawdown']) : _num(master['maxDrawdown']);
    final riskBand = discover != null ? _num(discover['riskBand']) : 5.0;
    final followers = discover != null
        ? (_num(discover['copiers'])).toInt()
        : (master['followerCount'] as num? ?? master['totalFollowers'] as num? ?? 0).toInt();

    return {
      'id': master['id'] ?? discover?['id'],
      'name': name,
      'avatar': _initials(name),
      'roi': _pct(ret30),
      'monthly': _pct(ret30),
      'followers': followers,
      'win': winRate,
      'dd': dd,
      'risk': _riskLabel(riskBand),
      'verified': (master['status'] ?? 'approved') == 'approved',
      'color': _cardColors[colorIndex % _cardColors.length],
      'trades': (master['totalTrades'] as num? ?? 0).toInt(),
      'since': _sinceLabel(master['createdAt']?.toString()),
      'desc': (master['description'] ?? 'No description provided.').toString(),
      'minInvestment': _num(master['minInvestment'] ?? 100),
      'perfFee': _num(master['performanceFeePct']),
      'aum': discover != null ? _num(discover['aum']) : 0.0,
      'sparkline': (discover?['sparkline'] as List?)?.map(_num).toList() ?? const <double>[],
    };
  }

  // ── Top traders: masters list enriched with discover stats ────────────────
  Future<({List<Map<String, dynamic>> traders, Map<String, dynamic> totals})>
      getTopTraders() async {
    try {
      final results = await Future.wait([
        _api.get('/copy-trading/masters'),
        _api.get('/copy-trading/discover'),
      ]);
      final masters = (results[0].data?['data'] as List? ?? [])
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList();

      final disc = ((results[1].data?['data'] as Map?) ?? {}).cast<String, dynamic>();
      // Index every discover card by master id (bestOverall + all leaderboards)
      final discIndex = <int, Map<String, dynamic>>{};
      void indexList(dynamic l) {
        for (final e in (l as List? ?? []).whereType<Map>()) {
          final id = (e['id'] as num?)?.toInt();
          if (id != null) discIndex[id] = e.cast<String, dynamic>();
        }
      }

      indexList(disc['bestOverall']);
      ((disc['leaderboards'] as Map?) ?? {}).forEach((_, v) => indexList(v));

      final traders = <Map<String, dynamic>>[];
      for (var i = 0; i < masters.length; i++) {
        final id = (masters[i]['id'] as num?)?.toInt();
        traders.add(_card(master: masters[i], discover: discIndex[id], colorIndex: i));
      }
      return (traders: traders, totals: (disc['totals'] as Map? ?? {}).cast<String, dynamic>());
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Master detail: live account + open positions ──────────────────────────
  Future<Map<String, dynamic>> getMasterDetail(int masterId) async {
    final res = await _api.get('/copy-trading/masters/$masterId');
    return ((res.data?['data'] as Map?) ?? {}).cast<String, dynamic>();
  }

  /// Live positions of a master mapped to the deals-row shape.
  static List<Map<String, dynamic>> mapLivePositions(Map<String, dynamic> detail) {
    return ((detail['livePositions'] as List?) ?? [])
        .whereType<Map>()
        .map((p) {
          final t = DateTime.fromMillisecondsSinceEpoch(
              ((p['openTime'] as num?)?.toInt() ?? 0) * 1000);
          String two(int v) => v.toString().padLeft(2, '0');
          return <String, dynamic>{
            'sym': (p['symbol'] ?? '').toString(),
            'side': (p['type'] ?? '').toString(),
            'vol': _num(p['volume']).toStringAsFixed(2),
            'open': _num(p['openPrice']).toString(),
            'close': _num(p['currentPrice']).toString(),
            'profit': _num(p['profit']),
            'date': '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}',
          };
        })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMasterCopiers(int masterId) async {
    try {
      final res = await _api.get('/copy-trading/masters/$masterId/copiers');
      return (res.data?['data'] as List? ?? []).whereType<Map>().map((c) {
        final profit = _num(c['profit']);
        return <String, dynamic>{
          'name': (c['name'] ?? 'Copier').toString(),
          'since': _sinceLabel(c['since']?.toString()),
          'amount': '\$${_num(c['allocated']).toStringAsFixed(0)}',
          'profit': '${profit >= 0 ? '+' : '-'}\$${profit.abs().toStringAsFixed(2)}',
          'active': (c['status'] ?? '') == 'active',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── My subscriptions ───────────────────────────────────────────────────────
  /// Returns raw followings; each has master{}, allocationAmount, status, id.
  Future<List<Map<String, dynamic>>> getFollowings() async {
    try {
      final res = await _api.get('/copy-trading/followings');
      return (res.data?['data'] as List? ?? [])
          .whereType<Map>()
          .map((f) => f.cast<String, dynamic>())
          .toList();
    } catch (e) {
      throw extractApiException(e);
    }
  }

  Future<void> follow(
    int masterId, {
    required double allocationAmount,
    int? followerMt5AccountId,
    bool fixedLots = false,
    double fixedLot = 0.01,
    double copyRatio = 1.0,
  }) async {
    try {
      await _api.post('/copy-trading/follow/$masterId', data: {
        'allocationAmount': allocationAmount,
        if (followerMt5AccountId != null) 'followerMt5AccountId': followerMt5AccountId,
        'lotMode': fixedLots ? 'fixed' : 'ratio',
        if (fixedLots) 'fixedLot': fixedLot,
        if (!fixedLots) 'copyRatio': copyRatio,
      });
    } catch (e) {
      throw extractApiException(e);
    }
  }

  Future<void> unfollow(int masterId) async {
    try {
      await _api.delete('/copy-trading/unfollow/$masterId');
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── My copied trades (Signals tab history) ────────────────────────────────
  Future<List<Map<String, dynamic>>> getCopyTrades() async {
    try {
      final res = await _api.get('/copy-trading/copy-trades');
      return (res.data?['data'] as List? ?? [])
          .whereType<Map>()
          .map((t) => t.cast<String, dynamic>())
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> applyAsMaster({
    required int mt5AccountId,
    required String displayName,
    String? description,
    String? tradingStyle,
    double? minInvestment,
  }) async {
    try {
      await _api.post('/copy-trading/apply-master', data: {
        'mt5AccountId': mt5AccountId,
        'displayName': displayName,
        if (description != null && description.isNotEmpty) 'description': description,
        if (tradingStyle != null) 'tradingStyle': tradingStyle,
        if (minInvestment != null) 'minInvestment': minInvestment,
      });
    } catch (e) {
      throw extractApiException(e);
    }
  }

  Future<Map<String, dynamic>?> getMyMasterProfile() async {
    try {
      final res = await _api.get('/copy-trading/my-master-profile');
      final d = res.data?['data'];
      return d is Map ? d.cast<String, dynamic>() : null;
    } catch (_) {
      return null; // 404 = not a master
    }
  }
}
