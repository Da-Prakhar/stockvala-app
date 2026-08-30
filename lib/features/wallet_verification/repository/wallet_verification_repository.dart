import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

/// v7 crypto payout-address verification:
///   GET    /wallet-verification                 — full state
///   POST   /wallet-verification/addresses       — multipart {network, currency,
///            address, holderName, label} + `proof` video (≤80MB mp4/mov/webm/3gp)
///   DELETE /wallet-verification/addresses/:id   — pending/rejected only
///   POST   /wallet-verification/unlock-request  — multipart {declaredName,
///            walletAddress} + `video` (only while the balance is locked)
class WalletAddressEntry {
  final int id;
  final String network, currency, address, holderName, status;
  final String? label, adminNote;

  const WalletAddressEntry({
    required this.id,
    required this.network,
    required this.currency,
    required this.address,
    required this.holderName,
    required this.status,
    this.label,
    this.adminNote,
  });

  factory WalletAddressEntry.fromJson(Map<String, dynamic> j) => WalletAddressEntry(
        id: (j['id'] as num).toInt(),
        network: (j['network'] ?? '').toString(),
        currency: (j['currency'] ?? 'USDT').toString(),
        address: (j['address'] ?? '').toString(),
        holderName: (j['holderName'] ?? '').toString(),
        status: (j['status'] ?? 'pending').toString(),
        label: j['label'] as String?,
        adminNote: (j['adminNote'] ?? j['rejectionReason']) as String?,
      );

  String get shortAddress => address.length <= 16
      ? address
      : '${address.substring(0, 8)}…${address.substring(address.length - 6)}';
}

class WalletVerificationState {
  final List<WalletAddressEntry> addresses;
  final int max, used, remaining, strikes, strikeLimit, strikesRemaining;
  final Map<String, dynamic>? lock;          // {reason, lockedAt, unlockAt, daysRemaining}
  final Map<String, dynamic>? unlockRequest; // {status, adminNote, createdAt, ...}
  final String accountName;

  const WalletVerificationState({
    required this.addresses,
    required this.max,
    required this.used,
    required this.remaining,
    required this.strikes,
    required this.strikeLimit,
    required this.strikesRemaining,
    this.lock,
    this.unlockRequest,
    required this.accountName,
  });

  bool get locked => lock != null;

  factory WalletVerificationState.fromJson(Map<String, dynamic> j) {
    final limits = ((j['limits'] as Map?) ?? {}).cast<String, dynamic>();
    return WalletVerificationState(
      addresses: ((j['addresses'] as List?) ?? [])
          .whereType<Map>()
          .map((a) => WalletAddressEntry.fromJson(a.cast<String, dynamic>()))
          .toList(),
      max: (limits['max'] as num? ?? 3).toInt(),
      used: (limits['used'] as num? ?? 0).toInt(),
      remaining: (limits['remaining'] as num? ?? 0).toInt(),
      strikes: (limits['strikes'] as num? ?? 0).toInt(),
      strikeLimit: (limits['strikeLimit'] as num? ?? 3).toInt(),
      strikesRemaining: (limits['strikesRemaining'] as num? ?? 3).toInt(),
      lock: (j['lock'] as Map?)?.cast<String, dynamic>(),
      unlockRequest: (j['unlockRequest'] as Map?)?.cast<String, dynamic>(),
      accountName: (j['accountName'] ?? '').toString(),
    );
  }
}

class WalletVerificationRepository {
  static final WalletVerificationRepository instance = WalletVerificationRepository._();
  WalletVerificationRepository._();

  final _api = ApiClient.instance;

  Future<WalletVerificationState> getState() async {
    try {
      final res = await _api.get('/wallet-verification');
      final d = ((res.data?['data'] as Map?) ?? {}).cast<String, dynamic>();
      return WalletVerificationState.fromJson(d);
    } catch (e) {
      throw extractApiException(e);
    }
  }

  Future<void> addAddress({
    required String network,
    required String currency,
    required String address,
    required String holderName,
    String? label,
    required String proofVideoPath,
  }) async {
    try {
      final form = FormData.fromMap({
        'network': network,
        'currency': currency,
        'address': address,
        'holderName': holderName,
        if (label != null && label.isNotEmpty) 'label': label,
        'proof': await MultipartFile.fromFile(proofVideoPath),
      });
      await _api.dio.post('/wallet-verification/addresses', data: form);
    } catch (e) {
      throw extractApiException(e);
    }
  }

  Future<void> removeAddress(int id) async {
    try {
      await _api.delete('/wallet-verification/addresses/$id');
    } catch (e) {
      throw extractApiException(e);
    }
  }

  Future<void> requestUnlock({
    required String declaredName,
    String? walletAddress,
    required String videoPath,
  }) async {
    try {
      final form = FormData.fromMap({
        'declaredName': declaredName,
        if (walletAddress != null && walletAddress.isNotEmpty)
          'walletAddress': walletAddress,
        'video': await MultipartFile.fromFile(videoPath),
      });
      await _api.dio.post('/wallet-verification/unlock-request', data: form);
    } catch (e) {
      throw extractApiException(e);
    }
  }
}
