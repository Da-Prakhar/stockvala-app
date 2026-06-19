import 'brand_config.dart';
import 'brands/stockvala.dart';
import 'brands/alphatrade.dart';
import 'brands/goldfx.dart';
import 'brands/nexustrade.dart';

/// Brand ID injected at build time via:
///   flutter run  --dart-define=BRAND=alphatrade
///   flutter build apk --dart-define=BRAND=goldfx --flavor goldfx
///
/// Defaults to 'stockvala' when not specified.
const _activeBrandId = String.fromEnvironment('BRAND', defaultValue: 'stockvala');

const _registry = <String, BrandConfig>{
  'stockvala':  stockvalaBrand,
  'alphatrade': alphatradeBrand,
  'goldfx':     goldfxBrand,
  'nexustrade': nexustradeBrand,
};

/// Single access point for all brand-specific configuration.
/// Use everywhere instead of hardcoded strings/colors/URLs.
///
/// Examples:
///   AppConfig.brand.appName        → "AlphaTrade"
///   AppConfig.brand.primaryColor   → Color(0xFF0056D2)
///   AppConfig.brand.apiBaseUrl     → "https://api.alphatrade.com/v2"
///   AppConfig.brand.showCopyTrading → false
class AppConfig {
  // Runtime lookup — map access can't be compile-time const
  static BrandConfig get brand => _registry[_activeBrandId] ?? stockvalaBrand;

  // Convenience shortcuts
  static String get appName      => brand.appName;
  static String get tagline      => brand.tagline;
  static String get apiBaseUrl   => brand.apiBaseUrl;
  static String get wsUrl        => brand.wsUrl;
  static String get mt5ApiUrl    => brand.mt5ApiUrl;
  static String get supportEmail => brand.supportEmail;

  // Feature flags
  static bool get showCopyTrading => brand.showCopyTrading;
  static bool get showMamPamm     => brand.showMamPamm;
  static bool get showCrypto      => brand.showCrypto;

  // Debug helper: all registered brands
  static Map<String, BrandConfig> get allBrands => Map.unmodifiable(_registry);
}
