/// Gasto del taller.
class Expense {
  const Expense({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    this.registeredBy = '',
  });

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
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return {
      'description': description,
      'category': category,
      'amount': amount,
      'date': '${date.year}-$month-$day',
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
