/// Catálogo de servicios, tipos de vehículo y precios sugeridos (COP).
abstract final class ServiceCatalog {
  static const List<String> serviceTypes = [
    'Alineación sencilla',
    'Balanceo',
    'Alineación doble',
    'Montaje de llantas',
    'Nitrógeno',
    'Rines',
  ];

  static const List<String> vehicleTypes = ['Particular', 'Taxi', 'Camioneta'];

  /// Precio sugerido: servicio -> tipo de vehículo -> precio.
  static const Map<String, Map<String, int>> suggestedPrices = {
    'Alineación sencilla': {
      'Taxi': 15000,
      'Particular': 20000,
      'Camioneta': 30000,
    },
    'Balanceo': {'Taxi': 30000, 'Particular': 30000, 'Camioneta': 50000},
    'Alineación doble': {
      'Taxi': 40000,
      'Particular': 40000,
      'Camioneta': 50000,
    },
    'Montaje de llantas': {
      'Taxi': 15000,
      'Particular': 15000,
      'Camioneta': 30000,
    },
    'Nitrógeno': {'Taxi': 20000, 'Particular': 20000, 'Camioneta': 30000},
    'Rines': {'Taxi': 50000, 'Particular': 50000, 'Camioneta': 50000},
  };

  /// Devuelve el precio sugerido o 0 si la combinación no existe.
  static int suggestedPrice(String service, String vehicleType) {
    return suggestedPrices[service]?[vehicleType] ?? 0;
  }
}
