import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/monthly_summary.dart';

/// Gráfico de barras agrupadas: ingresos vs. egresos (comisiones + gastos)
/// por mes, con la ganancia escrita debajo de cada mes.
///
/// Un solo eje (las dos series están en pesos). Al pasar el puntero (o
/// mantener presionado en el celular) cada barra muestra su valor; al tocar
/// un mes se selecciona.
class MonthlyChart extends StatelessWidget {
  const MonthlyChart({
    super.key,
    required this.months,
    required this.selectedIndex,
    required this.onSelect,
  });

  /// Meses del más antiguo al más reciente.
  final List<MonthlySummary> months;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// Paleta validada para el tema oscuro (separación para daltonismo y
  /// contraste contra el panel comprobados).
  static const Color incomeColor = Color(0xFF1AA888);
  static const Color outflowColor = Color(0xFF8F72EA);

  static const double _plotHeight = 190;
  static const double _axisWidth = 62;

  @override
  Widget build(BuildContext context) {
    final maxValue = _niceMax(
      months.fold<int>(0, (m, s) => math.max(m, math.max(s.income, s.outflow))),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 18,
          runSpacing: 6,
          children: [
            _LegendItem(color: incomeColor, label: 'Ingresos'),
            _LegendItem(
              color: outflowColor,
              label: 'Egresos (gastos + comisiones)',
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _axisWidth,
              height: _plotHeight,
              child: _Axis(maxValue: maxValue),
            ),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: _plotHeight,
                    child: Stack(
                      children: [
                        const _GridLines(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < months.length; i++)
                              Expanded(
                                child: _MonthBars(
                                  summary: months[i],
                                  maxValue: maxValue,
                                  selected: i == selectedIndex,
                                  onTap: () => onSelect(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < months.length; i++)
                        Expanded(
                          child: _MonthLabel(
                            summary: months[i],
                            selected: i == selectedIndex,
                            onTap: () => onSelect(i),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Redondea hacia arriba a 1, 2 o 5 × 10ⁿ para que el eje tenga valores
  /// limpios.
  static int _niceMax(int value) {
    if (value <= 0) return 100000;
    final magnitude = math
        .pow(10, (math.log(value) / math.ln10).floor())
        .toInt();
    for (final step in [1, 2, 5, 10]) {
      if (step * magnitude >= value) return step * magnitude;
    }
    return 10 * magnitude;
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// Etiquetas del eje vertical: 0, mitad y máximo.
class _Axis extends StatelessWidget {
  const _Axis({required this.maxValue});

  final int maxValue;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: AppColors.secondaryText, fontSize: 10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          [
                Text(formatMoneyShort(maxValue), style: style),
                Text(formatMoneyShort(maxValue ~/ 2), style: style),
                const Text('\$0', style: style),
              ]
              .map(
                (t) =>
                    Padding(padding: const EdgeInsets.only(right: 8), child: t),
              )
              .toList(),
    );
  }
}

/// Líneas guía discretas en 0, 50 % y 100 %.
class _GridLines extends StatelessWidget {
  const _GridLines();

  @override
  Widget build(BuildContext context) {
    Widget line(Color color) => Container(height: 1, color: color);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        line(AppColors.border.withValues(alpha: 0.5)),
        line(AppColors.border.withValues(alpha: 0.5)),
        line(AppColors.border), // línea base
      ],
    );
  }
}

class _MonthBars extends StatelessWidget {
  const _MonthBars({
    required this.summary,
    required this.maxValue,
    required this.selected,
    required this.onTap,
  });

  final MonthlySummary summary;
  final int maxValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final month = formatMonth(summary.year, summary.month);

    return Semantics(
      button: true,
      selected: selected,
      label:
          '$month: ingresos ${formatMoney(summary.income)}, egresos '
          '${formatMoney(summary.outflow)}, ganancia '
          '${formatMoney(summary.profit)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // toda la columna del mes es tocable
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = math.min(
                18.0,
                math.max(6.0, constraints.maxWidth * 0.22),
              );
              double height(int value) =>
                  maxValue == 0 ? 0 : constraints.maxHeight * value / maxValue;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Bar(
                    width: barWidth,
                    height: height(summary.income),
                    color: MonthlyChart.incomeColor,
                    tooltip:
                        '$month\nIngresos: ${formatMoney(summary.income)}'
                        '\n${summary.finishedServices} servicio(s) terminados',
                  ),
                  const SizedBox(width: 2), // separación entre barras vecinas
                  _Bar(
                    width: barWidth,
                    height: height(summary.outflow),
                    color: MonthlyChart.outflowColor,
                    tooltip:
                        '$month\nEgresos: ${formatMoney(summary.outflow)}'
                        '\nGastos: ${formatMoney(summary.expenses)}'
                        '\nComisiones: ${formatMoney(summary.commissions)}',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.width,
    required this.height,
    required this.color,
    required this.tooltip,
  });

  final double width;
  final double height;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    // Zona de contacto más ancha que la barra para que sea fácil de señalar.
    return Tooltip(
      message: tooltip,
      waitDuration: Duration.zero,
      child: SizedBox(
        width: width + 8,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: width,
            // Un valor en cero se ve como una marca mínima sobre la base.
            height: height <= 0 ? 0 : math.max(height, 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final MonthlySummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasData = summary.income > 0 || summary.outflow > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Text(
            formatMonthShort(summary.month),
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.white : AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              hasData ? formatMoneyShort(summary.profit) : '—',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
