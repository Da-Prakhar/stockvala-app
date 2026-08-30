import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/auth_models.dart';
import '../repository/auth_repository.dart';
import '../../../core/providers/mt5_account_store.dart';
import '../../../core/network/websocket_service.dart';

// ── State ────────────────────────────────────────────────────────────────────
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  AuthAuthenticated(this.user);
}

class AuthOtpRequired extends AuthState {
  final String target;
  final String? purpose;
  AuthOtpRequired(this.target, {this.purpose});
}

class AuthPinRequired extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// ── Cubit ────────────────────────────────────────────────────────────────────
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final _repo = AuthRepository.instance;

  /// Debug-only auto-login for simulator/emulator test runs:
  ///   flutter run --dart-define=DEV_AUTOLOGIN=email:password
  /// Ignored entirely in release builds.
  static const _devAutologin = String.fromEnvironment('DEV_AUTOLOGIN');

  // ── Internal helper: emit authenticated + load real MT5 accounts ─────────
  void _onAuthenticated(AppUser user) {
    emit(AuthAuthenticated(user));
    // Load real accounts from backend now that auth token is available
    Mt5AccountStore.instance.loadAccounts();
    // Rebuild the price socket with the fresh token — the pre-auth socket was
    // rejected by the server (Token missing) and would never recover on its own.
    WebSocketService.instance.reconnectWithAuth();
  }

  // Called on app start — check for saved session
  Future<void> checkSession() async {
    emit(AuthLoading());
    try {
      if (await _repo.hasSavedSession()) {
        final user = await _repo.getSavedUser();
        if (user != null) {
          _onAuthenticated(user);
          return;
        }
        // Token exists but no cached user — fetch fresh profile
        try {
          final freshUser = await _repo.getProfile();
          _onAuthenticated(freshUser);
        } catch (_) {
          emit(AuthUnauthenticated());
        }
      } else {
        if (kDebugMode && _devAutologin.contains(':')) {
          final i = _devAutologin.indexOf(':');
          await login(
            email: _devAutologin.substring(0, i),
            password: _devAutologin.substring(i + 1),
          );
          return;
        }
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final auth = await _repo.login(email: email, password: password);
      if (auth.requiresPin) {
        emit(AuthPinRequired());
      } else {
        _onAuthenticated(auth.user);
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    emit(AuthLoading());
    try {
      final auth = await _repo.register(
        firstName: firstName, lastName: lastName,
        email: email, password: password, phone: phone,
      );
      _onAuthenticated(auth.user);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyOtp({required String target, required String otp, String? purpose}) async {
    emit(AuthLoading());
    try {
      final auth = await _repo.verifyOtp(target: target, otp: otp, purpose: purpose);
      _onAuthenticated(auth.user);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    await _repo.logout();
    // Clear all local account data on logout
    Mt5AccountStore.instance.clear();
    emit(AuthUnauthenticated());
  }

  void clearError() {
    if (state is AuthError) emit(AuthInitial());
  }
}
