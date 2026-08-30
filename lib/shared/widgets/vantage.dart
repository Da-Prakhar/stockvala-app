import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// V2 shared primitives — the Vantage-style visual language.
/// Flat colors, soft gray cards, orange CTAs, floating pill nav. No blur.

// ── Full-width pill button (dark variant for Copy/Check-In/Log Out) ─────────
class VPill extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool dark;
  final bool loading;
  const VPill({super.key, required this.label, this.onPressed, this.dark = false, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: !enabled ? AppColors.bg300 : (dark ? AppColors.ink : AppColors.primary),
          borderRadius: BorderRadius.circular(28),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: enabled ? onPressed : null,
          child: Center(
            child: loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                : Text(label,
                    style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600,
                      color: enabled ? Colors.white : AppColors.textMuted,
                    )),
          ),
        ),
      ),
    );
  }
}

// ── Soft gray card ──────────────────────────────────────────────────────────
class VCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  const VCard({super.key, required this.child,
      this.padding = const EdgeInsets.all(16), this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.bg200,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
  }
}

// ── Text tabs with the short black underline ────────────────────────────────
class VTextTabs extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onTap;
  final double fontSize;
  final bool big; // 22w800 top-level (Watchlist | Explore) vs 15w600 section tabs
  const VTextTabs({super.key, required this.tabs, required this.selected,
      required this.onTap, this.big = false, this.fontSize = 0});

  @override
  Widget build(BuildContext context) {
    final fs = fontSize > 0 ? fontSize : (big ? 22.0 : 15.0);
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++)
          GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(right: big ? 22 : 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(tabs[i],
                    style: TextStyle(
                      fontSize: fs,
                      fontWeight: i == selected ? FontWeight.w800 : FontWeight.w600,
                      color: i == selected ? AppColors.textPrimary : AppColors.textMuted,
                    )),
                const SizedBox(height: 5),
                Container(
                  height: 3, width: 26,
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.textPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}

// ── Chip tabs (Most Copied / Highest Return …) ──────────────────────────────
class VChipTabs extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onTap;
  const VChipTabs({super.key, required this.tabs, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: i == selected ? AppColors.bg300 : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tabs[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                      color: i == selected ? AppColors.textPrimary : AppColors.textMuted,
                    )),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Section header (bold + chevron) ─────────────────────────────────────────
class VSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;
  const VSectionHeader(this.title, {super.key, this.onMore});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onMore,
        behavior: HitTestBehavior.opaque,
        child: Row(children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ),
          if (onMore != null)
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 24),
        ]),
      );
}

// ── Mini sparkline (red/green) ──────────────────────────────────────────────
class Sparkline extends StatelessWidget {
  final List<double> values;
  final bool bullish;
  final double width, height;
  const Sparkline({super.key, required this.values, required this.bullish,
      this.width = 64, this.height = 26});

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(width: width, height: height);
    return CustomPaint(
      size: Size(width, height),
      painter: _SparkPainter(values, bullish ? AppColors.bullish : AppColors.bearish),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> v;
  final Color color;
  _SparkPainter(this.v, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final lo = v.reduce((a, b) => a < b ? a : b);
    final hi = v.reduce((a, b) => a > b ? a : b);
    final range = (hi - lo) == 0 ? 1.0 : hi - lo;
    final path = Path();
    for (var i = 0; i < v.length; i++) {
      final x = size.width * i / (v.length - 1);
      final y = size.height - ((v[i] - lo) / range) * (size.height - 3) - 1.5;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.v != v || old.color != color;
}

// ── Circular symbol icon (emoji / lettermark on colored bg) ─────────────────
class SymbolAvatar extends StatelessWidget {
  final String symbol;
  final double size;
  const SymbolAvatar(this.symbol, {super.key, this.size = 40});

  static const _flags = {
    'EUR': '🇪🇺', 'USD': '🇺🇸', 'GBP': '🇬🇧', 'JPY': '🇯🇵', 'AUD': '🇦🇺',
    'CAD': '🇨🇦', 'CHF': '🇨🇭', 'NZD': '🇳🇿', 'CNH': '🇨🇳', 'SGD': '🇸🇬',
    'HKD': '🇭🇰', 'INR': '🇮🇳',
  };

  (String, Color) get _face {
    final s = symbol.toUpperCase();
    if (s.startsWith('XAU')) return ('🥇', const Color(0xFFFDF1DC));
    if (s.startsWith('XAG')) return ('🥈', const Color(0xFFF0F0F2));
    if (s.startsWith('XPT') || s.startsWith('XPD')) return ('⚪', const Color(0xFFF0F0F2));
    if (s.startsWith('BTC')) return ('₿', const Color(0xFFF7931A));
    if (s.startsWith('ETH')) return ('Ξ', const Color(0xFF627EEA));
    if (s.contains('OIL') || s.startsWith('XTI') || s.startsWith('XBR') || s.contains('BRENT')) {
      return ('🛢️', const Color(0xFFEDEDF0));
    }
    if (s.startsWith('US30') || s.startsWith('DJ')) return ('D', const Color(0xFF29ABE2));
    if (s.startsWith('NAS') || s.startsWith('USTEC') || s.startsWith('US100')) return ('100', const Color(0xFF1DA7C4));
    if (s.startsWith('SPX') || s.startsWith('US500') || s.startsWith('SP500')) return ('500', const Color(0xFFB2354B));
    if (s.startsWith('GER') || s.startsWith('DAX')) return ('🇩🇪', const Color(0xFFEDEDF0));
    if (s.startsWith('UK100') || s.startsWith('FTSE')) return ('🇬🇧', const Color(0xFFEDEDF0));
    if (s.startsWith('JPN') || s.startsWith('NIK')) return ('🇯🇵', const Color(0xFFEDEDF0));
    if (s.startsWith('HK')) return ('🇭🇰', const Color(0xFFEDEDF0));
    final base = s.length >= 3 ? s.substring(0, 3) : s;
    final flag = _flags[base];
    if (flag != null) return (flag, const Color(0xFFEFF1F4));
    return (s.isEmpty ? '?' : s.substring(0, 1), const Color(0xFFEFF1F4));
  }

  @override
  Widget build(BuildContext context) {
    final (face, bg) = _face;
    final isLetter = RegExp(r'^[A-Z0-9?₿Ξ]+$').hasMatch(face);
    final onDark = bg.computeLuminance() < 0.5;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(face,
          style: TextStyle(
            fontSize: isLetter ? (face.length > 2 ? size * .28 : size * .42) : size * .5,
            fontWeight: FontWeight.w800,
            color: onDark ? Colors.white : AppColors.textPrimary,
            height: 1,
          )),
    );
  }
}

// ── Symbol list row ─────────────────────────────────────────────────────────
class SymbolRow extends StatelessWidget {
  final String symbol;
  final String subtitle;
  final String price;
  final double changePct;
  final List<double> spark;
  final bool marketClosed;
  final VoidCallback? onTap;
  const SymbolRow({super.key, required this.symbol, required this.subtitle,
      required this.price, required this.changePct, this.spark = const [],
      this.marketClosed = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Flat day-change (weekend) → color by the sparkline trend instead.
    final up = changePct != 0
        ? changePct > 0
        : (spark.length > 1 ? spark.last >= spark.first : true);
    final cc = up ? AppColors.bullish : AppColors.bearish;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(children: [
          SymbolAvatar(symbol),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  child: Text(symbol,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ),
                if (marketClosed) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.nightlight_round, size: 12, color: AppColors.textMuted),
                ],
              ]),
              const SizedBox(height: 2),
              Text(subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ]),
          ),
          if (spark.length > 1) Sparkline(values: spark, bullish: up),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text('${up ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cc)),
          ]),
        ]),
      ),
    );
  }
}

// ── Quick action circle ─────────────────────────────────────────────────────
class VQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  const VQuickAction({super.key, required this.icon, required this.label,
      required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 54, height: 54,
                decoration: const BoxDecoration(color: AppColors.bg300, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.textPrimary, size: 24),
              ),
              if (badge != null)
                Positioned(
                  top: -7, left: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(badge!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, maxLines: 2,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.15)),
          ]),
        ),
      );
}

// ── Floating pill bottom nav ────────────────────────────────────────────────
class VBottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const VBottomNav({super.key, required this.current, required this.onTap});

  static const _items = [
    (Icons.show_chart_rounded, 'Home'),
    (Icons.bar_chart_rounded, 'Markets'),
    (Icons.swap_horiz_rounded, 'Trade'),
    (Icons.data_usage_rounded, 'Earn'),
    (Icons.pie_chart_rounded, 'Funds'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 40, height: 32,
                      decoration: BoxDecoration(
                        color: i == current ? AppColors.bg300 : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_items[i].$1, size: 21,
                          color: i == current ? AppColors.textPrimary : const Color(0xFF4B4F55)),
                    ),
                    const SizedBox(height: 2),
                    Text(_items[i].$2,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                          color: i == current ? AppColors.textPrimary : const Color(0xFF4B4F55),
                        )),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Dashed-underline label (Vantage info rows) ─────────────────────────────
class VInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const VInfoRow(this.label, this.value, {super.key, this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dashed,
                  decorationColor: AppColors.textDisabled,
                )),
          ),
          Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary)),
        ]),
      );
}
