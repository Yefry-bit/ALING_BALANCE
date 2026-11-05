/// Resumen de trabajos y comisión de un empleado.
class EmployeeCommission {
  const EmployeeCommission({
    required this.employeeId,
    required this.employeeName,
    required this.assignedCount,
    required this.finishedCount,
    required this.commission,
  });

  final int employeeId;
  final String employeeName;

  /// Servicios asignados al empleado (en proceso y terminados).
  final int assignedCount;

  /// Servicios terminados; solo estos generan comisión.
  final int finishedCount;

  /// Comisión acumulada en pesos.
  final int commission;
}
