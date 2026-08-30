import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted watchlist symbols, shared by Home + Markets.
class WatchlistStore extends ChangeNotifier {
  static final WatchlistStore instance = WatchlistStore._();
  WatchlistStore._();

  static const _key = 'sv_watchlist_v1';
  static const defaults = ['EURUSD', 'XAUUSD', 'BTCUSD'];

  final Set<String> _symbols = {...defaults};
  bool _loaded = false;

  List<String> get symbols => List.unmodifiable(_symbols);
  bool contains(String sym) => _symbols.contains(sym.toUpperCase());

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = (jsonDecode(raw) as List).whereType<String>();
        _symbols
          ..clear()
          ..addAll(list.map((s) => s.toUpperCase()));
        notifyListeners();
      }
    } catch (_) {/* fall back to defaults */}
  }

  Future<void> toggle(String sym) async {
    final s = sym.toUpperCase();
    _symbols.contains(s) ? _symbols.remove(s) : _symbols.add(s);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_symbols.toList()));
    } catch (_) {/* persistence is best-effort */}
  }
}
