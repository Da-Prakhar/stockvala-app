import 'package:flutter/material.dart';
import '../brand_config.dart';

const alphatradeBrand = BrandConfig(
  brandId: 'alphatrade',
  appName: 'AlphaTrade',
  tagline: 'Trade Smarter. Win Bigger.',
  bundleIdAndroid: 'com.alphatrade.app',
  bundleIdIOS: 'com.alphatrade.app',
  apiBaseUrl: 'https://api.alphatrade.com/v2',
  wsUrl: 'wss://stream.alphatrade.com/ws',
  mt5ApiUrl: 'https://mt5.alphatrade.com/api',
  webAppUrl: 'https://app.alphatrade.com',
  primaryColor: Color(0xFF0056D2),       // Bold blue
  primaryLightColor: Color(0xFF4A90E2),
  primaryLighterColor: Color(0xFFE8F0FE),
  accentColor: Color(0xFF1A73E8),
  supportEmail: 'support@alphatrade.com',
  supportUrl: 'https://support.alphatrade.com',
  companyName: 'AlphaTrade Ltd.',
  regulatorLabel: 'Regulated by FSC Mauritius',
  termsUrl: 'https://alphatrade.com/terms',
  privacyUrl: 'https://alphatrade.com/privacy',
  showCopyTrading: true,
  showMamPamm: true,
  showCrypto: true,
  showIndices: true,
  showEnergy: false,
  minDeposit: 250.0,
  minWithdraw: 50.0,
  leverages: ['1:1', '1:10', '1:50', '1:100', '1:200', '1:500'],
  depositMethods: [
    'Bank Transfer', 'Credit / Debit Card', 'Crypto (USDT)', 'Skrill', 'Neteller',
  ],
);
