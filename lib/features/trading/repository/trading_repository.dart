import '../../../core/network/api_client.dart';
import '../models/trading_models.dart';

class TradingRepository {
  static final TradingRepository instance = TradingRepository._();
  TradingRepository._();

  final _api = ApiClient.instance;

  // Helper: unwrap {success, data: {...}} envelope
  static Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map) return raw['data'] as Map<String, dynamic>;
      return raw;
    }
    return {};
  }

  static List<dynamic> _unwrapList(dynamic raw, String key) {
    if (raw is Map<String, dynamic>) {
      final d = raw['data'];
      if (d is List) return d;
      if (d is Map && d[key] is List) return d[key] as List;
    }
    if (raw is List) return raw;
    return [];
  }

  // ── Place order ──────────────────────────────────────────────────────────────
  // Backend: POST /trades/place-order
  Future<OrderResult> placeOrder(OrderRequest request) async {
    try {
      final res = await _api.post('/trades/place-order', data: request.toJson());
      return OrderResult.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Get open positions ───────────────────────────────────────────────────────
  // Backend: GET /trades/positions?accountId=xxx
  Future<List<TradingPosition>> getPositions({required String accountId}) async {
    try {
      final res = await _api.get('/trades/positions', params: {'accountId': accountId});
      final list = _unwrapList(res.data, 'positions');
      return list.map((j) => TradingPosition.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Close a position ─────────────────────────────────────────────────────────
  // Backend: POST /trades/close/:tradeId  body: {mt5AccountId, ticket}
  Future<OrderResult> closePosition({required String accountId, required int ticket}) async {
    try {
      final res = await _api.post('/trades/close/$ticket', data: {
        'mt5AccountId': accountId,
        'ticket': ticket,
      });
      return OrderResult.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Close all positions for an account ──────────────────────────────────────
  // No bulk close on backend — fetch all positions and close individually
  Future<void> closeAllPositions(String accountId) async {
    try {
      final positions = await getPositions(accountId: accountId);
      for (final pos in positions) {
        try {
          await closePosition(accountId: accountId, ticket: pos.ticket);
        } catch (_) {
          // continue closing others even if one fails
        }
      }
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Trade history ────────────────────────────────────────────────────────────
  // Backend: GET /trades/history?accountId=xxx&from=...&page=1&limit=50
  Future<List<TradeHistory>> getHistory({
    required String accountId,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await _api.get('/trades/history', params: {
        'accountId': accountId,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
        'page': page,
        'limit': limit,
      });
      final list = _unwrapList(res.data, 'trades');
      return list.map((j) => TradeHistory.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Modify SL/TP on open position ────────────────────────────────────────────
  // Backend: POST /trades/modify/:tradeId  body: {stopLoss, takeProfit}
  Future<void> modifyPosition({
    required String accountId,
    required int ticket,
    double? stopLoss,
    double? takeProfit,
  }) async {
    try {
      await _api.post('/trades/modify/$ticket', data: {
        'mt5AccountId': accountId,
        if (stopLoss != null) 'stopLoss': stopLoss,
        if (takeProfit != null) 'takeProfit': takeProfit,
      });
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Cancel a pending order ───────────────────────────────────────────────────
  Future<void> cancelOrder({required String accountId, required int ticket}) async {
    try {
      await _api.delete('/trades/orders/$ticket?mt5AccountId=$accountId');
    } catch (e) {
      throw extractApiException(e);
    }
  }
}
