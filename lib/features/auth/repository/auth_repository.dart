import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../models/auth_models.dart';

class AuthRepository {
  static final AuthRepository instance = AuthRepository._();
  AuthRepository._();

  final _api = ApiClient.instance;
  final _storage = SecureStorage();

  // ── Login ───────────────────────────────────────────────────────────────────
  Future<AuthResponse> login({required String email, required String password}) async {
    try {
      final res = await _api.post('/auth/login', data: {'email': email, 'password': password});
      final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
      await _persistAuth(auth);
      return auth;
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Register ────────────────────────────────────────────────────────────────
  Future<AuthResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final res = await _api.post('/auth/register', data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
      await _persistAuth(auth);
      return auth;
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── OTP verify ──────────────────────────────────────────────────────────────
  Future<AuthResponse> verifyOtp({required String target, required String otp, String? purpose}) async {
    try {
      final res = await _api.post('/auth/otp/verify', data: OtpVerifyRequest(
        target: target, otp: otp, purpose: purpose,
      ).toJson());
      final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
      await _persistAuth(auth);
      return auth;
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Resend OTP ──────────────────────────────────────────────────────────────
  Future<void> resendOtp({required String target, String? purpose}) async {
    try {
      await _api.post('/auth/otp/resend', data: {'target': target, if (purpose != null) 'purpose': purpose});
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Forgot password ─────────────────────────────────────────────────────────
  Future<void> forgotPassword({required String email}) async {
    try {
      await _api.post('/auth/forgot-password', data: {'email': email});
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Reset password ──────────────────────────────────────────────────────────
  Future<void> resetPassword({required String token, required String newPassword}) async {
    try {
      await _api.post('/auth/reset-password', data: {'token': token, 'password': newPassword});
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Biometric / PIN login ───────────────────────────────────────────────────
  Future<bool> hasSavedSession() async {
    final token = await _storage.getString(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<AppUser?> getSavedUser() async {
    final raw = await _storage.getString(AppConstants.userKey);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Get current profile ─────────────────────────────────────────────────────
  Future<AppUser> getProfile() async {
    try {
      final res = await _api.get('/users/me');
      final user = AppUser.fromJson(res.data as Map<String, dynamic>);
      await _storage.setString(AppConstants.userKey, jsonEncode(user.toJson()));
      return user;
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Update profile ──────────────────────────────────────────────────────────
  Future<AppUser> updateProfile({String? firstName, String? lastName, String? phone}) async {
    try {
      final res = await _api.patch('/users/me', data: {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
      });
      final user = AppUser.fromJson(res.data as Map<String, dynamic>);
      await _storage.setString(AppConstants.userKey, jsonEncode(user.toJson()));
      return user;
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Change password ─────────────────────────────────────────────────────────
  Future<void> changePassword({required String current, required String newPass}) async {
    try {
      await _api.post('/auth/change-password', data: {'current_password': current, 'new_password': newPass});
    } catch (e) {
      throw extractApiException(e);
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {} finally {
      await _storage.deleteString(AppConstants.tokenKey);
      await _storage.deleteString(AppConstants.refreshTokenKey);
      await _storage.deleteString(AppConstants.userKey);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Future<void> _persistAuth(AuthResponse auth) async {
    await _storage.setString(AppConstants.tokenKey, auth.accessToken);
    await _storage.setString(AppConstants.refreshTokenKey, auth.refreshToken);
    await _storage.setString(AppConstants.userKey, jsonEncode(auth.user.toJson()));
  }
}
