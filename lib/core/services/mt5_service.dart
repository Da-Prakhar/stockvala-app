import '../network/api_client.dart';
import '../models/mt5_account.dart';

class Mt5Service {
  static final Mt5Service instance = Mt5Service._();
  Mt5Service._();

  final _api = ApiClient.instance;

  Future<List<Mt5Account>> getAccounts() async {
    try {
      final res = await _api.get('/accounts');
      final body = res.data as Map<String, dynamic>;
      // Two envelope shapes in the wild:
      //   v2/onefx: {data: [ ...accounts ]}
      //   v7:       {data: {accounts: [...], accountLimit, accountCount}}
      final d = body['data'];
      final list = d is List
          ? d
          : (d is Map ? (d['accounts'] as List<dynamic>? ?? []) : <dynamic>[]);
      return list
          .whereType<Map>()
          .map((j) => Mt5Account.fromJson(j.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw extractApiException(e);
    }
  }

  Future<Mt5Account> getAccountInfo(String accountId) async {
    try {
      final res = await _api.get('/accounts/$accountId');
      final body = res.data as Map<String, dynamic>;
      final d = (body['data'] is Map) ? body['data'] as Map<String, dynamic> : body;
      return Mt5Account.fromJson(d);
    } catch (e) {
      throw extractApiException(e);
    }
  }

  /// Create a new MT5 account via POST /accounts/create.
  /// accountType must be: 'live' | 'demo' | 'cent' | 'copy_trading'
  /// The returned account includes tradingPassword and investorPassword.
  Future<Mt5Account> createAccount({
    required String accountType,
    required int leverage,
    String currency = 'USD',
  }) async {
    try {
      final res = await _api.post('/accounts/create', data: {
        'accountType': accountType,
        'leverage': leverage,
        'currency': currency,
      });
      final body = res.data as Map<String, dynamic>;
      final d = (body['data'] is Map) ? body['data'] as Map<String, dynamic> : body;
      return Mt5Account.fromJson(d);
    } catch (e) {
      throw extractApiException(e);
    }
  }

  /// Link an existing CRM/MT5 account to the current user by login number.
  /// POST /accounts/link  { mt5Login, accountType, leverage }
  Future<Mt5Account> linkExistingAccount({
    required String mt5Login,
    String accountType = 'live',
    int leverage = 100,
  }) async {
    try {
      final res = await _api.post('/accounts/link', data: {
        'mt5Login': mt5Login,
        'accountType': accountType,
        'leverage': leverage,
      });
      final body = res.data as Map<String, dynamic>;
      final d = (body['data'] is Map) ? body['data'] as Map<String, dynamic> : body;
      return Mt5Account.fromJson(d);
    } catch (e) {
      throw extractApiException(e);
    }
  }

  Future<void> unlinkAccount(String accountId) async {
    try {
      await _api.delete('/accounts/$accountId');
    } catch (e) {
      throw extractApiException(e);
    }
  }

  Future<void> setActiveAccount(String accountId) async {
    try {
      await _api.patch('/accounts/$accountId/activate');
    } catch (_) {}
  }
}
