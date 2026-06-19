import 'package:flutter/foundation.dart';
import '../models/mt5_account.dart';
import '../services/mt5_service.dart';

export '../models/mt5_account.dart';

enum StoreStatus { initial, loading, loaded, error }

class Mt5AccountStore extends ChangeNotifier {
  static final instance = Mt5AccountStore._();
  // Constructor does NOT seed fake data and does NOT auto-load.
  // loadAccounts() must be called explicitly after the auth token is available.
  Mt5AccountStore._();

  final List<Mt5Account> _accounts = [];
  int _activeIndex = 0;
  StoreStatus _status = StoreStatus.initial;
  String? _error;

  List<Mt5Account> get accounts => List.unmodifiable(_accounts);
  Mt5Account? get active => _accounts.isEmpty ? null : _accounts[_activeIndex];
  int get activeIndex => _activeIndex;
  StoreStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _status == StoreStatus.loading;
  bool get isEmpty => _accounts.isEmpty && _status == StoreStatus.loaded;

  // ── Fetch real accounts from backend ─────────────────────────────────────────
  // Called by AuthCubit after login / session restore.
  Future<void> loadAccounts() async {
    _status = StoreStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final apiAccounts = await Mt5Service.instance.getAccounts();
      _accounts
        ..clear()
        ..addAll(apiAccounts);
      if (_activeIndex >= _accounts.length) _activeIndex = 0;
      _status = StoreStatus.loaded;
    } catch (e) {
      _status = StoreStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  // ── Refresh live numbers for the active account ────────────────────────────
  Future<void> refreshActiveAccount() async {
    final acc = active;
    if (acc == null) return;
    try {
      final updated = await Mt5Service.instance.getAccountInfo(acc.id);
      final idx = _accounts.indexWhere((a) => a.id == updated.id);
      if (idx != -1) {
        _accounts[idx] = updated;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Switch active account ──────────────────────────────────────────────────
  void switchTo(int index) {
    if (index < 0 || index >= _accounts.length || index == _activeIndex) return;
    _activeIndex = index;
    notifyListeners();
    Mt5Service.instance.setActiveAccount(_accounts[index].id).catchError((_) {});
  }

  // ── Add a locally-linked account (from _AddAccountSheet) ──────────────────
  void addAccount(Mt5Account account) {
    _accounts.add(account);
    notifyListeners();
  }

  // ── Remove a custom account ────────────────────────────────────────────────
  Future<void> removeAccount(String id) async {
    final idx = _accounts.indexWhere((a) => a.id == id);
    if (idx == -1 || !_accounts[idx].isCustom) return;
    try {
      await Mt5Service.instance.unlinkAccount(id);
    } catch (_) {}
    _accounts.removeAt(idx);
    if (_activeIndex >= _accounts.length) _activeIndex = _accounts.length > 0 ? _accounts.length - 1 : 0;
    notifyListeners();
  }

  // ── Create a new MT5 account via POST /accounts/create ────────────────────
  // accountType: 'live' | 'demo' | 'cent' | 'copy_trading'
  // Returns the account INCLUDING tradingPassword and investorPassword.
  Future<Mt5Account> createAccount({
    required String accountType,
    required int leverage,
    String currency = 'USD',
  }) async {
    final account = await Mt5Service.instance.createAccount(
      accountType: accountType,
      leverage: leverage,
      currency: currency,
    );
    _accounts.add(account);
    _activeIndex = _accounts.length - 1;
    notifyListeners();
    return account;
  }

  // ── Link an existing CRM account by MT5 login number ──────────────────────
  // POST /accounts/link — for accounts created in the CRM admin panel
  Future<Mt5Account> linkExistingAccount({
    required String mt5Login,
    String accountType = 'live',
    int leverage = 100,
  }) async {
    final account = await Mt5Service.instance.linkExistingAccount(
      mt5Login: mt5Login,
      accountType: accountType,
      leverage: leverage,
    );
    _accounts.add(account);
    _activeIndex = _accounts.length - 1;
    notifyListeners();
    return account;
  }

  // ── Clear all accounts (on logout) ────────────────────────────────────────
  void clear() {
    _accounts.clear();
    _activeIndex = 0;
    _status = StoreStatus.initial;
    _error = null;
    notifyListeners();
  }
}
