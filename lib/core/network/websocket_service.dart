import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import '../../config/app_config.dart';

// Immutable tick data for a single symbol
class QuoteTick {
  final String sym;
  final double bid;
  final double ask;
  final double change;
  final double changePct;
  final double spread;
  final double high;
  final double low;
  final int ts; // epoch ms

  const QuoteTick({
    required this.sym,
    required this.bid,
    required this.ask,
    this.change = 0,
    this.changePct = 0,
    this.spread = 0,
    this.high = 0,
    this.low = 0,
    required this.ts,
  });

  bool get isBullish => changePct >= 0;

  String get formattedBid => bid.toStringAsFixed(_decimals(sym));
  String get formattedAsk => ask.toStringAsFixed(_decimals(sym));
  String get formattedChange => '${isBullish ? '+' : ''}${changePct.toStringAsFixed(2)}%';
  String get formattedPips => '${isBullish ? '+' : ''}${change.abs().toStringAsFixed(_decimals(sym) > 3 ? 1 : 0)} pts';

  int _decimals(String s) {
    if (s.contains('JPY') || s.contains('US30') || s.contains('SPX') ||
        s.contains('GER') || s.contains('BTC')) return 0;
    if (s.contains('XAU') || s.contains('XAG') || s.contains('XPT') ||
        s.contains('OIL')) return 2;
    return 5;
  }

  // Build from Socket.IO price_update event:
  // {symbol, bid, ask, t (epoch secs), serverName}
  factory QuoteTick.fromSocketEvent(dynamic data, [QuoteTick? prev]) {
    final j = data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
    final sym = (j['symbol'] as String? ?? '').replaceAll('.#', '');
    final bid = (j['bid'] as num? ?? 0).toDouble();
    final ask = (j['ask'] as num? ?? bid).toDouble();
    final prevBid = prev?.bid ?? bid;
    final change = bid - prevBid;
    final changePct = prevBid != 0 ? (change / prevBid) * 100 : 0.0;

    return QuoteTick(
      sym: sym,
      bid: bid,
      ask: ask,
      change: change,
      changePct: changePct,
      spread: ask - bid,
      high: prev?.high != null && bid > prev!.high ? bid : (prev?.high ?? bid),
      low: prev?.low != null && bid < prev!.low ? bid : (prev?.low ?? bid),
      ts: ((j['t'] as num?)?.toInt() ?? 0) * 1000, // secs → ms
    );
  }

  // Legacy JSON factory (kept for compatibility)
  factory QuoteTick.fromJson(Map<String, dynamic> j) => QuoteTick(
    sym: j['sym'] as String? ?? j['symbol'] as String? ?? '',
    bid: (j['bid'] as num? ?? 0).toDouble(),
    ask: (j['ask'] as num? ?? 0).toDouble(),
    change: (j['change'] as num? ?? 0).toDouble(),
    changePct: (j['change_pct'] as num? ?? j['changePct'] as num? ?? 0).toDouble(),
    spread: (j['spread'] as num? ?? 0).toDouble(),
    high: (j['high'] as num? ?? 0).toDouble(),
    low: (j['low'] as num? ?? 0).toDouble(),
    ts: (j['ts'] as int? ?? j['t'] as int? ?? 0),
  );
}

class WebSocketService extends ChangeNotifier {
  static final WebSocketService instance = WebSocketService._();
  WebSocketService._();

  IO.Socket? _socket;
  bool _connected = false;

  // Symbol → latest tick
  final Map<String, QuoteTick> _ticks = {};
  final _tickController = StreamController<QuoteTick>.broadcast();

  // Subscriptions to re-send on reconnect
  final Set<String> _subscriptions = {};

  bool get isConnected => _connected;
  Map<String, QuoteTick> get ticks => Map.unmodifiable(_ticks);
  Stream<QuoteTick> get tickStream => _tickController.stream;

  QuoteTick? tickFor(String sym) => _ticks[normalizeSymbol(sym)] ?? _ticks[sym];

  /// Normalize a symbol to the MT5 canonical form the backend uses.
  /// Strips '/' separator so 'EUR/USD' → 'EURUSD', 'XAU/USD' → 'XAUUSD'.
  /// The backend strips broker suffixes (.# / .pro) and uses plain names.
  static String normalizeSymbol(String sym) => sym.replaceAll('/', '');

  // ── Connect using Socket.IO ──────────────────────────────────────────────────
  Future<void> connect() async {
    // Guard: if a socket object already exists (connected OR still connecting),
    // do not create another one.  socket_io_client handles reconnection internally.
    if (_socket != null) return;

    final token = await SecureStorage().getString(AppConstants.tokenKey);

    // Strip path from wsUrl to get base URL — Socket.IO uses its own /socket.io path
    // e.g. ws://api.onefx.co.in/ws → http://api.onefx.co.in
    String wsBase = AppConfig.wsUrl
        .replaceFirst('wss://', 'https://')
        .replaceFirst('ws://', 'http://')
        .replaceAll(RegExp(r'/ws/?$'), '');

    // socket_io_client Dart bug: URLs without an explicit port resolve to port 0
    // on reconnect (Dart Uri.parse returns port==0 for implicit HTTP/HTTPS ports),
    // causing every reconnect attempt to fail. Force-add the default port so
    // the library always uses the correct port (80 for http, 443 for https).
    final _parsedWsUri = Uri.parse(wsBase);
    if (_parsedWsUri.port == 0 || _parsedWsUri.hasPort == false) {
      wsBase = _parsedWsUri
          .replace(port: _parsedWsUri.scheme == 'https' ? 443 : 80)
          .toString();
    }
    debugPrint('[WS] connecting to $wsBase');

    _socket = IO.io(
      wsBase,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token ?? ''})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(30000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _connected = true;
        debugPrint('[WS] Socket.IO connected');
        notifyListeners();
        // Re-subscribe to all symbols on reconnect — wrap in list (see subscribe() note)
        if (_subscriptions.isNotEmpty) {
          _socket!.emit('price:subscribe', [_subscriptions.toList()]);
          debugPrint('[WS] re-subscribed ${_subscriptions.length} symbols on connect: ${_subscriptions.take(5).join(",")}...');
        } else {
          debugPrint('[WS] connected but _subscriptions is empty — subscribe() not called yet');
        }
      })
      ..onDisconnect((_) {
        _connected = false;
        debugPrint('[WS] Socket.IO disconnected');
        notifyListeners();
      })
      ..onConnectError((err) {
        _connected = false;
        debugPrint('[WS] Socket.IO connect error: $err');
        notifyListeners();
      })
      ..on('price_update', _onPriceTick);
  }

  void _onPriceTick(dynamic data) {
    try {
      final sym = ((data['symbol'] as String?) ?? '').replaceAll('.#', '');
      if (sym.isEmpty) return;
      final prev = _ticks[sym];
      final tick = QuoteTick.fromSocketEvent(data, prev);
      _ticks[sym] = tick;
      // Also store under the raw symbol name (with suffix) for lookup
      final rawSym = (data['symbol'] as String?) ?? sym;
      if (rawSym != sym) _ticks[rawSym] = tick;
      _tickController.add(tick);
      debugPrint('[WS] tick ▶ $sym bid=${tick.bid} ask=${tick.ask}');
      notifyListeners();
    } catch (e) {
      debugPrint('[WS] tick parse error: $e');
    }
  }

  // ── Subscribe to symbols ─────────────────────────────────────────────────────
  // Symbols are normalized (EUR/USD → EURUSD) before being sent so they match
  // the room names the backend creates from its MT5 gateway tick data.
  void subscribe(List<String> symbols) {
    final normalized = symbols.map(normalizeSymbol).toList();
    _subscriptions.addAll(normalized);
    if (_socket != null && _connected) {
      // Wrap in a list so socket_io_client sends one array argument, not N separate arguments.
      // socket.emit('event', ['a','b']) → server gets ('a', 'b') as two args (only first captured).
      // socket.emit('event', [['a','b']]) → server gets (['a','b']) as one array arg. ✅
      _socket!.emit('price:subscribe', [normalized]);
      debugPrint('[WS] subscribed to ${normalized.length} symbols: ${normalized.take(5).join(',')}...');
    }
  }

  void unsubscribe(List<String> symbols) {
    for (final s in symbols) {
      _subscriptions.remove(normalizeSymbol(s));
    }
    if (_socket != null && _connected) {
      _socket!.emit('price:unsubscribe', symbols.map(normalizeSymbol).toList());
    }
  }

  // ── Disconnect ───────────────────────────────────────────────────────────────
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;       // null so connect() can create a fresh socket
    _connected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _tickController.close();
    super.dispose();
  }
}
