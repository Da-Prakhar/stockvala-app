import 'dart:async';
import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../repository/market_data_repository.dart';

/// Live candlestick chart — the v7 KLineChart loading model ported to Flutter.
///
/// Three separate data paths, so the chart never re-downloads what it has:
///   • first paint  — INITIAL_BARS via GET /trades/chart (instant from cache on revisit)
///   • pan backward — one deeper page of PAGE_BARS, fetched once
///   • live         — the socket quote folds into the forming candle (no HTTP)
/// A periodic reconcile re-fetches only the last few bars to correct drift.
class CandleChart extends StatefulWidget {
  final String symbol;      // normalized, e.g. EURUSD
  final String timeframe;   // app tf: 1m 5m 15m 1h 4h 1D

  const CandleChart({super.key, required this.symbol, required this.timeframe});

  @override
  State<CandleChart> createState() => _CandleChartState();
}

// Bars fetched for the first paint; the rest only if the user pans back.
const _kInitialBars = 200;
const _kPageBars = 500;      // all the backend aggregator holds per timeframe
const _kReconcileBars = 3;   // periodic correction — last bars only

const _tfSeconds = {
  'M1': 60, 'M5': 300, 'M15': 900, 'M30': 1800,
  'H1': 3600, 'H4': 14400, 'D1': 86400,
};

/// App timeframe label → MT5 timeframe the backend understands.
String mapTimeframe(String tf) => switch (tf) {
      '1m' => 'M1',
      '5m' => 'M5',
      '15m' => 'M15',
      '30m' => 'M30',
      '1h' => 'H1',
      '4h' => 'H4',
      '1D' || '1d' => 'D1',
      _ => 'M15',
    };

/* ═══════════════════════════════════════════════════
   Module-level candle cache — survives navigation,
   so re-opening a chart paints instantly (v7 pattern).
   Key: "SYMBOL|TF" → ascending bars.
   ═══════════════════════════════════════════════════ */
final Map<String, List<CandleData>> _candleCache = {};

class _CandleChartState extends State<CandleChart> {
  final _repo = MarketDataRepository.instance;

  List<CandleData> _bars = [];   // ascending by time
  bool _loading = false;
  bool _unavailable = false;
  bool _paged = false;           // deeper page fetched already
  int _failStreak = 0;

  Timer? _reconcileTimer;
  StreamSubscription<QuoteTick>? _tickSub;

  String get _cacheKey => '${widget.symbol}|$_mt5Tf';
  String get _mt5Tf => mapTimeframe(widget.timeframe);

  @override
  void initState() {
    super.initState();
    _mount();
  }

  @override
  void didUpdateWidget(CandleChart old) {
    super.didUpdateWidget(old);
    if (old.symbol != widget.symbol || old.timeframe != widget.timeframe) {
      _teardown();
      _mount();
    }
  }

  void _mount() {
    _paged = false;
    _failStreak = 0;
    _unavailable = false;

    // Instant paint from cache — fresh data replaces it right after.
    final cached = _candleCache[_cacheKey];
    _bars = cached != null ? List.of(cached) : [];

    _fetch(first: true);

    // Light drift correction; live movement comes from the socket below.
    _reconcileTimer = Timer.periodic(const Duration(seconds: 60), (_) => _fetch(first: false));

    // Live candle from the socket quote — no HTTP in this path.
    _tickSub = WebSocketService.instance.tickStream.listen(_onTick);
  }

  void _teardown() {
    _reconcileTimer?.cancel();
    _tickSub?.cancel();
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }

  Future<void> _fetch({required bool first}) async {
    final forKey = _cacheKey;
    if (first && _bars.isEmpty) setState(() => _loading = true);
    try {
      final candles = await _repo.getChart(
        widget.symbol,
        timeframe: _mt5Tf,
        count: first ? _kInitialBars : _kReconcileBars,
      );
      if (!mounted || forKey != _cacheKey) return; // symbol/tf switched mid-flight
      if (candles.isNotEmpty) {
        _failStreak = 0;
        setState(() {
          _unavailable = false;
          if (first) {
            _bars = candles;
          } else {
            // Correction only — patch matching tail bars, append new ones.
            for (final c in candles) {
              final i = _bars.lastIndexWhere((b) => b.time == c.time);
              if (i >= 0) {
                _bars[i] = c;
              } else if (_bars.isEmpty || c.time > _bars.last.time) {
                _bars.add(c);
              }
            }
          }
          _loading = false;
        });
        _candleCache[forKey] = List.of(_bars);
      } else if (first && _bars.isEmpty) {
        setState(() { _unavailable = true; _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted || forKey != _cacheKey) return;
      // A poll that fails silently leaves stale candles looking live — after a
      // few misses say so honestly instead (v7 failStreak behavior).
      _failStreak++;
      setState(() {
        if ((first && _bars.isEmpty) || _failStreak >= 3) _unavailable = _bars.isEmpty;
        _loading = false;
      });
    }
  }

  /// Older bars, fetched only when the user actually pans back to them.
  Future<void> _loadOlder() async {
    if (_paged || _bars.isEmpty) return;
    final forKey = _cacheKey;
    try {
      final candles = await _repo.getChart(widget.symbol, timeframe: _mt5Tf, count: _kPageBars);
      if (!mounted || forKey != _cacheKey) return;
      _paged = true;
      final cutoff = _bars.first.time;
      final older = candles.where((c) => c.time < cutoff).toList();
      if (older.isNotEmpty) {
        setState(() => _bars = [...older, ..._bars]);
        _candleCache[forKey] = List.of(_bars);
      }
    } catch (_) {/* pan-back is best-effort */}
  }

  /// Fold the live quote into the forming candle (v7 live path).
  void _onTick(QuoteTick tick) {
    if (tick.sym != widget.symbol || tick.bid <= 0 || _bars.isEmpty) return;
    final tfSecs = _tfSeconds[_mt5Tf] ?? 900;
    final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final barStart = (nowSecs ~/ tfSecs) * tfSecs;
    final last = _bars.last;
    final price = tick.bid;

    setState(() {
      if (barStart > last.time) {
        _bars.add(CandleData(
          time: barStart, open: price, high: price, low: price, close: price,
        ));
        if (_bars.length > _kPageBars + _kInitialBars) _bars.removeAt(0);
      } else {
        _bars[_bars.length - 1] = last.copyWith(
          high: price > last.high ? price : last.high,
          low: price < last.low ? price : last.low,
          close: price,
        );
      }
    });
    _candleCache[_cacheKey] = _bars; // same list — cheap write-through
  }

  @override
  Widget build(BuildContext context) {
    if (_bars.isEmpty) {
      return Container(
        color: AppColors.bg100,
        alignment: Alignment.center,
        child: _unavailable
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.candlestick_chart_outlined, color: AppColors.textMuted, size: 42),
                const SizedBox(height: 10),
                Text('Chart unavailable for ${widget.symbol}', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                const Text('No candle data from the server yet', style: AppTextStyles.bodySmall),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () { setState(() => _unavailable = false); _fetch(first: true); },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ])
            : const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
      );
    }

    // candlesticks package wants NEWEST at index 0.
    final display = _bars.reversed
        .map((c) => Candle(
              date: DateTime.fromMillisecondsSinceEpoch(c.time * 1000),
              open: c.open, high: c.high, low: c.low, close: c.close,
              volume: c.volume,
            ))
        .toList(growable: false);

    return Container(
      color: AppColors.bg100,
      child: Stack(children: [
        Candlesticks(
          candles: display,
          onLoadMoreCandles: _loadOlder,
        ),
        if (_loading)
          const Positioned(
            top: 10, left: 10,
            child: SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          ),
      ]),
    );
  }
}
