// Order side
enum OrderSide { buy, sell }

extension OrderSideExt on OrderSide {
  String get value => name;
  static OrderSide from(String s) => s.toLowerCase() == 'buy' ? OrderSide.buy : OrderSide.sell;
}

// Order type
enum OrderType { market, limit, stop, stopLimit }

extension OrderTypeExt on OrderType {
  String get value => switch (this) {
    OrderType.market => 'market',
    OrderType.limit => 'limit',
    OrderType.stop => 'stop',
    OrderType.stopLimit => 'stop_limit',
  };
  static OrderType from(String s) => switch (s.toLowerCase()) {
    'limit' => OrderType.limit,
    'stop' => OrderType.stop,
    'stop_limit' => OrderType.stopLimit,
    _ => OrderType.market,
  };
}

// Position status
enum PositionStatus { open, closed, pending, cancelled }

// ── Order request (sent to API) ──────────────────────────────────────────────
class OrderRequest {
  final String accountId;
  final String symbol;
  final OrderType type;
  final OrderSide side;
  final double lots;
  final double? price;       // null for market orders
  final double? stopLoss;
  final double? takeProfit;
  final String? comment;

  const OrderRequest({
    required this.accountId,
    required this.symbol,
    required this.type,
    required this.side,
    required this.lots,
    this.price,
    this.stopLoss,
    this.takeProfit,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
    'mt5AccountId': accountId,       // backend field name
    'symbol': symbol,
    'type': side.value,              // backend uses 'type' for buy/sell (not 'side')
    'volume': lots,                  // backend uses 'volume' (not 'lots')
    if (price != null) 'price': price,
    if (stopLoss != null) 'sl': stopLoss,    // backend: sl/tp
    if (takeProfit != null) 'tp': takeProfit,
    if (comment != null) 'comment': comment,
  };
}

// ── Open position ────────────────────────────────────────────────────────────
class TradingPosition {
  final int ticket;
  final String symbol;
  final OrderSide side;
  final double lots;
  final double openPrice;
  final double currentPrice;
  final double profit;
  final double swap;
  final double stopLoss;
  final double takeProfit;
  final DateTime openTime;
  final String accountId;

  const TradingPosition({
    required this.ticket,
    required this.symbol,
    required this.side,
    required this.lots,
    required this.openPrice,
    required this.currentPrice,
    required this.profit,
    required this.swap,
    required this.stopLoss,
    required this.takeProfit,
    required this.openTime,
    required this.accountId,
  });

  bool get isProfit => profit >= 0;
  double get totalProfit => profit + swap;

  factory TradingPosition.fromJson(Map<String, dynamic> j) => TradingPosition(
    ticket: (j['ticket'] as num?)?.toInt() ?? 0,
    symbol: j['symbol'] as String? ?? '',
    // backend returns 'type' as 'buy'/'sell'; fallback to 'side'
    side: OrderSideExt.from((j['type'] ?? j['side']) as String? ?? 'buy'),
    // backend: volume | fallback: lots
    lots: ((j['volume'] ?? j['lots']) as num? ?? 0).toDouble(),
    // backend: openPrice | fallback: open_price
    openPrice: ((j['openPrice'] ?? j['open_price'] ?? j['price']) as num? ?? 0).toDouble(),
    // backend: currentPrice | fallback: current_price
    currentPrice: ((j['currentPrice'] ?? j['current_price']) as num? ?? 0).toDouble(),
    profit: (j['profit'] as num? ?? 0).toDouble(),
    swap: (j['swap'] as num? ?? 0).toDouble(),
    stopLoss: ((j['sl'] ?? j['stopLoss'] ?? j['stop_loss']) as num? ?? 0).toDouble(),
    takeProfit: ((j['tp'] ?? j['takeProfit'] ?? j['take_profit']) as num? ?? 0).toDouble(),
    openTime: DateTime.tryParse((j['openTime'] ?? j['open_time'])?.toString() ?? '') ?? DateTime.now(),
    accountId: (j['accountId'] ?? j['account_id'])?.toString() ?? '',
  );
}

// ── Closed trade / history ───────────────────────────────────────────────────
class TradeHistory {
  final int ticket;
  final String symbol;
  final OrderSide side;
  final double lots;
  final double openPrice;
  final double closePrice;
  final double profit;
  final double swap;
  final double commission;
  final DateTime openTime;
  final DateTime closeTime;

  const TradeHistory({
    required this.ticket,
    required this.symbol,
    required this.side,
    required this.lots,
    required this.openPrice,
    required this.closePrice,
    required this.profit,
    required this.swap,
    required this.commission,
    required this.openTime,
    required this.closeTime,
  });

  double get netProfit => profit + swap - commission.abs();

  factory TradeHistory.fromJson(Map<String, dynamic> j) => TradeHistory(
    ticket: (j['ticket'] as num?)?.toInt() ?? 0,
    symbol: j['symbol'] as String? ?? '',
    // backend returns 'type' as 'buy'/'sell'; fallback to 'side'
    side: OrderSideExt.from((j['type'] ?? j['side']) as String? ?? 'buy'),
    // backend: volume | fallback: lots
    lots: ((j['volume'] ?? j['lots']) as num? ?? 0).toDouble(),
    // backend: price (open) | fallback: open_price / openPrice
    openPrice: ((j['price'] ?? j['openPrice'] ?? j['open_price']) as num? ?? 0).toDouble(),
    // backend: closePrice | fallback: close_price
    closePrice: ((j['closePrice'] ?? j['close_price']) as num? ?? 0).toDouble(),
    profit: (j['profit'] as num? ?? 0).toDouble(),
    swap: (j['swap'] as num? ?? 0).toDouble(),
    commission: (j['commission'] as num? ?? 0).toDouble(),
    openTime: DateTime.tryParse((j['openTime'] ?? j['open_time'])?.toString() ?? '') ?? DateTime.now(),
    closeTime: DateTime.tryParse((j['closeTime'] ?? j['close_time'] ?? j['time'])?.toString() ?? '') ?? DateTime.now(),
  );
}

// ── Order result ─────────────────────────────────────────────────────────────
class OrderResult {
  final int ticket;
  final String symbol;
  final OrderSide side;
  final double lots;
  final double executedPrice;
  final String status; // 'filled', 'pending', 'rejected'
  final String? message;

  const OrderResult({
    required this.ticket,
    required this.symbol,
    required this.side,
    required this.lots,
    required this.executedPrice,
    required this.status,
    this.message,
  });

  bool get isFilled => status == 'filled';

  factory OrderResult.fromJson(Map<String, dynamic> j) {
    // Backend wraps in {success, data: {...}}
    final d = (j['data'] is Map) ? j['data'] as Map<String, dynamic> : j;
    return OrderResult(
      ticket: (d['mt5Ticket'] ?? d['ticket'] ?? d['position_ticket'] ?? d['deal_id'] ?? 0) is num
          ? ((d['mt5Ticket'] ?? d['ticket'] ?? d['position_ticket'] ?? d['deal_id']) as num).toInt()
          : int.tryParse((d['mt5Ticket'] ?? d['ticket'] ?? 0).toString()) ?? 0,
      symbol: d['symbol'] as String? ?? '',
      side: OrderSideExt.from((d['type'] ?? d['side'] ?? d['action']) as String? ?? 'buy'),
      lots: ((d['volume'] ?? d['lots']) as num? ?? 0).toDouble(),
      executedPrice: ((d['openPrice'] ?? d['price'] ?? d['executed_price'] ?? d['open_price']) as num? ?? 0).toDouble(),
      status: d['status'] as String? ?? 'filled',
      message: d['message'] as String?,
    );
  }
}
