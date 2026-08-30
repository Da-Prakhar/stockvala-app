import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/theme/app_colors.dart';
import '../repository/market_data_repository.dart';

/// Live candlestick chart — v7 loading model with an in-house renderer.
///
/// The `candlesticks` package render object crashes on live updates
/// (LateInitializationError on `_close`), which flooded frames and broke
/// hit-testing for the whole Trade screen — so the painting is now a
/// dependency-free CustomPainter. Data paths are unchanged:
///   • first paint  — INITIAL_BARS via GET /trades/chart (instant from cache)
///   • live         — socket quote folds into the forming candle (no HTTP)
///   • reconcile    — periodic tail correction
class CandleChart extends StatefulWidget {
  final String symbol;      // normalized, e.g. EURUSD
  final String timeframe;   // app tf: 1m 5m 15m 1h 4h 1D

  const CandleChart({super.key, required this.symbol, required this.timeframe});

  @override
  State<CandleChart> createState() => _CandleChartState();
}

const _kInitialBars = 200;
const _kReconcileBars = 3;

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

/* Module-level candle cache — survives navigation (v7 pattern). */
final Map<String, List<CandleData>> _candleCache = {};

class _CandleChartState extends State<CandleChart> {
  final _repo = MarketDataRepository.instance;

  List<CandleData> _bars = [];   // ascending by time
  bool _loading = false;
  bool _unavailable = false;
  int _failStreak = 0;

  Timer? _reconcileTimer;
  Timer? _flushTimer;
  StreamSubscription<QuoteTick>? _tickSub;
  bool _dirty = false; // a tick folded since the last chart flush

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
    _failStreak = 0;
    _unavailable = false;

    final cached = _candleCache[_cacheKey];
    _bars = cached != null ? List.of(cached) : [];

    _fetch(first: true);
    _reconcileTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _fetch(first: false));

    // Live ticks fold into the forming candle; the CHART repaints at most
    // every 300ms so a fast feed cannot storm the render pipeline.
    _tickSub = WebSocketService.instance.tickStream.listen(_onTick);
    _flushTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (_dirty && mounted) {
        _dirty = false;
        setState(() {});
      }
    });
  }

  void _teardown() {
    _reconcileTimer?.cancel();
    _tickSub?.cancel();
    _flushTimer?.cancel();
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
      if (!mounted || forKey != _cacheKey) return;
      if (candles.isNotEmpty) {
        _failStreak = 0;
        setState(() {
          _unavailable = false;
          if (first) {
            _bars = candles;
          } else {
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
      _failStreak++;
      setState(() {
        if ((first && _bars.isEmpty) || _failStreak >= 3) _unavailable = _bars.isEmpty;
        _loading = false;
      });
    }
  }

  /// Fold the live quote into the forming candle.
  void _onTick(QuoteTick tick) {
    if (tick.sym != widget.symbol || tick.bid <= 0 || _bars.isEmpty) return;
    final last = _bars.last;
    final price = tick.bid;

    // Feeds can disagree (a stale gateway resolving SYMBOL.# on another
    // server). A quote >3% away from the forming candle is not this chart's
    // feed — folding it in painted kilometre-long wicks.
    if ((price - last.close).abs() / last.close > 0.03) return;

    final tfSecs = _tfSeconds[_mt5Tf] ?? 900;
    final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final barStart = (nowSecs ~/ tfSecs) * tfSecs;

    if (barStart > last.time) {
      _bars.add(CandleData(
        time: barStart, open: price, high: price, low: price, close: price,
      ));
      if (_bars.length > _kInitialBars * 2) _bars.removeAt(0);
    } else {
      _bars[_bars.length - 1] = last.copyWith(
        high: price > last.high ? price : last.high,
        low: price < last.low ? price : last.low,
        close: price,
      );
    }
    _candleCache[_cacheKey] = _bars;
    _dirty = true; // flushed to the screen by the 300ms timer
  }

  @override
  Widget build(BuildContext context) {
    if (_bars.isEmpty) {
      return Container(
        color: AppColors.bg100,
        alignment: Alignment.center,
        child: _unavailable
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('📉', style: TextStyle(fontSize: 38)),
                const SizedBox(height: 10),
                Text('Chart unavailable for ${widget.symbol}',
                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                TextButton.icon(
                  onPressed: () { setState(() => _unavailable = false); _fetch(first: true); },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ])
            : const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
      );
    }

    return Container(
      color: AppColors.bg100,
      child: Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _CandlePainter(
                bars: _bars,
                maxVisible: 80,
              ),
            ),
          ),
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

/* ═══════════════════════════════════════════════════════════════════════════
   In-house renderer: candles + wicks, volume mini-pane, right price axis,
   last-price tag, time labels. No late fields, no package bugs.
   ═══════════════════════════════════════════════════════════════════════════ */
class _CandlePainter extends CustomPainter {
  final List<CandleData> bars;
  final int maxVisible;
  _CandlePainter({required this.bars, required this.maxVisible});

  static const _axisW = 62.0;
  static const _timeH = 20.0;
  static const _volFrac = 0.16;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty || size.width < _axisW + 40) return;
    final visible = bars.length > maxVisible
        ? bars.sublist(bars.length - maxVisible)
        : bars;

    final plotW = size.width - _axisW;
    final plotH = size.height - _timeH;
    final volH = plotH * _volFrac;
    final candleH = plotH - volH - 6;

    // ── Ranges ───────────────────────────────────────────────────────────
    var lo = double.infinity, hi = -double.infinity, maxVol = 0.0;
    for (final b in visible) {
      if (b.low < lo) lo = b.low;
      if (b.high > hi) hi = b.high;
      if (b.volume > maxVol) maxVol = b.volume;
    }
    if (!lo.isFinite || !hi.isFinite) return;
    final pad = (hi - lo) == 0 ? (hi.abs() * 0.001 + 0.0001) : (hi - lo) * 0.08;
    lo -= pad;
    hi += pad;
    final range = hi - lo;

    double y(double v) => (1 - (v - lo) / range) * candleH;

    // ── Grid + price labels ──────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = AppColors.chartGrid
      ..strokeWidth = 1;
    final digits = _digitsFor(visible.last.close, range);
    for (var i = 0; i <= 4; i++) {
      final gy = candleH * i / 4;
      canvas.drawLine(Offset(0, gy), Offset(plotW, gy), gridPaint);
      final price = hi - range * i / 4;
      _text(canvas, price.toStringAsFixed(digits),
          Offset(plotW + 6, gy - 6), AppColors.textMuted, 10.5);
    }

    // ── Candles + volume ─────────────────────────────────────────────────
    final slot = plotW / visible.length;
    final bodyW = math.max(1.5, slot * 0.62);
    final wickPaint = Paint()..strokeWidth = 1;

    for (var i = 0; i < visible.length; i++) {
      final b = visible[i];
      final cx = slot * i + slot / 2;
      final up = b.close >= b.open;
      final color = up ? AppColors.bullish : AppColors.bearish;

      // wick
      wickPaint.color = color;
      canvas.drawLine(Offset(cx, y(b.high)), Offset(cx, y(b.low)), wickPaint);

      // body
      final top = y(math.max(b.open, b.close));
      final bot = y(math.min(b.open, b.close));
      canvas.drawRect(
        Rect.fromLTRB(cx - bodyW / 2, top, cx + bodyW / 2,
            math.max(bot, top + 1)),
        Paint()..color = color,
      );

      // volume bar
      if (maxVol > 0) {
        final vh = (b.volume / maxVol) * (volH - 4);
        canvas.drawRect(
          Rect.fromLTRB(cx - bodyW / 2, plotH - vh, cx + bodyW / 2, plotH),
          Paint()..color = color.withValues(alpha: 0.35),
        );
      }
    }

    // ── Last price line + tag ────────────────────────────────────────────
    final last = visible.last;
    final lp = last.close.clamp(lo, hi);
    final ly = y(lp);
    final up = last.close >= last.open;
    final tagColor = up ? AppColors.bullish : AppColors.bearish;
    final dash = Paint()
      ..color = tagColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < plotW) {
      canvas.drawLine(Offset(x, ly), Offset(x + 4, ly), dash);
      x += 8;
    }
    final label = last.close.toStringAsFixed(digits);
    final tp = _layout(label, Colors.white, 10.5, FontWeight.w700);
    final tagRect = Rect.fromLTWH(
        plotW, ly - 9, _axisW, 18);
    canvas.drawRRect(
        RRect.fromRectAndRadius(tagRect, const Radius.circular(3)),
        Paint()..color = tagColor);
    tp.paint(canvas, Offset(plotW + 5, ly - tp.height / 2));

    // ── Time labels ──────────────────────────────────────────────────────
    for (final frac in const [0.08, 0.5, 0.92]) {
      final idx = (visible.length * frac).floor().clamp(0, visible.length - 1);
      final t = DateTime.fromMillisecondsSinceEpoch(visible[idx].time * 1000);
      final lbl =
          '${t.month.toString().padLeft(2, '0')}/${t.day.toString().padLeft(2, '0')} '
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      _text(canvas, lbl, Offset(slot * idx, plotH + 4), AppColors.textMuted, 10);
    }
  }

  int _digitsFor(double price, double range) {
    if (price >= 1000) return 2;
    if (price >= 10) return range < 0.5 ? 3 : 2;
    return 5;
  }

  TextPainter _layout(String s, Color c, double size,
      [FontWeight w = FontWeight.w500]) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: c, fontSize: size, fontWeight: w)),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  void _text(Canvas canvas, String s, Offset o, Color c, double size) {
    _layout(s, c, size).paint(canvas, o);
  }

  @override
  bool shouldRepaint(_CandlePainter old) =>
      old.bars != bars || old.bars.length != bars.length;
}
