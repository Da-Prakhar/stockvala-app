import 'package:flutter/material.dart';

class AppColors {
  // ─── Brand purple ─────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF7C3AED);   // vivid purple
  static const Color primaryLight   = Color(0xFF8B5CF6);   // medium purple
  static const Color primaryLighter = Color(0xFFEDE9FE);   // very light purple tint
  static const Color accent         = Color(0xFF6B21D9);   // deep purple
  static const Color gold           = Color(0xFFD97706);   // warm gold

  // ─── Light backgrounds ────────────────────────────────────────────────────
  static const Color bg100  = Color(0xFFF5F3FF);   // scaffold — lightest lavender
  static const Color bg200  = Color(0xFFFFFFFF);   // panels / header / sheets — white
  static const Color bg300  = Color(0xFFFFFFFF);   // list cards — white
  static const Color bg400  = Color(0xFFEDE9FE);   // elevated / hover — soft purple
  static const Color bg500  = Color(0xFFE8E3FF);   // input fills — light purple
  static const Color bgGlass= Color(0x267C3AED);   // frosted purple glass

  // ─── Text (on light backgrounds) ─────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF120D2E);   // near-black (purple tint)
  static const Color textSecondary = Color(0xFF4E4872);   // medium purple-gray
  static const Color textMuted     = Color(0xFF9490B0);   // muted lavender-gray
  static const Color textDisabled  = Color(0xFFC0BCE0);

  // ─── Trading ──────────────────────────────────────────────────────────────
  static const Color bullish   = Color(0xFF059669);   // rich emerald green ↑
  static const Color bearish   = Color(0xFFDC2626);   // rich red ↓
  static const Color bullishBg = Color(0xFFECFDF5);   // light green chip bg
  static const Color bearishBg = Color(0xFFFEF2F2);   // light red chip bg

  // ─── Status ───────────────────────────────────────────────────────────────
  static const Color success   = Color(0xFF059669);
  static const Color error     = Color(0xFFDC2626);
  static const Color warning   = Color(0xFFD97706);
  static const Color info      = Color(0xFF7C3AED);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color errorBg   = Color(0xFFFEF2F2);
  static const Color warningBg = Color(0xFFFFFBEB);

  // ─── Borders ──────────────────────────────────────────────────────────────
  static const Color border      = Color(0xFFE5E0F5);   // soft lavender border
  static const Color borderLight = Color(0xFFF0ECF8);
  static const Color borderFocus = Color(0xFF7C3AED);   // purple on focus

  // ─── Chart ────────────────────────────────────────────────────────────────
  static const Color chartGrid  = Color(0xFFF0ECF8);
  static const Color chartCross = Color(0xFFC0BCE0);

  // ─── MT5 price colors ─────────────────────────────────────────────────────
  static const Color bidColor = Color(0xFFDC2626);
  static const Color askColor = Color(0xFF059669);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6B21D9), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
  );
  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFF5F3FF), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF6B21D9), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
