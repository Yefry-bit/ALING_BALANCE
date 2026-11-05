/// Resultado financiero de un mes.
///
/// - **Ingresos**: precio de los servicios *terminados* en el mes.
/// - **Comisiones**: lo que se paga a los empleados por esos servicios.
/// - **Gastos**: gastos registrados con fecha en el mes.
/// - **Ganancia**: ingresos − comisiones − gastos (puede ser negativa).
class MonthlySummary {
  const MonthlySummary({
    required this.year,
    required this.month,
    required this.income,
    required this.commissions,
    required this.expenses,
    required this.finishedServices,
  });

  final int year;

  /// 1 = enero … 12 = diciembre.
  final int month;
  final int income;
  final int commissions;
  final int expenses;
  final int finishedServices;

  /// Todo lo que sale: comisiones + gastos.
  int get outflow => commissions + expenses;

  int get profit => income - outflow;

  /// Margen sobre los ingresos (0 si no hubo ingresos).
  double get margin => income == 0 ? 0 : profit / income;
}
