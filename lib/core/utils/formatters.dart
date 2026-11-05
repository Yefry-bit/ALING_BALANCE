/// Da formato de pesos con separador de miles: 20000 -> $20.000,
/// -150000 -> -$150.000
String formatMoney(int amount) {
  final value = amount.abs().toString();
  final result = StringBuffer();

  for (int i = 0; i < value.length; i++) {
    if (i > 0 && (value.length - i) % 3 == 0) {
      result.write('.');
    }
    result.write(value[i]);
  }

  return '${amount < 0 ? '-' : ''}\$${result.toString()}';
}

/// Versión corta para ejes y etiquetas: 1500000 -> $1,5 M; 85000 -> $85 mil.
String formatMoneyShort(int amount) {
  final sign = amount < 0 ? '-' : '';
  final value = amount.abs();

  if (value >= 1000000) {
    final millions = value / 1000000;
    final text = millions >= 10 || millions == millions.roundToDouble()
        ? millions.round().toString()
        : millions.toStringAsFixed(1).replaceAll('.', ',');
    return '$sign\$$text M';
  }
  if (value >= 1000) return '$sign\$${(value / 1000).round()} mil';
  return '$sign\$$value';
}

/// Da formato dd/mm/aaaa a una fecha.
String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Hora en formato de 12 horas: 4:05 p. m.
String formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${date.hour < 12 ? 'a. m.' : 'p. m.'}';
}

/// "05/11/2026 · 4:05 p. m."
String formatDateTime(DateTime date) =>
    '${formatDate(date)} · ${formatTime(date)}';

/// Duración legible: "45 min", "2 h 10 min", "1 d 3 h".
String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes < 1) return 'menos de 1 min';
  if (minutes < 60) return '$minutes min';

  final hours = duration.inHours;
  if (hours < 24) {
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }

  final days = duration.inDays;
  final restHours = hours % 24;
  return restHours == 0 ? '$days d' : '$days d $restHours h';
}

const List<String> _monthNames = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', //
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

/// "Noviembre 2026"
String formatMonth(int year, int month) => '${_monthNames[month - 1]} $year';

/// "Nov" (para los ejes de los gráficos).
String formatMonthShort(int month) => _monthNames[month - 1].substring(0, 3);
