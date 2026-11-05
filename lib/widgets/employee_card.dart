import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/employee.dart';
import '../models/employee_commission.dart';
import '../core/theme/app_decorations.dart';

/// Tarjeta con los datos de un empleado y el botón para activarlo o
/// desactivarlo.
class EmployeeCard extends StatelessWidget {
  const EmployeeCard({
    super.key,
    required this.employee,
    required this.onToggleActive,
    this.commission,
  });

  final Employee employee;

  /// Resumen de comisiones del empleado (opcional).
  final EmployeeCommission? commission;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final active = employee.active;
    final phone = employee.phone.isNotEmpty ? employee.phone : 'No registrado';
    final document = employee.document.isNotEmpty
        ? employee.document
        : 'No registrado';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.panel(radius: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            child: const Icon(Icons.person, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Documento: $document',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Teléfono: $phone',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                if (commission != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Terminados: ${commission!.finishedCount} de '
                    '${commission!.assignedCount} · '
                    'Comisión: ${formatMoney(commission!.commission)}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  active ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: active ? AppColors.accent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: active ? 'Desactivar empleado' : 'Activar empleado',
            onPressed: onToggleActive,
            icon: Icon(
              active ? Icons.person_off_outlined : Icons.person_add_alt_1,
              color: active ? Colors.orangeAccent : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
