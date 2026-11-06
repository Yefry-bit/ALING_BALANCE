import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/formatters.dart';
import 'monthly_report.dart';

/// Arma el PDF del resumen mensual (tamaño carta, listo para imprimir).
Future<Uint8List> buildMonthlyReportPdf(MonthlyReport report) async {
  const ink = PdfColor.fromInt(0xFF1B2430);
  const muted = PdfColor.fromInt(0xFF5B6675);
  const accent = PdfColor.fromInt(0xFF0E8F74);
  const line = PdfColor.fromInt(0xFFD5DAE1);
  const headerFill = PdfColor.fromInt(0xFFEFF3F6);

  final summary = report.summary;
  final doc = pw.Document(
    title: 'Resumen ${report.monthName}',
    author: 'AlingBalance',
  );

  pw.Widget title(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: ink,
      ),
    ),
  );

  pw.Widget note(String text) =>
      pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: muted));

  /// Tabla con encabezado sombreado; las columnas en [numeric] van a la
  /// derecha.
  pw.Widget table(
    List<String> headers,
    List<List<String>> rows, {
    Set<int> numeric = const {},
  }) {
    if (rows.isEmpty) return note('Sin registros en este mes.');
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: line, width: 0.5),
        bottom: pw.BorderSide(color: line, width: 0.5),
      ),
      headerDecoration: const pw.BoxDecoration(color: headerFill),
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: ink,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9, color: ink),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      headerAlignments: {for (final i in numeric) i: pw.Alignment.centerRight},
      cellAlignments: {for (final i in numeric) i: pw.Alignment.centerRight},
    );
  }

  pw.Widget metric(
    String label,
    int value,
    String detail, {
    bool bold = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: line, width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: muted),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              formatMoney(value),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: bold ? accent : ink,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              detail,
              style: const pw.TextStyle(fontSize: 8, color: muted),
            ),
          ],
        ),
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: note('AlingBalance · Resumen ${report.monthName}'),
            ),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          note('Generado el ${formatDateTime(report.generatedAt)}'),
          note('Página ${context.pageNumber} de ${context.pagesCount}'),
        ],
      ),
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'AlingBalance',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  pw.Text(
                    'Resumen mensual · ${report.monthName}',
                    style: const pw.TextStyle(fontSize: 13, color: ink),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.Divider(color: line),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            metric(
              'Ingresos',
              summary.income,
              '${summary.finishedServices} servicio(s) terminados',
            ),
            metric(
              'Comisiones',
              summary.commissions,
              '${report.commissionPercent}% · pendiente '
                  '${formatMoney(report.pendingCommissions)}',
            ),
            metric(
              'Gastos',
              summary.expenses,
              '${report.expenses.length} gasto(s)',
            ),
            metric(
              summary.profit >= 0 ? 'Ganancia neta' : 'Pérdida neta',
              summary.profit,
              'Margen: ${report.marginText}',
              bold: true,
            ),
          ],
        ),
        title('Últimos 6 meses'),
        table(
          ['Mes', 'Ingresos', 'Comisiones', 'Gastos', 'Ganancia'],
          [
            for (final m in report.recentMonths.reversed)
              [
                formatMonth(m.year, m.month),
                formatMoney(m.income),
                formatMoney(m.commissions),
                formatMoney(m.expenses),
                formatMoney(m.profit),
              ],
          ],
          numeric: {1, 2, 3, 4},
        ),
        title('Comisiones por empleado'),
        table(
          ['Empleado', 'Servicios', 'Comisión', 'Pagado', 'Pendiente'],
          [
            for (final c in report.commissions)
              [
                c.employeeName,
                '${c.finishedCount}',
                formatMoney(c.amount),
                formatMoney(c.paidAmount),
                formatMoney(c.pendingAmount),
              ],
          ],
          numeric: {1, 2, 3, 4},
        ),
        title('Gastos por categoría'),
        table(
          ['Categoría', 'Valor', '% del total'],
          [
            for (final entry in report.categories)
              [
                entry.key,
                formatMoney(entry.value),
                '${(entry.value / summary.expenses * 100).round()}%',
              ],
          ],
          numeric: {1, 2},
        ),
        title('Gastos del mes'),
        table(
          ['Fecha', 'Descripción', 'Categoría', 'Valor'],
          [
            for (final e in report.expenses)
              [
                formatDate(e.date),
                e.isRecurring ? '${e.description} (fijo)' : e.description,
                e.category,
                formatMoney(e.amount),
              ],
          ],
          numeric: {3},
        ),
        title('Servicios terminados'),
        table(
          ['#', 'Fecha', 'Placa', 'Servicio', 'Empleado', 'Precio', 'Comisión'],
          [
            for (final s in report.services)
              [
                '${s.operation}',
                formatDate(s.date),
                s.plate,
                s.service,
                s.employeeName.isEmpty ? 'Sin asignar' : s.employeeName,
                formatMoney(s.price),
                s.employeeId == null
                    ? '-'
                    : formatMoney(report.commissionOf(s)),
              ],
          ],
          numeric: {0, 5, 6},
        ),
        pw.SizedBox(height: 14),
        note(
          'Ingresos = servicios terminados en el mes. Egresos = gastos + '
          'comisiones de esos servicios. Ganancia = ingresos - egresos.',
        ),
      ],
    ),
  );

  return doc.save();
}
