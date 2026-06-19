import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Holds all brand-specific configuration for one white-label client.
/// Resolved at startup from --dart-define=BRAND=<brandId>.
class BrandConfig {
  // Identity
  final String brandId;
  final String appName;
  final String tagline;
  final String bundleIdAndroid; // com.alphatrade.app
  final String bundleIdIOS;

  // Domains — all API traffic uses these
  final String apiBaseUrl;  // https://api.alphatrade.com/v2
  final String wsUrl;       // wss://stream.alphatrade.com/ws
  final String mt5ApiUrl;   // https://mt5.alphatrade.com/api
  final String webAppUrl;   // https://app.alphatrade.com

  // Branding
  final Color primaryColor;
  final Color primaryLightColor;
  final Color primaryLighterColor; // tint background
  final Color accentColor;
  final String logoIconAsset;  // path inside assets/
  final String supportEmail;
  final String supportUrl;

  // Feature flags — turn modules on/off per brand
  final bool showCopyTrading;
  final bool showMamPamm;
  final bool showCrypto;
  final bool showIndices;
  final bool showEnergy;
  final bool showPinLogin;
  final bool showBiometric;

  // Trading config
  final List<String> leverages;
  final List<String> depositMethods;
  final String defaultCurrency;
  final double minDeposit;
  final double minWithdraw;

  // Compliance
  final String companyName;       // "AlphaTrade Ltd."
  final String regulatorLabel;    // "Regulated by FSC Mauritius"
  final String termsUrl;
  final String privacyUrl;

  const BrandConfig({
    required this.brandId,
    required this.appName,
    required this.tagline,
    required this.bundleIdAndroid,
    required this.bundleIdIOS,
    required this.apiBaseUrl,
    required this.wsUrl,
    required this.mt5ApiUrl,
    required this.webAppUrl,
    required this.primaryColor,
    required this.primaryLightColor,
    required this.primaryLighterColor,
    required this.accentColor,
    this.logoIconAsset = 'assets/icons/logo.png',
    required this.supportEmail,
    required this.supportUrl,
    this.showCopyTrading = true,
    this.showMamPamm = true,
    this.showCrypto = true,
    this.showIndices = true,
    this.showEnergy = true,
    this.showPinLogin = true,
    this.showBiometric = true,
    this.leverages = const ['1:1','1:10','1:25','1:50','1:100','1:200','1:500'],
    this.depositMethods = const [
      'Bank Transfer', 'Credit / Debit Card', 'Crypto (USDT)', 'UPI', 'Skrill', 'Neteller',
    ],
    this.defaultCurrency = 'USD',
    this.minDeposit = 100.0,
    this.minWithdraw = 10.0,
    required this.companyName,
    required this.regulatorLabel,
    required this.termsUrl,
    required this.privacyUrl,
  });

  // Theme built from brand colors
  ThemeData get theme {
    final fontFamily = GoogleFonts.inter().fontFamily;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: primaryLighterColor,
        error: const Color(0xFFE53935),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF1A1033),
      ),
      fontFamily: fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1033),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F7FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E0F5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E0F5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935))),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: const Color(0xFF8E82B0),
        indicatorColor: primaryColor,
        dividerColor: const Color(0xFFE5E0F5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primaryColor : const Color(0xFF8E82B0)),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primaryLighterColor : const Color(0xFFEDE9FE)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE5E0F5), thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryColor, primaryLightColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
