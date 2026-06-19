class AppConstants {
  static const String appName = 'StockVala';
  static const String appTagline = 'Trade. Invest. Grow.';
  static const String version = '1.0.0';

  // API
  static const String baseUrl = 'https://api.stockvala.com/v2';
  static const String wsUrl = 'wss://stream.stockvala.com/ws';
  static const String mt5ApiUrl = 'https://mt5.stockvala.com/api';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String pinKey = 'app_pin';
  static const String biometricKey = 'biometric_enabled';
  static const String onboardingKey = 'onboarding_done';
  static const String themeKey = 'theme_mode';

  // KYC
  static const int otpLength = 6;
  static const int otpResendSeconds = 30;
  static const int pinLength = 6;

  // Trading
  static const List<String> timeframes = ['1m', '5m', '15m', '30m', '1h', '4h', '1D', '1W', '1M'];
  static const List<String> orderTypes = ['Market', 'Limit', 'Stop', 'Stop Limit'];
  static const List<String> leverages = ['1:1', '1:10', '1:25', '1:50', '1:100', '1:200', '1:500'];

  // Supported currencies
  static const List<String> currencies = ['USD', 'EUR', 'GBP', 'JPY', 'INR', 'AED'];

  // Copy trading
  static const double minCopyAmount = 100.0;
  static const double maxCopyAmount = 100000.0;

  // MAM/PAMM
  static const double minPammInvestment = 500.0;

  // Deposit methods
  static const List<String> depositMethods = [
    'Bank Transfer',
    'Credit / Debit Card',
    'Crypto (USDT)',
    'UPI',
    'Net Banking',
    'Skrill',
    'Neteller',
  ];
}
