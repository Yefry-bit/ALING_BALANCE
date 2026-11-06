/// Pago de comisiones a un empleado (agrupa los servicios que se le pagaron).
class CommissionPayment {
  const CommissionPayment({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.year,
    required this.month,
    required this.amount,
    required this.serviceCount,
    required this.paidAt,
    this.paidBy = '',
  });

  final int id;
  final int? employeeId;
  final String employeeName;

  /// Mes al que corresponden los servicios.
  final int year;
  final int month;

  final int amount;
  final int serviceCount;

  /// Momento del pago (hora local).
  final DateTime paidAt;

  /// Administrador que registró el pago.
  final String paidBy;

  factory CommissionPayment.fromJson(Map<String, dynamic> json) {
    return CommissionPayment(
      id: (json['id'] as num).toInt(),
      employeeId: (json['employeeId'] as num?)?.toInt(),
      employeeName: json['employeeName']?.toString() ?? '',
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      amount: (json['amount'] as num).toInt(),
      serviceCount: (json['serviceCount'] as num).toInt(),
      paidAt:
          (DateTime.tryParse(json['paidAt']?.toString() ?? '') ??
                  DateTime.now())
              .toLocal(),
      paidBy: json['paidBy']?.toString() ?? '',
    );
  }
}

/// Comisiones de un empleado en un mes: lo generado, lo pagado y lo que
/// falta por pagar.
class MonthlyCommission {
  const MonthlyCommission({
    required this.employeeId,
    required this.employeeName,
    required this.finishedCount,
    required this.amount,
    required this.paidAmount,
    required this.pendingOperations,
  });

  final int employeeId;
  final String employeeName;

  /// Servicios terminados del mes (generan comisión).
  final int finishedCount;

  /// Comisión total del mes.
  final int amount;

  /// Parte ya pagada.
  final int paidAmount;

  /// Servicios cuya comisión falta por pagar.
  final List<int> pendingOperations;

  int get pendingAmount => amount - paidAmount;

  bool get fullyPaid => amount > 0 && pendingOperations.isEmpty;
}
