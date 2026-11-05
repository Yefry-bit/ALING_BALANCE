import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Decoraciones reutilizables para que todas las pantallas compartan el
/// mismo estilo (paneles con degradado sutil, sombras y acentos).
abstract final class AppDecorations {
  /// Degradado de la marca (botones principales, logo, insignias).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accent, AppColors.accentBlue],
  );

  /// Panel principal: degradado leve de arriba-izquierda a abajo-derecha,
  /// borde fino y sombra suave para dar profundidad.
  static BoxDecoration panel({double radius = 18, Color? highlight}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            (highlight ?? AppColors.accent).withValues(alpha: 0.05),
            AppColors.panelHigh,
          ),
          AppColors.panel,
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlight?.withValues(alpha: 0.35) ?? AppColors.border,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  /// Forma equivalente a [panel] para usar con `Material` (cuando el panel
  /// contiene ListTile o InkWell).
  static ShapeBorder panelShape({double radius = 18}) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: AppColors.border),
    );
  }

  /// Fondo teñido con un color (insignias de iconos, etiquetas).
  static BoxDecoration tinted(Color color, {double radius = 12}) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withValues(alpha: 0.28)),
    );
  }

  /// Superficie hundida (filas dentro de un panel).
  static BoxDecoration inset({double radius = 12}) {
    return BoxDecoration(
      color: AppColors.background.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border),
    );
  }
}
