import 'package:flutter/material.dart';
import '../brand_config.dart';

const goldfxBrand = BrandConfig(
  brandId: 'goldfx',
  appName: 'GoldFX',
  tagline: 'Gold Standard Trading.',
  bundleIdAndroid: 'com.goldfx.app',
  bundleIdIOS: 'com.goldfx.app',
  apiBaseUrl: 'https://api.goldfx.io/v2',
  wsUrl: 'wss://stream.goldfx.io/ws',
  mt5ApiUrl: 'https://mt5.goldfx.io/api',
  webAppUrl: 'https://app.goldfx.io',
  primaryColor: Color(0xFFB8860B),       // Dark golden
  primaryLightColor: Color(0xFFFFB800),
  primaryLighterColor: Color(0xFFFFF8E1),
  accentColor: Color(0xFFFF8C00),
  supportEmail: 'support@goldfx.io',
  supportUrl: 'https://support.goldfx.io',
  companyName: 'GoldFX Markets Ltd.',
  regulatorLabel: 'Regulated by VFSC Vanuatu',
  termsUrl: 'https://goldfx.io/terms',
  privacyUrl: 'https://goldfx.io/privacy',
  showCopyTrading: false,
  showMamPamm: true,
  showCrypto: false,
  showIndices: false,
  showEnergy: false,
  minDeposit: 500.0,
  minWithdraw: 100.0,
  leverages: ['1:1', '1:10', '1:25', '1:50', '1:100', '1:200'],
  depositMethods: ['Bank Transfer', 'Crypto (USDT)', 'Skrill'],
);
