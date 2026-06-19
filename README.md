# StockVala Mobile App

A white-label Flutter trading app with MT5 integration. One codebase, multiple brands — swap brand at build time via `--dart-define=BRAND=<brandId>`.

---

## What It Is

StockVala is a full-featured mobile trading platform that connects to an MT5 broker backend. It supports live price streaming, trade execution, deposits/withdrawals, KYC, copy trading, MAM/PAMM, and more — all configurable per broker brand.

---

## Features

### Auth & Security
- Email + OTP registration and login
- 2FA support (email OTP)
- PIN login (set on first login, used on subsequent opens)
- Biometric login (Face ID / Fingerprint via `local_auth`)
- Secure token storage with `flutter_secure_storage`
- Session management with auto-logout

### Trading
- Live MT5 account balance, equity, margin, free margin
- Real-time price streaming via WebSocket
- Place, modify, and close trades
- Candlestick charts (`candlesticks` + `syncfusion_flutter_charts`)
- Trade history and open positions
- Multiple leverage options per brand

### Portfolio & Markets
- Portfolio overview with P&L
- Markets screen with live quotes
- Forex, Indices, Crypto, Energy (toggleable per brand)

### Finance
- Deposit screen with multiple payment methods (Bank Transfer, Card, USDT, UPI, Skrill, Neteller)
- Withdrawal screen with minimum amount enforcement
- Transaction history

### KYC
- Multi-step KYC flow: Personal Info → Document Upload → Selfie → Risk Profile → Success
- Camera capture and image picker
- Image cropping support

### Copy Trading
- Browse and follow signal providers
- Manage copy positions

### MAM / PAMM
- View and join MAM/PAMM funds
- Performance stats

### Notifications
- Firebase push notifications (FCM)
- In-app notification centre

### Profile
- Edit personal details
- Change password
- App settings

### White-Label / Multi-Brand
- Full brand config per client: colors, logo, app name, API URLs, feature flags, compliance text
- Built-in brands: StockVala, AlphaTrade, GoldFX, NexusTrade
- Switch brand at build: `flutter run --dart-define=BRAND=alphatrade`

---

## Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Language | Dart | `>=3.3.0 <4.0.0` |
| Framework | Flutter | SDK |
| State Management | flutter_bloc + Provider | `8.1.5` / `6.1.2` |
| Navigation | go_router | `14.2.7` |
| HTTP Client | Dio | `5.4.3` |
| WebSocket | web_socket_channel + socket_io_client | `3.0.1` / `3.0.2` |
| Local Storage | flutter_secure_storage + Hive + SharedPreferences | `9.2.2` / `1.1.0` / `2.3.2` |
| Charts | Syncfusion Flutter Charts + candlesticks + fl_chart | `27.1.48` / `2.1.0` / `0.69.0` |
| Notifications | Firebase Messaging + flutter_local_notifications | `15.1.3` / `17.2.2` |
| Auth | local_auth (biometric) + pin_code_fields | `2.3.0` / `8.0.1` |
| KYC | camera + image_picker + image_cropper | `0.11.0` / `1.1.2` / `8.0.2` |
| UI | glassmorphism + shimmer + lottie + flutter_animate | latest |
| Fonts | Google Fonts (Inter) | `6.2.1` |
| Firebase | firebase_core + firebase_messaging | `3.6.0` / `15.1.3` |

---

## Platform Support

| Platform | Status |
|---|---|
| Android | ✅ |
| iOS | ✅ |
| Web | ✅ (basic) |

---

## Project Structure

```
lib/
├── config/              # Brand config & app config
│   └── brands/          # Per-brand definitions (stockvala, alphatrade, goldfx, nexustrade)
├── core/
│   ├── constants/       # Routes, app constants
│   ├── models/          # MT5 account model
│   ├── network/         # Dio API client, WebSocket service
│   ├── providers/       # MT5 account store
│   ├── services/        # Biometric, MT5 service
│   ├── storage/         # Secure storage wrapper
│   └── theme/           # Colors, text styles, app theme
├── features/
│   ├── auth/            # Login, Register, OTP, PIN, Biometric, Splash, Onboarding
│   ├── home/            # Main shell + home screen
│   ├── trading/         # Trade execution, positions, history
│   ├── markets/         # Live quotes
│   ├── portfolio/       # P&L overview
│   ├── deposit/         # Deposit & withdrawal
│   ├── finance/         # Finance repository
│   ├── kyc/             # KYC multi-step flow
│   ├── copy_trading/    # Copy trading
│   ├── mam_pamm/        # MAM/PAMM funds
│   ├── notifications/   # Push + in-app notifications
│   ├── history/         # Trade history
│   └── profile/         # User profile & settings
└── shared/
    └── widgets/         # Reusable UI components (buttons, inputs, glass card)
```

---

## Build

```bash
# Default brand (StockVala)
flutter run

# Specific brand
flutter run --dart-define=BRAND=alphatrade

# Release APK
flutter build apk --dart-define=BRAND=stockvala --release

# Release iOS
flutter build ipa --dart-define=BRAND=stockvala --release
```

---

## Backend

Connects to the StockVala Node.js backend (`stockvala-v2` / `stockvala-v3`) with MT5 gateway integration. Configure API URLs in the brand config file.
