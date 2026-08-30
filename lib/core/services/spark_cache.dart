import 'dart:async';
import '../../features/trading/repository/market_data_repository.dart';

/// Tiny module-level cache of close-price series for sparklines.
/// One M30x16 chart fetch per symbol per session; instant on revisit.
class SparkCache {
  static final Map<String, List<double>> _cache = {};
  static final Map<String, Future<List<double>>> _inflight = {};

  static List<double>? peek(String symbol) => _cache[symbol.toUpperCase()];

  static Future<List<double>> get(String symbol) {
    final sym = symbol.toUpperCase();
    final hit = _cache[sym];
    if (hit != null) return Future.value(hit);
    return _inflight[sym] ??= MarketDataRepository.instance
        .getChart(sym, timeframe: 'M30', count: 16)
        .then((candles) {
      final closes = candles.map((c) => c.close).toList();
      if (closes.length >= 2) _cache[sym] = closes;
      _inflight.remove(sym);
      return closes;
    }).catchError((_) {
      _inflight.remove(sym);
      return <double>[];
    });
  }
}
