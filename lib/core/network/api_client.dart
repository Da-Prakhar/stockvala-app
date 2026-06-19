import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';
import '../constants/app_constants.dart';
import '../../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,        // brand-specific domain
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      },
    ));
    _dio.interceptors.addAll([
      _AuthInterceptor(_dio),
      _ErrorInterceptor(),
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true, logPrint: (o) => debugPrint(o.toString())),
    ]);
  }

  late final Dio _dio;
  Dio get dio => _dio;

  // Convenience wrappers
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? params}) =>
      _dio.get<T>(path, queryParameters: params);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) =>
      _dio.delete<T>(path);
}

// ── Auth interceptor — injects Bearer token, refreshes on 401 ──────────────
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);
  final Dio _dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage().getString(AppConstants.tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try refresh
      final refreshed = await _tryRefresh();
      if (refreshed) {
        // Retry original request with new token
        final token = await SecureStorage().getString(AppConstants.tokenKey);
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (_) {}
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await SecureStorage().getString(AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final res = await Dio().post(
        '${AppConfig.apiBaseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final body = res.data as Map<String, dynamic>?;
      final data = (body?['data'] is Map) ? body!['data'] as Map<String, dynamic> : body ?? {};
      final newToken = data['accessToken'] as String? ?? data['access_token'] as String?;
      final newRefresh = data['refreshToken'] as String? ?? data['refresh_token'] as String?;
      if (newToken == null) return false;

      await SecureStorage().setString(AppConstants.tokenKey, newToken);
      if (newRefresh != null) {
        await SecureStorage().setString(AppConstants.refreshTokenKey, newRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ── Error interceptor — converts DioException → ApiException ───────────────
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ApiException apiEx;

    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown) {
      apiEx = const ApiException(statusCode: 0, message: 'No internet connection');
    } else if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      apiEx = const ApiException(statusCode: 0, message: 'Connection timed out');
    } else {
      final statusCode = err.response?.statusCode ?? 0;
      final data = err.response?.data;
      String message = '';
      if (data is Map) {
        message = (data['message'] ?? data['error'] ?? data['detail'] ?? '').toString();
      }
      apiEx = ApiException(statusCode: statusCode, message: message, data: data);
    }

    handler.reject(
      DioException(requestOptions: err.requestOptions, error: apiEx, response: err.response),
    );
  }
}

// Helper to extract ApiException from DioException
ApiException extractApiException(Object error) {
  if (error is DioException && error.error is ApiException) {
    return error.error as ApiException;
  }
  return const ApiException(statusCode: 0, message: 'Unexpected error');
}
