import 'package:flutter/foundation.dart';

/// Configuración de la conexión con el servidor (API).
abstract final class ApiConfig {
  /// Dirección indicada al ejecutar la app (vacía si no se indicó):
  ///
  ///   flutter run --dart-define=API_URL=http://192.168.1.20:5080
  static const String _configuredUrl = String.fromEnvironment('API_URL');

  /// Puerto por defecto del servidor.
  static const int _port = 5080;

  /// Dirección del servidor que usa la app.
  ///
  /// - Si se indicó `API_URL`, se usa esa (ver la excepción de abajo).
  /// - Si no se indicó: en el emulador de Android `http://10.0.2.2:5080`; en
  ///   el navegador, el mismo computador que sirve la página; en Windows,
  ///   macOS, Linux o el simulador de iOS, `http://localhost:5080`.
  ///
  /// `10.0.2.2` solo existe dentro del emulador de Android. Si llega esa
  /// dirección en otra plataforma (por ejemplo, al copiar el comando del
  /// emulador para abrir la app en Edge) se cambia por la del computador
  /// local, en vez de esperar hasta que se agote el tiempo.
  static String get baseUrl {
    final configured = _configuredUrl.trim();
    final runsOnAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    if (configured.isNotEmpty) {
      final uri = Uri.tryParse(configured);
      if (uri != null && uri.host == '10.0.2.2' && !runsOnAndroid) {
        return _withoutTrailingSlash(uri.replace(host: _localHost).toString());
      }
      return _withoutTrailingSlash(configured);
    }

    if (runsOnAndroid) return 'http://10.0.2.2:$_port';
    return 'http://$_localHost:$_port';
  }

  /// En el navegador, el computador que sirve la página (así también
  /// funciona si se abre desde otro equipo de la red); en el resto,
  /// `localhost`.
  static String get _localHost {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty) return host;
    }
    return 'localhost';
  }

  static String _withoutTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  /// Tiempo máximo de espera de cada petición.
  static const Duration timeout = Duration(seconds: 15);
}
