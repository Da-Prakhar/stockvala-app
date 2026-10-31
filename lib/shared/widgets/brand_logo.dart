import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../core/theme/app_colors.dart';

/// Brand wordmark. Uses the brand's artwork when it has any, otherwise draws
/// a text wordmark from the brand name — so a brand with no logo file never
/// displays another brand's logo.
class BrandLogo extends StatelessWidget {
  final bool onDark;
  final double height;
  const BrandLogo({super.key, this.onDark = false, this.height = 44});

  @override
  Widget build(BuildContext context) {
    final asset = onDark
        ? AppConfig.brand.logoDarkAsset
        : AppConfig.brand.logoLightAsset;
    if (asset != null) return Image.asset(asset, height: height);

    final name = AppConfig.brand.appName;
    final fg = onDark ? Colors.white : AppColors.textPrimary;
    // Last word (e.g. "Demo") is tinted so "StockVala Demo" reads as a mark.
    final parts = name.split(' ');
    final head = parts.length > 1 ? parts.sublist(0, parts.length - 1).join(' ') : name;
    final tail = parts.length > 1 ? parts.last : '';

    return FittedBox(
      child: RichText(
        text: TextSpan(
          text: head,
          style: TextStyle(
            fontSize: height * 0.62,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: fg,
          ),
          children: tail.isEmpty
              ? null
              : [
                  TextSpan(
                    text: ' $tail',
                    style: TextStyle(
                      fontSize: height * 0.62,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}
