import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/employee.dart';
import '../models/service_record.dart';
import '../models/service_status.dart';
import 'form_error_banner.dart';
import 'plate_badge.dart';

/// Cambia el empleado que realiza un servicio ya registrado. La comisión
/// pasa al empleado nuevo. Devuelve `true` si se guardó.
class AssignEmployeeDialog extends StatefulWidget {
  const AssignEmployeeDialog({
    super.key,
    required this.service,
    required this.employees,
    required this.commission,
    required this.onSubmit,
  });

  final ServiceRecord service;

  /// Empleados activos.
  final List<Employee> employees;

  /// Comisión que genera el servicio (para mostrarla).
  final int commission;

  final Future<String?> Function(int employeeId) onSubmit;

  @override
  State<AssignEmployeeDialog> createState() => _AssignEmployeeDialogState();
}

class _AssignEmployeeDialogState extends State<AssignEmployeeDialog> {
  late int? _employeeId =
      widget.employees.any((e) => e.id == widget.service.employeeId)
      ? widget.service.employeeId
      : null;
  bool _saving = false;
  String? _error;

  bool get _changed =>
      _employeeId != null && _employeeId != widget.service.employeeId;

  Future<void> _save() async {
    if (_saving || !_changed) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.onSubmit(_employeeId!);
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final finished = service.status == ServiceStatus.finished;
    const small = TextStyle(color: AppColors.secondaryText, fontSize: 12);

    return AlertDialog(
      backgroundColor: AppColors.panel,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Row(
        children: [
          Icon(Icons.swap_horiz_rounded, color: AppColors.accent),
          SizedBox(width: 10),
          Expanded(child: Text('Cambiar empleado')),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) FormErrorBanner(message: _error!),
              Row(
                children: [
                  PlateBadge(
                    plate: service.plate,
                    vehicleType: service.vehicleType,
                    small: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '#${service.operation} · ${service.service}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                service.employeeName.isEmpty
                    ? 'Ahora: sin empleado asignado'
                    : 'Ahora: ${service.employeeName}',
                style: small,
              ),
              const SizedBox(height: 16),
              if (widget.employees.isEmpty)
                const Text(
                  'No hay empleados activos. Regístralos en la sección '
                  'Empleados.',
                  style: TextStyle(color: AppColors.warning),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _employeeId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Empleado que realiza el servicio',
                    prefixIcon: Icon(Icons.engineering_outlined),
                  ),
                  items: [
                    for (final employee in widget.employees)
                      DropdownMenuItem(
                        value: employee.id,
                        child: Text(employee.name),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _employeeId = value),
                ),
              const SizedBox(height: 12),
              Text(
                finished
                    ? 'La comisión de este servicio '
                          '(${formatMoney(widget.commission)}) pasará al '
                          'empleado que elijas.'
                    : 'Cuando el servicio se termine, la comisión '
                          '(${formatMoney(widget.commission)}) será para el '
                          'empleado que elijas.',
                style: small,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving || !_changed ? null : _save,
          child: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}
