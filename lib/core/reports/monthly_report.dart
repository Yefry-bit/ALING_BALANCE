import '../../models/commission_payment.dart';
import '../../models/expense.dart';
import '../../models/monthly_summary.dart';
import '../../models/service_record.dart';
import '../../state/workshop_controller.dart';
import '../utils/formatters.dart';

/// Datos del resumen mensual que se exporta a PDF o Excel. Son los mismos
/// que muestra la sección Contabilidad.
class MonthlyReport {
  const MonthlyReport({
    required this.year,
    required this.month,
    required this.summary,
    required this.recentMonths,
    required this.categories,
    required this.expenses,
    required this.commissions,
    required this.services,
    required this.commissionOf,
    required this.commissionPercent,
    required this.generatedAt,
  });

  factory MonthlyReport.fromController(
    WorkshopController controller,
    int year,
    int month, {
    DateTime? now,
  }) {
    return MonthlyReport(
      year: year,
      month: month,
      summary: controller.monthlySummary(year, month),
      recentMonths: controller.recentMonths(6, DateTime(year, month)),
      categories: controller.expensesByCategory(year, month),
      expenses: controller.expensesIn(year, month),
      commissions: controller.commissionsForMonth(year, month),
      services: controller.servicesFinishedIn(year, month),
      commissionOf: controller.commissionFor,
      commissionPercent: (WorkshopController.commissionRate * 100).round(),
      generatedAt: now ?? DateTime.now(),
    );
  }

  final int year;
  final int month;
  final MonthlySummary summary;

  /// Seis meses terminando en el mes del informe (del más antiguo al último).
  final List<MonthlySummary> recentMonths;

  /// Gastos por categoría, de mayor a menor.
  final List<MapEntry<String, int>> categories;
  final List<Expense> expenses;
  final List<MonthlyCommission> commissions;

  /// Servicios terminados que cuentan como ingreso del mes.
  final List<ServiceRecord> services;

  final int Function(ServiceRecord service) commissionOf;
  final int commissionPercent;
  final DateTime generatedAt;

  /// "Noviembre 2026"
  String get monthName => formatMonth(year, month);

  /// "AlingBalance_resumen_2026-11"
  String get fileName =>
      'AlingBalance_resumen_$year-${month.toString().padLeft(2, '0')}';

  int get pendingCommissions =>
      commissions.fold(0, (total, c) => total + c.pendingAmount);

  /// "38%" o "—" si no hubo ingresos.
  String get marginText =>
      summary.income == 0 ? '—' : '${(summary.margin * 100).round()}%';
}
