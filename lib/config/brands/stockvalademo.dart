import 'package:flutter/material.dart';
import '../brand_config.dart';

/// StockVala Demo — points at the bnrfx V7 demo deployment.
/// Run with:  flutter run --dart-define=BRAND=stockvalademo
///
/// NOTE: this backend currently has no MT5 price feed (its gateway reports
/// 0 symbols), so Markets/charts/Trade stay empty. Auth, accounts, deposits,
/// KYC, copy trading and funds are all served normally.
const stockvalaDemoBrand = BrandConfig(
  brandId: 'stockvalademo',
  appName: 'StockVala Demo',
  tagline: 'Trade. Invest. Grow.',
  bundleIdAndroid: 'com.stockvala.demo',
  bundleIdIOS: 'com.stockvala.demo',
  apiBaseUrl: 'https://api.v7.bnrfx.com/api',
  wsUrl: 'https://api.v7.bnrfx.com',
  mt5ApiUrl: 'https://api.v7.bnrfx.com/api',
  webAppUrl: 'https://user.v7.bnrfx.com',
  primaryColor: Color(0xFFFF6118),
  primaryLightColor: Color(0xFFFF7A3D),
  primaryLighterColor: Color(0xFFFFEDE3),
  accentColor: Color(0xFFE84E00),
  supportEmail: 'support@stockvala.com',
  supportUrl: 'https://stockvala.com',
  companyName: 'StockVala Technologies Ltd.',
  regulatorLabel: 'Demo Environment',
  termsUrl: 'https://stockvala.com/terms',
  privacyUrl: 'https://stockvala.com/privacy',
  showCopyTrading: true,
  showMamPamm: true,
  showCrypto: true,
  showIndices: true,
  showEnergy: true,
  minDeposit: 100.0,
  minWithdraw: 10.0,
);
