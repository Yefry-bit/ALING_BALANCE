import 'package:flutter/material.dart';

/// Paleta de colores de AlingBalance (tema oscuro).
abstract final class AppColors {
  // Fondos, del más profundo al más elevado.
  static const Color background = Color(0xFF080D19);
  static const Color backgroundAlt = Color(0xFF0D1526);
  static const Color panel = Color(0xFF111A2C);
  static const Color panelHigh = Color(0xFF172238);
  static const Color border = Color(0xFF223049);

  // Marca: verde azulado con un degradado hacia azul.
  static const Color accent = Color(0xFF27D7B0);
  static const Color accentDeep = Color(0xFF12A386);
  static const Color accentBlue = Color(0xFF3B9EFF);

  // Texto.
  static const Color secondaryText = Color(0xFF9BAAC0);
  static const Color mutedText = Color(0xFF66768F);

  // Colores de apoyo para métricas y estados.
  static const Color warning = Color(0xFFFFBD69);
  static const Color info = Color(0xFF75A7FF);
  static const Color violet = Color(0xFFB69CFF);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color infoBanner = Color(0xFF122A33);

  /// Amarillo de las placas colombianas.
  static const Color plate = Color(0xFFF5C518);
  static const Color plateTaxi = Color(0xFFF4F4F1);
}
