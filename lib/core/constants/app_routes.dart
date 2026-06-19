class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String otpVerify = '/otp-verify';
  static const String setPin = '/set-pin';
  static const String pinLogin = '/pin-login';
  static const String biometricSetup = '/biometric-setup';
  static const String forgotPassword = '/forgot-password';

  // KYC
  static const String kycStart = '/kyc/start';
  static const String kycPersonal = '/kyc/personal';
  static const String kycDocument = '/kyc/document';
  static const String kycSelfie = '/kyc/selfie';
  static const String kycAddress = '/kyc/address';
  static const String kycRiskProfile = '/kyc/risk-profile';
  static const String kycReview = '/kyc/review';
  static const String kycSuccess = '/kyc/success';

  // Main App
  static const String home = '/home';
  static const String markets = '/markets';
  static const String trading = '/trading';
  static const String portfolio = '/portfolio';
  static const String profile = '/profile';

  // Trading
  static const String chart = '/chart';
  static const String orderTicket = '/order-ticket';
  static const String orderHistory = '/order-history';
  static const String positions = '/positions';

  // Deposit / Withdraw
  static const String deposit = '/deposit';
  static const String depositMethod = '/deposit/method';
  static const String depositCrypto = '/deposit/crypto';
  static const String depositBank = '/deposit/bank';
  static const String depositCard = '/deposit/card';
  static const String withdraw = '/withdraw';
  static const String withdrawMethod = '/withdraw/method';
  static const String transactionHistory = '/transactions';

  // Copy Trading
  static const String copyTrading = '/copy-trading';
  static const String traderDetail = '/copy-trading/trader';
  static const String mySignals = '/copy-trading/my-signals';

  // MAM / PAMM
  static const String mamPamm = '/mam-pamm';
  static const String mamDetail = '/mam-pamm/detail';
  static const String investInPamm = '/mam-pamm/invest';

  // Settings / Profile
  static const String settings = '/settings';
  static const String security = '/settings/security';
  static const String changePin = '/settings/change-pin';
  static const String notifications = '/settings/notifications';
  static const String accountInfo = '/settings/account';
  static const String documents = '/settings/documents';
  static const String support = '/support';
  static const String about = '/about';
}
