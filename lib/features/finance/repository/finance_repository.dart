import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

// ── Payment method (from GET /funds/payment-methods) ─────────────────────────
class PaymentMethod {
  final int id;
  final String name;
  final String type; // 'usdt' | 'bank' | 'card' | ...
  final bool isActive;
  final double minAmount;
  final double maxAmount;

  // Parsed from `details` JSON string
  final String? walletAddress;
  final String? network;
  final String? qrImageUrl;
  final String? bankName;
  final String? accountNumber;
  final String? ifsc;
  final Map<String, dynamic> rawDetails;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    required this.minAmount,
    required this.maxAmount,
    this.walletAddress,
    this.network,
    this.qrImageUrl,
    this.bankName,
    this.accountNumber,
    this.ifsc,
    this.rawDetails = const {},
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> details = {};
    final raw = j['details'];
    if (raw is String && raw.isNotEmpty) {
      try {
        details = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    } else if (raw is Map) {
      details = Map<String, dynamic>.from(raw);
    }

    return PaymentMethod(
      id: (j['id'] as num).toInt(),
      name: j['name'] as String? ?? '',
      type: j['type'] as String? ?? 'other',
      isActive: j['isActive'] as bool? ?? true,
      minAmount: double.tryParse(j['minAmount']?.toString() ?? '0') ?? 0,
      maxAmount: double.tryParse(j['maxAmount']?.toString() ?? '0') ?? 0,
      walletAddress: details['walletAddress'] as String?,
      network: details['network'] as String?,
      qrImageUrl: details['qrImageUrl'] as String?,
      bankName: details['bankName'] as String?,
      accountNumber: details['accountNumber'] as String?,
      ifsc: details['ifsc'] as String?,
      rawDetails: details,
    );
  }

  // Display icon logic
  String get displayNetwork => network ?? type.toUpperCase();
}

// ── Finance transaction (deposit OR withdrawal) ───────────────────────────────
class FinanceTransaction {
  final String id;
  final String type; // 'deposit' | 'withdrawal'  (set by caller, not in response)
  final double amount;
  final String currency;
  final String paymentMethodName; // from paymentMethod.name in response
  final String paymentMethodType; // from paymentMethod.type
  final String status; // 'pending' | 'approved' | 'rejected' | 'completed'
  final String? reference; // transactionRef
  final DateTime createdAt;
  final int? mt5AccountId;

  const FinanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.paymentMethodName,
    required this.paymentMethodType,
    required this.status,
    this.reference,
    required this.createdAt,
    this.mt5AccountId,
  });

  bool get isDeposit => type == 'deposit';

  /// Map 'pending' | 'approved' | 'rejected' to UI display status
  bool get isCompleted => status == 'completed' || status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected' || status == 'failed';

  /// Parse a single deposit/withdrawal JSON object.
  /// [txType] must be 'deposit' or 'withdrawal' — set by the caller.
  factory FinanceTransaction.fromJson(
    Map<String, dynamic> j, {
    required String txType,
  }) {
    // paymentMethod may be nested or flat
    final pm = j['paymentMethod'] as Map<String, dynamic>?;
    final pmName = pm?['name'] as String? ?? j['methodName'] as String? ?? '';
    final pmType = pm?['type'] as String? ?? j['methodType'] as String? ?? '';

    return FinanceTransaction(
      id: j['id']?.toString() ?? '',
      type: txType,
      amount: double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
      currency: j['currency'] as String? ?? 'USD',
      paymentMethodName: pmName,
      paymentMethodType: pmType,
      status: j['status'] as String? ?? 'pending',
      reference: j['transactionRef'] as String? ?? j['reference'] as String?,
      createdAt: DateTime.tryParse(
            j['createdAt'] as String? ?? j['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
      mt5AccountId: (j['mt5AccountId'] as num?)?.toInt(),
    );
  }
}

// ── KYC Status ────────────────────────────────────────────────────────────────
class KycStatus {
  final String status; // 'not-submitted' | 'pending' | 'verified' | 'rejected'
  const KycStatus(this.status);

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isNotSubmitted => status == 'not-submitted';
}

// ── Repository ────────────────────────────────────────────────────────────────
class FinanceRepository {
  static final FinanceRepository instance = FinanceRepository._();
  FinanceRepository._();

  final _api = ApiClient.instance;

  // ── Payment methods ───────────────────────────────────────────────────────────
  // GET /funds/payment-methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final res = await _api.get('/funds/payment-methods');
      final body = res.data as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? [];
      return list
          .map((j) => PaymentMethod.fromJson(j as Map<String, dynamic>))
          .where((m) => m.isActive)
          .toList();
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Submit deposit ────────────────────────────────────────────────────────────
  // POST /funds/deposits  { mt5AccountId: int, amount: number, paymentMethodId: int }
  Future<FinanceTransaction> deposit({
    required String accountId, // Mt5Account.id — will be parsed to int
    required double amount,
    required int paymentMethodId,
  }) async {
    final aid = int.tryParse(accountId);
    if (aid == null) {
      throw const ApiException(
        statusCode: 0,
        message: 'Invalid account ID. Please link a real MT5 account first.',
      );
    }
    try {
      final res = await _api.post('/funds/deposits', data: {
        'mt5AccountId': aid,
        'amount': amount,
        'paymentMethodId': paymentMethodId,
      });
      final body = res.data as Map<String, dynamic>;
      final d = (body['data'] is Map) ? body['data'] as Map<String, dynamic> : body;
      return FinanceTransaction.fromJson(d, txType: 'deposit');
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Submit withdrawal ─────────────────────────────────────────────────────────
  // POST /funds/withdrawals  { mt5AccountId: int, amount: number, paymentMethodId: int }
  Future<FinanceTransaction> withdraw({
    required String accountId,
    required double amount,
    required int paymentMethodId,
  }) async {
    final aid = int.tryParse(accountId);
    if (aid == null) {
      throw const ApiException(
        statusCode: 0,
        message: 'Invalid account ID. Please link a real MT5 account first.',
      );
    }
    try {
      final res = await _api.post('/funds/withdrawals', data: {
        'mt5AccountId': aid,
        'amount': amount,
        'paymentMethodId': paymentMethodId,
      });
      final body = res.data as Map<String, dynamic>;
      final d = (body['data'] is Map) ? body['data'] as Map<String, dynamic> : body;
      return FinanceTransaction.fromJson(d, txType: 'withdrawal');
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Deposit history ───────────────────────────────────────────────────────────
  // GET /funds/deposits
  Future<List<FinanceTransaction>> getDeposits({int page = 1, int limit = 20}) async {
    try {
      final res = await _api.get('/funds/deposits', params: {'page': page, 'limit': limit});
      final body = res.data as Map<String, dynamic>;
      final d = body['data'];
      final list = (d is Map ? d['deposits'] : d) as List<dynamic>? ?? [];
      return list
          .map((j) => FinanceTransaction.fromJson(j as Map<String, dynamic>, txType: 'deposit'))
          .toList();
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Withdrawal history ────────────────────────────────────────────────────────
  // GET /funds/withdrawals
  Future<List<FinanceTransaction>> getWithdrawals({int page = 1, int limit = 20}) async {
    try {
      final res = await _api.get('/funds/withdrawals', params: {'page': page, 'limit': limit});
      final body = res.data as Map<String, dynamic>;
      final d = body['data'];
      final list = (d is Map ? d['withdrawals'] : d) as List<dynamic>? ?? [];
      return list
          .map((j) => FinanceTransaction.fromJson(j as Map<String, dynamic>, txType: 'withdrawal'))
          .toList();
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── All transactions (deposits + withdrawals merged, newest first) ────────────
  Future<List<FinanceTransaction>> getTransactions({int page = 1, int limit = 20}) async {
    try {
      final results = await Future.wait([
        getDeposits(page: page, limit: limit),
        getWithdrawals(page: page, limit: limit),
      ]);
      final all = [...results[0], ...results[1]];
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── KYC status ────────────────────────────────────────────────────────────────
  // GET /kyc/status → { status: "not-submitted" | "pending" | "verified" | "rejected" }
  Future<KycStatus> getKycStatus() async {
    try {
      final res = await _api.get('/kyc/status');
      final body = res.data as Map<String, dynamic>;
      final d = (body['data'] is Map) ? body['data'] as Map<String, dynamic> : body;
      return KycStatus(d['status'] as String? ?? 'not-submitted');
    } catch (e) {
      throw extractApiException(e);
    }
  }
}
