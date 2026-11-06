/// Gasto del taller.
class Expense {
  const Expense({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    this.registeredBy = '',
    this.recurringExpenseId,
  });

  /// Gasto fijo que lo generó automáticamente; `null` si se registró a mano.
  final int? recurringExpenseId;

  bool get isRecurring => recurringExpenseId != null;

  final int id;
  final String description;

  /// Una de [ExpenseCategories.all].
  final String category;

  /// Valor en pesos colombianos.
  final int amount;

  /// Día del gasto (sin hora); define el mes en el que cuenta.
  final DateTime date;
  final String registeredBy;

  factory Expense.fromJson(Map<String, dynamic> json) {
    // La fecha llega como "2026-11-05" y se interpreta como día local.
    final parsed = DateTime.tryParse(json['date']?.toString() ?? '');
    return Expense(
      id: (json['id'] as num).toInt(),
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      amount: (json['amount'] as num).toInt(),
      date: parsed == null
          ? DateTime.now()
          : DateTime(parsed.year, parsed.month, parsed.day),
      registeredBy: json['registeredBy']?.toString() ?? '',
      recurringExpenseId: (json['recurringExpenseId'] as num?)?.toInt(),
    );
  }
}

/// Datos para registrar un gasto.
class NewExpenseData {
  const NewExpenseData({
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
  });

  final String description;
  final String category;
  final int amount;
  final DateTime date;

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'category': category,
      'amount': amount,
      'date': formatIsoDate(date),
    };
  }
}

/// "2026-11-05" (formato de fecha que espera el servidor).
String formatIsoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Gasto fijo mensual (arriendo, nómina…): el servidor registra el gasto de
/// cada mes cuando llega el día indicado.
class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.dayOfMonth,
    this.active = true,
  });

  final int id;
  final String description;
  final String category;
  final int amount;

  /// Día del mes en que se registra (1 a 28).
  final int dayOfMonth;

  /// En pausa no se registran gastos nuevos.
  final bool active;

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: (json['id'] as num).toInt(),
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      amount: (json['amount'] as num).toInt(),
      dayOfMonth: (json['dayOfMonth'] as num).toInt(),
      active: json['active'] != false,
    );
  }
}

/// Datos para crear o editar un gasto fijo.
class RecurringExpenseData {
  const RecurringExpenseData({
    required this.description,
    required this.category,
    required this.amount,
    required this.dayOfMonth,
    this.active = true,
    this.includeCurrentMonth = true,
  });

  final String description;
  final String category;
  final int amount;
  final int dayOfMonth;
  final bool active;

  /// Solo al crear: registrar también el gasto de este mes si ya pasó el día.
  final bool includeCurrentMonth;

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'category': category,
      'amount': amount,
      'dayOfMonth': dayOfMonth,
      'active': active,
      'includeCurrentMonth': includeCurrentMonth,
    };
  }
}

/// Categorías de gasto (mismos textos que el servidor:
/// backend/AlingBalance.Api/Domain/Expense.cs).
abstract final class ExpenseCategories {
  static const List<String> all = [
    'Arriendo',
    'Nómina',
    'Servicios públicos',
    'Insumos y repuestos',
    'Mantenimiento de equipos',
    'Impuestos',
    'Otros',
  ];
}
