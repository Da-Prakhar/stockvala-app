import 'package:flutter/material.dart';
import '../brand_config.dart';

const nexustradeBrand = BrandConfig(
  brandId: 'nexustrade',
  appName: 'NexusTrade',
  tagline: 'The Future of Trading.',
  bundleIdAndroid: 'com.nexustrade.app',
  bundleIdIOS: 'com.nexustrade.app',
  apiBaseUrl: 'https://api.nexustrade.io/v2',
  wsUrl: 'wss://stream.nexustrade.io/ws',
  mt5ApiUrl: 'https://mt5.nexustrade.io/api',
  webAppUrl: 'https://app.nexustrade.io',
  primaryColor: Color(0xFF00897B),       // Teal
  primaryLightColor: Color(0xFF26A69A),
  primaryLighterColor: Color(0xFFE0F2F1),
  accentColor: Color(0xFF00BCD4),
  supportEmail: 'support@nexustrade.io',
  supportUrl: 'https://support.nexustrade.io',
  companyName: 'NexusTrade Global Ltd.',
  regulatorLabel: 'Regulated by CySEC',
  termsUrl: 'https://nexustrade.io/terms',
  privacyUrl: 'https://nexustrade.io/privacy',
  showCopyTrading: true,
  showMamPamm: true,
  showCrypto: true,
  showIndices: true,
  showEnergy: true,
  minDeposit: 200.0,
  minWithdraw: 25.0,
  leverages: ['1:1', '1:10', '1:25', '1:50', '1:100', '1:200', '1:500'],
  depositMethods: [
    'Bank Transfer', 'Credit / Debit Card', 'Crypto (USDT)', 'Skrill', 'Neteller', 'PayPal',
  ],
);
