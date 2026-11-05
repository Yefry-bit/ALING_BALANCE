import 'package:image_picker/image_picker.dart';

import '../../models/service_photo.dart';

/// Toma fotos con la cámara o las elige de la galería / archivos.
///
/// Las fotos se reducen a 1600 px y calidad 75 % antes de subirlas, así
/// pesan unos cientos de KB aunque la cámara sea de alta resolución.
class PhotoPicker {
  const PhotoPicker();

  static const double _maxSide = 1600;
  static const int _quality = 75;

  /// En Android, iOS y el navegador del celular hay cámara; en Windows o en
  /// el navegador del computador solo se pueden elegir archivos.
  bool get canUseCamera {
    try {
      return ImagePicker().supportsImageSource(ImageSource.camera);
    } catch (_) {
      return false;
    }
  }

  /// Devuelve las fotos elegidas (vacío si el usuario cancela).
  Future<List<NewPhotoData>> pick({required bool camera}) async {
    final picker = ImagePicker();

    final files = camera
        ? [
            ?await picker.pickImage(
              source: ImageSource.camera,
              maxWidth: _maxSide,
              maxHeight: _maxSide,
              imageQuality: _quality,
            ),
          ]
        : await picker.pickMultiImage(
            maxWidth: _maxSide,
            maxHeight: _maxSide,
            imageQuality: _quality,
          );

    return [
      for (final file in files)
        NewPhotoData(
          bytes: await file.readAsBytes(),
          fileName: file.name.isEmpty ? 'foto.jpg' : file.name,
        ),
    ];
  }
}
