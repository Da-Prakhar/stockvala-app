import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/app_config.dart';
import 'core/constants/app_routes.dart';
import 'core/providers/mt5_account_store.dart';
import 'core/network/websocket_service.dart';
import 'features/auth/cubit/auth_cubit.dart';

// Auth
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/set_pin_screen.dart';
import 'features/auth/screens/biometric_setup_screen.dart';

// KYC
import 'features/kyc/screens/kyc_screen.dart';

// Main
import 'features/home/screens/home_screen.dart';

// Deposit
import 'features/deposit/screens/deposit_screen.dart';

// Copy Trading
import 'features/copy_trading/screens/copy_trading_screen.dart';

// MAM PAMM
import 'features/mam_pamm/screens/mam_pamm_screen.dart';

// Notifications
import 'features/notifications/screens/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,           // dark icons on light bg
    systemNavigationBarColor: Color(0xFFF5F3FF),        // match light scaffold
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Connect WebSocket on startup
  WebSocketService.instance.connect();

  runApp(const StockValaApp());
}

class StockValaApp extends StatelessWidget {
  const StockValaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: Mt5AccountStore.instance),
        ChangeNotifierProvider.value(value: WebSocketService.instance),
        BlocProvider(create: (_) => AuthCubit()..checkSession()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppConfig.brand.theme,   // brand-specific colors + fonts
        initialRoute: AppRoutes.splash,
        routes: _routes,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Map<String, WidgetBuilder> get _routes => {
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.onboarding: (_) => const OnboardingScreen(),
    AppRoutes.login: (_) => const LoginScreen(),
    AppRoutes.register: (_) => const RegisterScreen(),
    AppRoutes.setPin: (_) => const SetPinScreen(),
    AppRoutes.pinLogin: (_) => const PinLoginScreen(),
    AppRoutes.biometricSetup: (_) => const BiometricSetupScreen(),
    AppRoutes.kycStart: (_) => const KycPersonalScreen(),
    AppRoutes.kycPersonal: (_) => const KycPersonalScreen(),
    AppRoutes.kycDocument: (_) => const KycDocumentScreen(),
    AppRoutes.kycSelfie: (_) => const KycSelfieScreen(),
    AppRoutes.kycRiskProfile: (_) => const KycRiskProfileScreen(),
    AppRoutes.kycSuccess: (_) => const KycSuccessScreen(),
    AppRoutes.home: (_) => const MainShell(),
    AppRoutes.deposit: (_) => const DepositScreen(),
    AppRoutes.withdraw: (_) => const DepositScreen(isWithdraw: true),
    AppRoutes.notifications: (_) => const NotificationsScreen(),
    AppRoutes.copyTrading: (_) => const CopyTradingScreen(),
    AppRoutes.mamPamm: (_) => const MamPammScreen(),
    AppRoutes.forgotPassword: (_) => const _ForgotPasswordPlaceholder(),
  };

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.otpVerify:
        final email = settings.arguments as String? ?? '';
        return MaterialPageRoute(builder: (_) => OtpScreen(target: email));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('Route not found: ${settings.name}',
                style: const TextStyle(color: Colors.black54))),
          ),
        );
    }
  }
}

// Simple placeholder for Forgot Password (full screen can be built later)
class _ForgotPasswordPlaceholder extends StatelessWidget {
  const _ForgotPasswordPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password'), leading: BackButton(onPressed: () => Navigator.pop(context))),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Password reset is coming soon.\nPlease contact support@onefx.co.in',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
