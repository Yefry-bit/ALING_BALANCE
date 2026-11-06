import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../utils/formatters.dart';
import 'monthly_report.dart';

/// Arma el libro de Excel (.xlsx) del resumen mensual, con una hoja por
/// tema y valores numéricos (se pueden sumar y filtrar en Excel).
Uint8List buildMonthlyReportExcel(MonthlyReport report) {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

  const money = CustomNumericNumFormat(formatCode: r'"$"#,##0');
  final moneyStyle = CellStyle(numberFormat: money);
  final headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#FFEFF3F6'),
  );
  final titleStyle = CellStyle(bold: true, fontSize: 14);

  CellValue text(String value) => TextCellValue(value);
  CellValue number(int value) => IntCellValue(value);

  /// Agrega una tabla: encabezado en negrilla y columnas de dinero con
  /// formato de pesos.
  void addTable(
    Sheet sheet,
    List<String> headers,
    List<List<CellValue>> rows, {
    Set<int> moneyColumns = const {},
    List<double>? widths,
  }) {
    final headerRow = sheet.maxRows;
    sheet.appendRow([for (final h in headers) text(h)]);
    for (var c = 0; c < headers.length; c++) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerRow),
              )
              .cellStyle =
          headerStyle;
    }

    for (final row in rows) {
      final index = sheet.maxRows;
      sheet.appendRow(row);
      for (final c in moneyColumns) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: c, rowIndex: index),
                )
                .cellStyle =
            moneyStyle;
      }
    }

    if (widths != null) {
      for (var c = 0; c < widths.length; c++) {
        sheet.setColumnWidth(c, widths[c]);
      }
    }
  }

  void addTitle(Sheet sheet, String value) {
    final index = sheet.maxRows;
    sheet.appendRow([text(value)]);
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: index))
            .cellStyle =
        titleStyle;
  }

  final summary = report.summary;

  // ----------------------------------------------------------------- Resumen
  final resumen = excel['Resumen'];
  addTitle(resumen, 'AlingBalance · Resumen ${report.monthName}');
  resumen.appendRow([
    text('Generado el ${formatDateTime(report.generatedAt)}'),
  ]);
  resumen.appendRow([]);
  addTable(
    resumen,
    ['Concepto', 'Valor'],
    [
      [text('Ingresos (servicios terminados)'), number(summary.income)],
      [text('Comisiones'), number(summary.commissions)],
      [text('Gastos'), number(summary.expenses)],
      [
        text(summary.profit >= 0 ? 'Ganancia neta' : 'Pérdida neta'),
        number(summary.profit),
      ],
      [
        text('Comisiones pendientes de pago'),
        number(report.pendingCommissions),
      ],
    ],
    moneyColumns: {1},
    widths: [34, 18, 18, 18, 18],
  );
  resumen.appendRow([text('Margen'), text(report.marginText)]);
  resumen.appendRow([
    text('Servicios terminados'),
    number(summary.finishedServices),
  ]);
  resumen.appendRow([]);
  addTitle(resumen, 'Últimos 6 meses');
  addTable(
    resumen,
    ['Mes', 'Ingresos', 'Comisiones', 'Gastos', 'Ganancia'],
    [
      for (final m in report.recentMonths.reversed)
        [
          text(formatMonth(m.year, m.month)),
          number(m.income),
          number(m.commissions),
          number(m.expenses),
          number(m.profit),
        ],
    ],
    moneyColumns: {1, 2, 3, 4},
  );

  // --------------------------------------------------------------- Servicios
  addTable(
    excel['Servicios'],
    [
      'Operación',
      'Fecha',
      'Placa',
      'Vehículo',
      'Tipo',
      'Servicio',
      'Empleado',
      'Precio',
      'Comisión',
      'Comisión pagada',
    ],
    [
      for (final s in report.services)
        [
          number(s.operation),
          text(formatDate(s.date)),
          text(s.plate),
          text(s.vehicle),
          text(s.vehicleType),
          text(s.service),
          text(s.employeeName.isEmpty ? 'Sin asignar' : s.employeeName),
          number(s.price),
          number(s.employeeId == null ? 0 : report.commissionOf(s)),
          text(
            s.employeeId == null
                ? '-'
                : s.commissionPaid
                ? 'Sí'
                : 'No',
          ),
        ],
    ],
    moneyColumns: {7, 8},
    widths: [11, 12, 11, 24, 12, 22, 24, 13, 13, 16],
  );

  // ------------------------------------------------------------------ Gastos
  addTable(
    excel['Gastos'],
    ['Fecha', 'Descripción', 'Categoría', 'Valor', 'Gasto fijo', 'Registró'],
    [
      for (final e in report.expenses)
        [
          text(formatDate(e.date)),
          text(e.description),
          text(e.category),
          number(e.amount),
          text(e.isRecurring ? 'Sí' : 'No'),
          text(e.registeredBy),
        ],
    ],
    moneyColumns: {3},
    widths: [12, 34, 24, 14, 11, 28],
  );

  // -------------------------------------------------------------- Comisiones
  addTable(
    excel['Comisiones'],
    ['Empleado', 'Servicios terminados', 'Comisión', 'Pagado', 'Pendiente'],
    [
      for (final c in report.commissions)
        [
          text(c.employeeName),
          number(c.finishedCount),
          number(c.amount),
          number(c.paidAmount),
          number(c.pendingAmount),
        ],
    ],
    moneyColumns: {2, 3, 4},
    widths: [28, 20, 14, 14, 14],
  );

  excel.setDefaultSheet('Resumen');
  if (defaultSheet != 'Resumen') excel.delete(defaultSheet);

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('No se pudo generar el archivo de Excel.');
  }
  return Uint8List.fromList(bytes);
}
