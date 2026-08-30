import 'package:flutter/material.dart';

/// V2 — Vantage-style light design system.
/// Same token names as V1 so every screen keeps compiling; values remapped.
class AppColors {
  // ─── Brand orange ─────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFFFF6118);   // signature orange
  static const Color primaryLight   = Color(0xFFFF7A3D);
  static const Color primaryLighter = Color(0xFFFFEDE3);   // light orange chip bg
  static const Color accent         = Color(0xFFE84E00);   // deep orange
  static const Color gold           = Color(0xFFF7B500);   // chart MA yellow

  // Dark ink used for dark pills / onboarding surfaces
  static const Color ink            = Color(0xFF16181C);

  // ─── Light backgrounds ────────────────────────────────────────────────────
  static const Color bg100  = Color(0xFFFFFFFF);   // scaffold — white
  static const Color bg200  = Color(0xFFF5F5F7);   // cards / sheets — soft gray
  static const Color bg300  = Color(0xFFF3F4F6);   // inputs / chips
  static const Color bg400  = Color(0xFFEDEDF0);   // pressed / elevated gray
  static const Color bg500  = Color(0xFFF3F4F6);   // input fills
  static const Color bgGlass= Color(0x14000000);

  // ─── Text (on light backgrounds) ─────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111214);   // near-black
  static const Color textSecondary = Color(0xFF6F7378);   // gray
  static const Color textMuted     = Color(0xFF9CA0A6);   // light gray
  static const Color textDisabled  = Color(0xFFC6C9CE);

  // ─── Trading ──────────────────────────────────────────────────────────────
  static const Color bullish   = Color(0xFF0FA958);   // green ↑
  static const Color bearish   = Color(0xFFF23645);   // red ↓
  static const Color bullishBg = Color(0xFFE8F7EF);
  static const Color bearishBg = Color(0xFFFEECEE);

  // ─── Status ───────────────────────────────────────────────────────────────
  static const Color success   = Color(0xFF0FA958);
  static const Color error     = Color(0xFFF23645);
  static const Color warning   = Color(0xFFB98900);
  static const Color info      = Color(0xFFFF6118);
  static const Color successBg = Color(0xFFE8F7EF);
  static const Color errorBg   = Color(0xFFFEECEE);
  static const Color warningBg = Color(0xFFFDF6E3);   // pale-yellow notice banner

  // ─── Borders ──────────────────────────────────────────────────────────────
  static const Color border      = Color(0xFFECECEF);
  static const Color borderLight = Color(0xFFF4F4F6);
  static const Color borderFocus = Color(0xFFFF6118);

  // ─── Chart ────────────────────────────────────────────────────────────────
  static const Color chartGrid  = Color(0xFFF2F2F4);
  static const Color chartCross = Color(0xFFC6C9CE);
  static const Color maFast   = Color(0xFFF7B500);   // MA(5) yellow
  static const Color maMid    = Color(0xFFF23645);   // MA(10) red
  static const Color maSlow   = Color(0xFFC13CFF);   // MA(20) purple

  // ─── MT5 price colors ─────────────────────────────────────────────────────
  static const Color bidColor = Color(0xFFF23645);
  static const Color askColor = Color(0xFF0FA958);

  // ─── Gradients (kept for API compat — mostly flat now) ───────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6118), Color(0xFFFF7A3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6118), Color(0xFFFF8A50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF7B500), Color(0xFFFFCF40)],
  );
  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFF5F5F7), Color(0xFFF5F5F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF0B8A47), Color(0xFF0FA958)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
