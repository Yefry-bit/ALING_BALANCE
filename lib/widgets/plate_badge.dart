import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Placa del vehículo con el estilo de las placas colombianas: amarilla para
/// particulares y camionetas, blanca para taxis (servicio público). Letras
/// negras y borde oscuro.
class PlateBadge extends StatelessWidget {
  const PlateBadge({
    super.key,
    required this.plate,
    this.vehicleType,
    this.small = false,
  });

  final String plate;

  /// Tipo de vehículo ("Particular", "Taxi", "Camioneta"). Define el color.
  final String? vehicleType;
  final bool small;

  static Color colorFor(String? vehicleType) =>
      vehicleType?.trim().toLowerCase() == 'taxi'
      ? AppColors.plateTaxi
      : AppColors.plate;

  @override
  Widget build(BuildContext context) {
    final color = colorFor(vehicleType);
    final type = vehicleType?.trim();

    return Tooltip(
      message: type == null || type.isEmpty ? plate : '$plate · $type',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 7 : 10,
          vertical: small ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(small ? 5 : 7),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 1.6),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 10),
          ],
        ),
        child: Text(
          plate,
          style: TextStyle(
            color: const Color(0xFF111111),
            fontWeight: FontWeight.w900,
            fontSize: small ? 12 : 15,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}
