import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_decorations.dart';

/// Icono dentro de un cuadro redondeado teñido (o con el degradado de la
/// marca si [brand] es `true`).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.accent,
    this.size = 44,
    this.brand = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool brand;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.3;

    return Container(
      width: size,
      height: size,
      decoration: brand
          ? BoxDecoration(
              gradient: AppDecorations.brandGradient,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            )
          : AppDecorations.tinted(color, radius: radius),
      child: Icon(
        icon,
        size: size * 0.52,
        color: brand ? AppColors.background : color,
      ),
    );
  }
}
