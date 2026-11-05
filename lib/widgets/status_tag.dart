import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/service_status.dart';

/// Etiqueta con el estado de un servicio (icono + texto, no solo color).
class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.status});

  final ServiceStatus status;

  @override
  Widget build(BuildContext context) {
    final finished = status == ServiceStatus.finished;
    final color = finished ? AppColors.accent : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            finished ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
