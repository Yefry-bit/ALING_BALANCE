/// Vehículo registrado a nombre de un cliente.
///
/// Los servicios se enlazan con el vehículo por la placa (única).
class Vehicle {
  const Vehicle({
    required this.id,
    required this.clientId,
    required this.plate,
    required this.brand,
    required this.model,
    required this.vehicleType,
  });

  final int id;
  final int clientId;
  final String plate;
  final String brand;
  final String model;
  final String vehicleType;

  /// Marca y modelo, por ejemplo "Kia Rio".
  String get description => '$brand $model';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: (json['id'] as num).toInt(),
      clientId: (json['clientId'] as num).toInt(),
      plate: json['plate']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString() ?? '',
    );
  }
}

/// Cliente del taller con sus vehículos.
class Client {
  const Client({
    required this.id,
    required this.name,
    required this.document,
    this.phone = '',
    this.vehicles = const [],
  });

  final int id;
  final String name;

  /// Número de identificación (único por cliente).
  final String document;
  final String phone;
  final List<Vehicle> vehicles;

  factory Client.fromJson(Map<String, dynamic> json) {
    final vehicles = json['vehicles'];
    return Client(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      document: json['document']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      vehicles: vehicles is List
          ? [
              for (final item in vehicles)
                Vehicle.fromJson(Map<String, dynamic>.from(item as Map)),
            ]
          : const [],
    );
  }
}

/// Datos para crear o editar un cliente.
class ClientData {
  const ClientData({
    required this.name,
    required this.document,
    this.phone = '',
  });

  final String name;
  final String document;
  final String phone;

  Map<String, dynamic> toJson() {
    return {'name': name, 'document': document, 'phone': phone};
  }
}

/// Datos para agregar un vehículo a un cliente.
class NewVehicleData {
  const NewVehicleData({
    required this.plate,
    required this.brand,
    required this.model,
    required this.vehicleType,
  });

  final String plate;
  final String brand;
  final String model;
  final String vehicleType;

  Map<String, dynamic> toJson() {
    return {
      'plate': plate,
      'brand': brand,
      'model': model,
      'vehicleType': vehicleType,
    };
  }
}
