import 'dart:typed_data';

/// Foto de evidencia de un servicio (sin la imagen; se descarga aparte).
class ServicePhoto {
  const ServicePhoto({
    required this.id,
    required this.operation,
    required this.kind,
    this.note = '',
    this.takenById = 0,
    this.takenBy = '',
    required this.createdAt,
  });

  final int id;
  final int operation;

  /// Una de [PhotoKinds.all].
  final String kind;
  final String note;
  final int takenById;
  final String takenBy;
  final DateTime createdAt;

  factory ServicePhoto.fromJson(Map<String, dynamic> json) {
    return ServicePhoto(
      id: (json['id'] as num).toInt(),
      operation: (json['operation'] as num).toInt(),
      kind: json['kind']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      takenById: (json['takenById'] as num?)?.toInt() ?? 0,
      takenBy: json['takenBy']?.toString() ?? '',
      createdAt:
          (DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                  DateTime.now())
              .toLocal(),
    );
  }
}

/// Foto tomada en el dispositivo, lista para subir.
class NewPhotoData {
  NewPhotoData({
    required this.bytes,
    required this.fileName,
    this.kind = PhotoKinds.vehicle,
    this.note = '',
  });

  final Uint8List bytes;
  final String fileName;

  /// Se pueden cambiar en el formulario antes de subirla.
  String kind;
  String note;
}

/// Qué muestra la foto (mismos textos que el servidor:
/// backend/AlingBalance.Api/Domain/ServicePhoto.cs).
abstract final class PhotoKinds {
  static const String vehicle = 'Vehículo';
  static const String machine = 'Máquina / equipo';
  static const String damage = 'Falla o daño';
  static const String missing = 'Pieza faltante';

  static const List<String> all = [vehicle, machine, damage, missing];

  /// Máximo de fotos por servicio (igual que el servidor).
  static const int maxPerService = 12;
}
