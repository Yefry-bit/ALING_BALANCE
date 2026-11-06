import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

/// Formato de exportación del resumen mensual.
enum ReportFormat {
  pdf(extension: 'pdf', label: 'PDF', mime: MimeType.pdf),
  excel(extension: 'xlsx', label: 'Excel', mime: MimeType.microsoftExcel);

  const ReportFormat({
    required this.extension,
    required this.label,
    required this.mime,
  });

  final String extension;
  final String label;
  final MimeType mime;
}

/// Guarda un archivo generado por la app.
///
/// - Web: se descarga con el navegador.
/// - Windows, Android, iOS: se abre "Guardar como" para elegir dónde.
class ReportSaver {
  const ReportSaver();

  /// Devuelve `false` si se canceló el diálogo de guardar.
  Future<bool> save({
    required String name,
    required Uint8List bytes,
    required ReportFormat format,
  }) async {
    if (kIsWeb) {
      await FileSaver.instance.saveFile(
        name: name,
        bytes: bytes,
        fileExtension: format.extension,
        mimeType: format.mime,
      );
      return true;
    }

    final path = await FileSaver.instance.saveAs(
      name: name,
      bytes: bytes,
      fileExtension: format.extension,
      mimeType: format.mime,
    );
    return path != null && path.isNotEmpty;
  }
}
