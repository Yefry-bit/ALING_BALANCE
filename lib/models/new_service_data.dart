import 'service_status.dart';

/// Datos que se envían al servidor para registrar un servicio.
/// El número de operación, la fecha y quién lo registró los asigna el servidor.
class NewServiceData {
  const NewServiceData({
    required this.plate,
    required this.brand,
    required this.model,
    required this.vehicleType,
    required this.serviceType,
    required this.status,
    required this.price,
    this.employeeId,
    this.contactName = '',
    this.contactPhone = '',
  });

  final String plate;
  final String brand;
  final String model;
  final String vehicleType;
  final String serviceType;
  final ServiceStatus status;
  final int price;
  final int? employeeId;

  /// A quién avisar cuando el vehículo esté listo (opcionales).
  final String contactName;
  final String contactPhone;

  Map<String, dynamic> toJson() {
    return {
      'plate': plate,
      'brand': brand,
      'model': model,
      'vehicleType': vehicleType,
      'serviceType': serviceType,
      'status': status.label,
      'price': price,
      'employeeId': employeeId,
      'contactName': contactName,
      'contactPhone': contactPhone,
    };
  }
}
