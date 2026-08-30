import 'package:flutter/material.dart';
import '../brand_config.dart';

/// RhynoFX — live V7 deployment (api.rhynofx.com).
/// Run with:  flutter run --dart-define=BRAND=rhynofx
const rhynofxBrand = BrandConfig(
  brandId: 'rhynofx',
  appName: 'RhynoFX',
  tagline: 'Trade with Power.',
  bundleIdAndroid: 'com.rhynofx.app',
  bundleIdIOS: 'com.rhynofx.app',
  apiBaseUrl: 'https://api.rhynofx.com/api',
  wsUrl: 'https://api.rhynofx.com',
  mt5ApiUrl: 'https://api.rhynofx.com/api',
  webAppUrl: 'https://app.rhynofx.com',
  primaryColor: Color(0xFFF59E0B),
  primaryLightColor: Color(0xFFFBBF24),
  primaryLighterColor: Color(0xFFFEF3C7),
  accentColor: Color(0xFFD97706),
  supportEmail: 'support@rhynofx.com',
  supportUrl: 'https://rhynofx.com',
  companyName: 'RhynoFX Ltd.',
  regulatorLabel: '',
  termsUrl: 'https://rhynofx.com/terms',
  privacyUrl: 'https://rhynofx.com/privacy',
  showCopyTrading: true,
  showMamPamm: true,
  showCrypto: true,
  showIndices: true,
  showEnergy: true,
  minDeposit: 100.0,
  minWithdraw: 10.0,
);
