class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  String get userMessage {
    switch (statusCode) {
      case 400: return message.isNotEmpty ? message : 'Invalid request.';
      case 401: return 'Session expired. Please login again.';
      case 403: return 'You don\'t have permission for this action.';
      case 404: return 'Resource not found.';
      case 409: return message.isNotEmpty ? message : 'Conflict — resource already exists.';
      case 422: return message.isNotEmpty ? message : 'Validation failed.';
      case 429: return 'Too many requests. Please wait a moment.';
      case 500:
      case 502:
      case 503: return 'Server error. Please try again later.';
      case 0:   return 'No internet connection.';
      default:  return message.isNotEmpty ? message : 'Something went wrong.';
    }
  }

  bool get isAuthError => statusCode == 401;
  bool get isNetworkError => statusCode == 0;
}
