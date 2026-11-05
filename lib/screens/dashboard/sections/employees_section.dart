import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/employee.dart';
import '../../../state/workshop_controller.dart';
import '../../../widgets/employee_card.dart';
import '../../../widgets/empty_module.dart';
import '../../../widgets/section_header.dart';
import '../../../core/navigation/app_section.dart';

/// Sección "Empleados": lista del personal y botón para registrar uno nuevo.
class EmployeesSection extends StatelessWidget {
  const EmployeesSection({
    super.key,
    required this.controller,
    required this.onNewEmployee,
    required this.onToggleActive,
  });

  final WorkshopController controller;
  final VoidCallback onNewEmployee;
  final ValueChanged<Employee> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final employees = controller.employees;
    final commissionById = {
      for (final item in controller.commissionsByEmployee)
        item.employeeId: item,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: AppSection.empleados.icon,
          title: AppSection.empleados.title,
          description: AppSection.empleados.description,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '${employees.length} empleados registrados',
                style: const TextStyle(color: AppColors.secondaryText),
              ),
            ),
            FilledButton.icon(
              onPressed: onNewEmployee,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nuevo empleado'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (employees.isEmpty)
          const EmptyModule(
            icon: Icons.groups_rounded,
            title: 'No hay empleados registrados',
            description: 'Pulsa “Nuevo empleado” para registrar al primero.',
          ),
        for (final employee in employees)
          EmployeeCard(
            employee: employee,
            commission: commissionById[employee.id],
            onToggleActive: () => onToggleActive(employee),
          ),
      ],
    );
  }
}
