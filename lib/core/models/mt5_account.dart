class Mt5Account {
  final String id;
  final String login;
  final String server;
  final String type;       // 'Live' | 'Demo' | 'Cent' | 'Copy Trading'
  final String accountType; // raw API value: 'live' | 'demo' | 'cent' | 'copy_trading'
  final String leverage;   // e.g. "1:100"
  final double balance;
  final double equity;
  final double margin;
  final double freeMargin;
  final double marginLevel;
  final double openPL;
  final bool isReal;
  final bool isCustom;

  // Only present immediately after account creation (POST /accounts/create)
  final String? tradingPassword;
  final String? investorPassword;

  const Mt5Account({
    required this.id,
    required this.login,
    required this.server,
    required this.type,
    required this.accountType,
    required this.leverage,
    required this.balance,
    required this.equity,
    required this.margin,
    required this.freeMargin,
    required this.marginLevel,
    required this.openPL,
    this.isReal = true,
    this.isCustom = false,
    this.tradingPassword,
    this.investorPassword,
  });

  Mt5Account copyWith({
    double? balance, double? equity, double? margin,
    double? freeMargin, double? marginLevel, double? openPL,
  }) => Mt5Account(
    id: id, login: login, server: server, type: type,
    accountType: accountType, leverage: leverage,
    balance: balance ?? this.balance, equity: equity ?? this.equity,
    margin: margin ?? this.margin, freeMargin: freeMargin ?? this.freeMargin,
    marginLevel: marginLevel ?? this.marginLevel, openPL: openPL ?? this.openPL,
    isReal: isReal, isCustom: isCustom,
    tradingPassword: tradingPassword, investorPassword: investorPassword,
  );

  factory Mt5Account.fromJson(Map<String, dynamic> j) {
    // API uses 'accountType': 'live' | 'demo' | 'cent' | 'copy_trading'
    final rawType = (j['accountType'] ?? j['type']) as String? ?? 'live';
    return Mt5Account(
      id: j['id']?.toString() ?? '',
      // backend: mt5Login (numeric) | fallback: login
      login: (j['mt5Login'] ?? j['login'])?.toString() ?? '',
      // backend: serverName | fallback: server
      server: (j['serverName'] ?? j['server']) as String? ?? '',
      // Map raw accountType to display label
      type: _mapAccountType(rawType),
      accountType: rawType,
      leverage: '1:${j['leverage'] ?? 100}',
      // Use _toDouble() — some accounts return balance as "0.00" (String),
      // others as 541438.74 (num). Handle both without crashing.
      balance:     _toDouble(j['balance']),
      equity:      _toDouble(j['equity']),
      margin:      _toDouble(j['margin']),
      freeMargin:  _toDouble(j['freeMargin'] ?? j['free_margin']),
      marginLevel: _toDouble(j['marginLevel'] ?? j['margin_level']),
      openPL:      _toDouble(j['openPL'] ?? j['open_pl']),
      // isReal: true for live/cent/copy_trading, false for demo
      isReal: rawType != 'demo',
      isCustom: j['isCustom'] as bool? ?? j['is_custom'] as bool? ?? false,
      // Credentials returned only on creation
      tradingPassword: j['tradingPassword'] as String?,
      investorPassword: j['investorPassword'] as String?,
    );
  }

  /// Parse a JSON value that may be a num OR a String (e.g. "0.00").
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static String _mapAccountType(String raw) {
    switch (raw) {
      case 'live':         return 'Live';
      case 'demo':         return 'Demo';
      case 'cent':         return 'Cent';
      case 'copy_trading': return 'Copy Trading';
      default:             return raw.isEmpty ? 'Live' : raw;
    }
  }
}
