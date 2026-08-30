import '../../../core/network/api_client.dart';

/// One OHLCV bar as served by GET /trades/chart/:symbol —
/// `{time (epoch secs), open, high, low, close, volume}`.
class CandleData {
  final int time; // epoch seconds, bar start
  final double open, high, low, close, volume;

  const CandleData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0,
  });

  factory CandleData.fromJson(Map<String, dynamic> j) {
    final t = (j['time'] as num? ?? 0).toInt();
    return CandleData(
      // Backend sends seconds; tolerate ms just in case (v7 toBars does the same)
      time: t > 1000000000000 ? t ~/ 1000 : t,
      open: (j['open'] as num? ?? 0).toDouble(),
      high: (j['high'] as num? ?? 0).toDouble(),
      low: (j['low'] as num? ?? 0).toDouble(),
      close: (j['close'] as num? ?? 0).toDouble(),
      volume: (j['volume'] as num? ?? 0).toDouble(),
    );
  }

  CandleData copyWith({double? high, double? low, double? close}) => CandleData(
        time: time,
        open: open,
        high: high ?? this.high,
        low: low ?? this.low,
        close: close ?? this.close,
        volume: volume,
      );
}

class TickData {
  final String symbol;
  final double bid, ask;
  final int digits;
  final int time; // epoch secs
  final String? resolvedSymbol;

  const TickData({
    required this.symbol,
    required this.bid,
    required this.ask,
    this.digits = 5,
    this.time = 0,
    this.resolvedSymbol,
  });
}

/// Chart + tick data straight from the trading backend (v7 contract):
///   GET /trades/chart/:symbol?timeframe=M15&count=200
///   GET /trades/tick/:symbol
///   GET /public/prices?symbols=A,B,C          (no auth — pre-login backstop)
class MarketDataRepository {
  static final MarketDataRepository instance = MarketDataRepository._();
  MarketDataRepository._();

  final _api = ApiClient.instance;

  Future<List<CandleData>> getChart(
    String symbol, {
    String timeframe = 'M15',
    int count = 200,
  }) async {
    try {
      final res = await _api.get(
        '/trades/chart/${Uri.encodeComponent(symbol)}?timeframe=$timeframe&count=$count',
      );
      final data = res.data?['data'] ?? res.data ?? {};
      final list = (data['candles'] as List? ?? [])
          .whereType<Map>()
          .map((c) => CandleData.fromJson(c.cast<String, dynamic>()))
          .where((c) => c.time > 0 && c.close > 0)
          .toList();
      list.sort((a, b) => a.time.compareTo(b.time));
      return list;
    } catch (e) {
      throw extractApiException(e);
    }
  }

  Future<TickData?> getTick(String symbol) async {
    try {
      final res = await _api.get('/trades/tick/${Uri.encodeComponent(symbol)}');
      final d = ((res.data?['data'] as Map?) ?? {}).cast<String, dynamic>();
      final bid = (d['bid'] as num? ?? 0).toDouble();
      final ask = (d['ask'] as num? ?? 0).toDouble();
      if (bid <= 0 && ask <= 0) return null;
      return TickData(
        symbol: symbol,
        bid: bid,
        ask: ask,
        digits: (d['digits'] as num? ?? 5).toInt(),
        time: (d['time'] as num? ?? d['t'] as num? ?? 0).toInt(),
        resolvedSymbol: d['resolvedSymbol'] as String?,
      );
    } catch (_) {
      return null; // tick backstop is best-effort — socket is the primary source
    }
  }

  /// Unauthenticated batch prices — usable on splash/login screens before a
  /// token exists. Returns {SYMBOL: {bid, ask, t}}.
  Future<Map<String, Map<String, num>>> getPublicPrices(List<String> symbols) async {
    try {
      final q = symbols.map(Uri.encodeComponent).join(',');
      final res = await _api.get('/public/prices?symbols=$q');
      final list = (res.data?['data'] as List? ?? []);
      final out = <String, Map<String, num>>{};
      for (final e in list.whereType<Map>()) {
        final sym = (e['symbol'] as String? ?? '').toUpperCase();
        final bid = (e['bid'] as num? ?? 0);
        if (sym.isEmpty || bid <= 0) continue;
        out[sym] = {'bid': bid, 'ask': e['ask'] as num? ?? bid, 't': e['t'] as num? ?? 0};
      }
      return out;
    } catch (_) {
      return {};
    }
  }
}
