import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_section.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/employee_commission.dart';
import '../../../models/expense.dart';
import '../../../models/monthly_summary.dart';
import '../../../state/workshop_controller.dart';
import '../../../widgets/metric_card.dart';
import '../../../widgets/monthly_chart.dart';
import '../../../widgets/section_header.dart';
import '../../../core/theme/app_decorations.dart';

/// Sección "Contabilidad": dashboard financiero mensual.
///
/// Muestra, para el mes elegido, ingresos, gastos, comisiones y ganancia;
/// la evolución de los últimos 6 meses; los gastos por categoría y la lista
/// de gastos del mes; y las comisiones acumuladas por empleado.
class AccountingSection extends StatefulWidget {
  const AccountingSection({
    super.key,
    required this.controller,
    required this.isDesktop,
    required this.onNewExpense,
    required this.onDeleteExpense,
    this.now,
  });

  final WorkshopController controller;
  final bool isDesktop;

  /// Abre el formulario de gasto proponiendo una fecha del mes visible.
  final ValueChanged<DateTime> onNewExpense;
  final ValueChanged<Expense> onDeleteExpense;

  /// Fecha actual (se puede fijar en pruebas).
  final DateTime? now;

  @override
  State<AccountingSection> createState() => _AccountingSectionState();
}

class _AccountingSectionState extends State<AccountingSection> {
  static const int _chartMonths = 6;

  late final DateTime _currentMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = widget.now ?? DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selected = _currentMonth;
  }

  bool get _isCurrentMonth => _selected == _currentMonth;

  void _moveMonth(int delta) {
    final next = DateTime(_selected.year, _selected.month + delta);
    if (next.isAfter(_currentMonth)) return;
    setState(() => _selected = next);
  }

  /// El gráfico termina en el mes actual, salvo que se elija un mes más
  /// antiguo que la ventana: entonces la ventana termina en ese mes.
  DateTime get _chartEnd {
    final windowStart = DateTime(
      _currentMonth.year,
      _currentMonth.month - (_chartMonths - 1),
    );
    return _selected.isBefore(windowStart) ? _selected : _currentMonth;
  }

  /// Fecha propuesta para un gasto nuevo: hoy si se ve el mes actual; si no,
  /// el último día del mes que se está viendo.
  DateTime get _suggestedExpenseDate {
    if (_isCurrentMonth) return widget.now ?? DateTime.now();
    return DateTime(_selected.year, _selected.month + 1, 0);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isDesktop = widget.isDesktop;

    final summary = controller.monthlySummary(_selected.year, _selected.month);
    final previous = controller.monthlySummary(
      DateTime(_selected.year, _selected.month - 1).year,
      DateTime(_selected.year, _selected.month - 1).month,
    );
    final months = controller.recentMonths(_chartMonths, _chartEnd);
    final selectedIndex = months.indexWhere(
      (m) => m.year == _selected.year && m.month == _selected.month,
    );

    final categories = controller.expensesByCategory(
      _selected.year,
      _selected.month,
    );
    final expenses = controller.expensesIn(_selected.year, _selected.month);

    final breakdown = _Panel(
      title: 'Gastos por categoría',
      subtitle: formatMonth(_selected.year, _selected.month),
      child: _CategoryBreakdown(items: categories, total: summary.expenses),
    );
    final expenseList = _Panel(
      title: 'Gastos del mes',
      subtitle: '${expenses.length} registrado(s)',
      trailing: TextButton.icon(
        onPressed: () => widget.onNewExpense(_suggestedExpenseDate),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Agregar'),
      ),
      child: _ExpenseList(expenses: expenses, onDelete: widget.onDeleteExpense),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: AppSection.contabilidad.icon,
          title: AppSection.contabilidad.title,
          description: AppSection.contabilidad.description,
        ),
        _buildToolbar(),
        const SizedBox(height: 18),
        _buildMetrics(summary, previous, isDesktop),
        const SizedBox(height: 22),
        _Panel(
          title: 'Ingresos y egresos',
          subtitle:
              'Últimos $_chartMonths meses · la cifra bajo cada mes es '
              'la ganancia. Toca un mes para verlo en detalle.',
          child: MonthlyChart(
            months: months,
            selectedIndex: selectedIndex,
            onSelect: (index) => setState(
              () =>
                  _selected = DateTime(months[index].year, months[index].month),
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: breakdown),
              const SizedBox(width: 18),
              Expanded(child: expenseList),
            ],
          )
        else ...[
          breakdown,
          const SizedBox(height: 18),
          expenseList,
        ],
        const SizedBox(height: 18),
        _Panel(
          title: 'Resumen por mes',
          subtitle: 'Mismos datos del gráfico en forma de tabla',
          child: _MonthlyTable(months: months.reversed.toList()),
        ),
        const SizedBox(height: 18),
        _CommissionsPanel(
          items: controller.commissionsByEmployee,
          unassignedCount: controller.unassignedCount,
          commissionPercent: (WorkshopController.commissionRate * 100).round(),
        ),
        const SizedBox(height: 20),
        const Text(
          'Ingresos = servicios terminados en el mes (los que siguen "En '
          'proceso" no cuentan). Egresos = gastos registrados + comisiones de '
          'esos servicios. Ganancia = ingresos − egresos.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Container(
          decoration: AppDecorations.panel(radius: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Mes anterior',
                onPressed: () => _moveMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              SizedBox(
                width: 150,
                child: Text(
                  formatMonth(_selected.year, _selected.month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                onPressed: _isCurrentMonth ? null : () => _moveMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isCurrentMonth) ...[
              TextButton(
                onPressed: () => setState(() => _selected = _currentMonth),
                child: const Text('Ir al mes actual'),
              ),
              const SizedBox(width: 8),
            ],
            FilledButton.icon(
              onPressed: () => widget.onNewExpense(_suggestedExpenseDate),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo gasto'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetrics(
    MonthlySummary summary,
    MonthlySummary previous,
    bool isDesktop,
  ) {
    final profit = summary.profit;
    final marginText = summary.income == 0
        ? 'Sin ingresos este mes'
        : 'Margen: ${(summary.margin * 100).round()}%';

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isDesktop ? 1.5 : 1.0,
      children: [
        MetricCard(
          title: 'Ingresos del mes',
          value: formatMoney(summary.income),
          detail:
              '${summary.finishedServices} servicio(s) terminados · '
              '${_change(summary.income, previous.income)}',
          icon: Icons.trending_up_rounded,
          color: AppColors.accent,
        ),
        MetricCard(
          title: 'Gastos del mes',
          value: formatMoney(summary.expenses),
          detail: _change(summary.expenses, previous.expenses),
          icon: Icons.receipt_long_outlined,
          color: AppColors.violet,
        ),
        MetricCard(
          title: 'Comisiones',
          value: formatMoney(summary.commissions),
          detail:
              '${(WorkshopController.commissionRate * 100).round()}% de '
              'los servicios terminados',
          icon: Icons.percent_rounded,
          color: AppColors.info,
        ),
        MetricCard(
          title: profit >= 0 ? 'Ganancia neta' : 'Pérdida neta',
          value: formatMoney(profit),
          detail: marginText,
          icon: profit >= 0
              ? Icons.savings_outlined
              : Icons.warning_amber_rounded,
          color: profit >= 0 ? AppColors.accent : Colors.redAccent,
        ),
      ],
    );
  }

  /// "+12% vs. mes anterior"
  static String _change(int current, int previous) {
    if (previous == 0) {
      return current == 0
          ? 'Igual al mes anterior'
          : 'Sin datos el mes anterior';
    }
    final percent = ((current - previous) / previous * 100).round();
    final sign = percent > 0 ? '+' : '';
    return '$sign$percent% vs. mes anterior';
  }
}

// --------------------------------------------------------------- Paneles

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.panel(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

/// Barras horizontales (un solo tono: es magnitud, no identidad).
class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.items, required this.total});

  final List<MapEntry<String, int>> items;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'No hay gastos registrados en este mes.',
        style: TextStyle(color: AppColors.secondaryText),
      );
    }

    final max = items.first.value;

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.key,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${formatMoney(item.value)} · '
                      '${(item.value / total * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) => Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 8,
                      width: constraints.maxWidth * item.value / max,
                      decoration: BoxDecoration(
                        color: MonthlyChart.outflowColor,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses, required this.onDelete});

  final List<Expense> expenses;
  final ValueChanged<Expense> onDelete;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Text(
        'Registra arriendo, nómina, servicios públicos, insumos y demás '
        'gastos para calcular la ganancia real del mes.',
        style: TextStyle(color: AppColors.secondaryText),
      );
    }

    return Column(
      children: [
        for (final expense in expenses)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${formatDate(expense.date)} · ${expense.category}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatMoney(expense.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  tooltip: 'Eliminar gasto',
                  onPressed: () => onDelete(expense),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tabla con los mismos datos del gráfico (accesible y fácil de copiar).
class _MonthlyTable extends StatelessWidget {
  const _MonthlyTable({required this.months});

  final List<MonthlySummary> months;

  @override
  Widget build(BuildContext context) {
    const header = TextStyle(
      color: AppColors.secondaryText,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    DataCell money(int value, {bool bold = false}) => DataCell(
      Text(
        formatMoney(value),
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 40,
        horizontalMargin: 0,
        columnSpacing: 28,
        dividerThickness: 0.5,
        columns: const [
          DataColumn(label: Text('Mes', style: header)),
          DataColumn(label: Text('Ingresos', style: header), numeric: true),
          DataColumn(label: Text('Comisiones', style: header), numeric: true),
          DataColumn(label: Text('Gastos', style: header), numeric: true),
          DataColumn(label: Text('Ganancia', style: header), numeric: true),
        ],
        rows: [
          for (final m in months)
            DataRow(
              cells: [
                DataCell(Text(formatMonth(m.year, m.month))),
                money(m.income),
                money(m.commissions),
                money(m.expenses),
                money(m.profit, bold: true),
              ],
            ),
        ],
      ),
    );
  }
}

/// Comisiones acumuladas por empleado (todos los meses).
class _CommissionsPanel extends StatelessWidget {
  const _CommissionsPanel({
    required this.items,
    required this.unassignedCount,
    required this.commissionPercent,
  });

  final List<EmployeeCommission> items;
  final int unassignedCount;
  final int commissionPercent;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Comisiones por empleado',
      subtitle:
          'Acumulado histórico: cada empleado recibe el '
          '$commissionPercent% del precio de los servicios que terminó.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isEmpty)
            const Text(
              'Aún no hay empleados registrados.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.background,
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.employeeName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Terminados: ${item.finishedCount} de '
                          '${item.assignedCount} asignados',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatMoney(item.commission),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          if (unassignedCount > 0) ...[
            const Divider(height: 28, color: AppColors.border),
            Text(
              '$unassignedCount servicio(s) sin empleado asignado no '
              'generan comisión.',
              style: const TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
