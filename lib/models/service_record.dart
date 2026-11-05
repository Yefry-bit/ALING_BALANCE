import 'service_status.dart';

/// Una operación de servicio realizada a un vehículo.
class ServiceRecord {
  const ServiceRecord({
    required this.operation,
    required this.plate,
    required this.vehicle,
    required this.vehicleType,
    required this.service,
    required this.status,
    required this.price,
    required this.date,
    this.registeredBy = '',
    this.employeeId,
    this.employeeName = '',
    this.photoCount = 0,
    this.finishedAt,
  });

  /// Hora en que el servicio pasó a "Terminado" (hora local); `null` si está
  /// en proceso o si se terminó antes de que existiera este dato.
  final DateTime? finishedAt;

  /// Tiempo entre el registro y la finalización, si se conoce.
  Duration? get duration {
    final end = finishedAt;
    if (end == null || end.isBefore(date)) return null;
    return end.difference(date);
  }

  /// Cantidad de fotos de evidencia del servicio.
  final int photoCount;

  /// Número consecutivo de la operación.
  final int operation;
  final String plate;

  /// Marca y modelo, por ejemplo "Chevrolet Spark".
  final String vehicle;
  final String vehicleType;

  /// Nombre del servicio, por ejemplo "Balanceo".
  final String service;
  final ServiceStatus status;

  /// Precio en pesos colombianos.
  final int price;
  final DateTime date;

  /// Nombre del usuario que registró el servicio (vacío en datos antiguos).
  final String registeredBy;

  /// Empleado del taller que realizó el trabajo (genera la comisión).
  /// Es `null` en servicios sin empleado asignado.
  final int? employeeId;

  /// Nombre del empleado al momento de registrar el servicio.
  final String employeeName;

  ServiceRecord copyWith({ServiceStatus? status, int? photoCount}) {
    return ServiceRecord(
      operation: operation,
      plate: plate,
      vehicle: vehicle,
      vehicleType: vehicleType,
      service: service,
      status: status ?? this.status,
      price: price,
      date: date,
      registeredBy: registeredBy,
      employeeId: employeeId,
      employeeName: employeeName,
      photoCount: photoCount ?? this.photoCount,
      finishedAt: finishedAt,
    );
  }

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    return ServiceRecord(
      operation: (json['operation'] as num).toInt(),
      plate: json['plate'] as String,
      vehicle: json['vehicle'] as String,
      vehicleType: json['vehicleType'] as String,
      service: json['service'] as String,
      status: ServiceStatus.fromLabel(json['status'] as String?),
      price: (json['price'] as num).toInt(),
      date:
          (DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now())
              .toLocal(),
      registeredBy: json['registeredBy']?.toString() ?? '',
      employeeId: (json['employeeId'] as num?)?.toInt(),
      employeeName: json['employeeName']?.toString() ?? '',
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
      finishedAt: DateTime.tryParse(json['finishedAt']?.toString() ?? '')
          ?.toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'plate': plate,
      'vehicle': vehicle,
      'vehicleType': vehicleType,
      'service': service,
      'status': status.label,
      'price': price,
      'date': date.toIso8601String(),
      'registeredBy': registeredBy,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'photoCount': photoCount,
      'finishedAt': finishedAt?.toUtc().toIso8601String(),
    };
  }
}
