import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Fondo de la app: degradado oscuro con dos resplandores suaves de la marca.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.backgroundAlt, AppColors.background],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -160,
            right: -120,
            child: _Glow(color: AppColors.accent, size: 420),
          ),
          const Positioned(
            bottom: -200,
            left: -160,
            child: _Glow(color: AppColors.accentBlue, size: 480),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.13), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
