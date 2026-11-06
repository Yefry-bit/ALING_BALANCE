import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';

/// Error de comunicación con el servidor, con un mensaje listo para mostrar.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;

  /// Código HTTP, o `null` si no se pudo llegar al servidor.
  final int? statusCode;

  @override
  String toString() => message;
}

/// Cliente HTTP de la API: agrega el token, interpreta los errores del
/// servidor y los convierte en [ApiException].
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _http = httpClient ?? http.Client(),
      baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _http;
  final String baseUrl;

  /// Token JWT de la sesión activa (`null` si no hay sesión).
  String? token;

  /// Se llama cuando el servidor rechaza el token (sesión vencida).
  void Function()? onUnauthorized;

  Future<List<Map<String, dynamic>>> getList(String path) async {
    final data = await _send('GET', path);
    return _asList(data);
  }

  Future<Map<String, dynamic>> getObject(String path) async {
    return _asObject(await _send('GET', path));
  }

  Future<Map<String, dynamic>> postObject(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _asObject(await _send('POST', path, body: body));
  }

  Future<Map<String, dynamic>> patchObject(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _asObject(await _send('PATCH', path, body: body));
  }

  /// PATCH cuando el servidor no devuelve nada (204 sin contenido).
  Future<void> patch(String path, Map<String, dynamic> body) async {
    await _send('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> putObject(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _asObject(await _send('PUT', path, body: body));
  }

  /// DELETE: devuelve el objeto actualizado si el servidor responde con uno,
  /// o `null` si responde sin contenido (204).
  Future<Map<String, dynamic>?> delete(String path) async {
    final data = await _send('DELETE', path);
    return data == null ? null : _asObject(data);
  }

  /// Sube un archivo con `multipart/form-data` (por ejemplo, una foto).
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fileField,
    required List<int> bytes,
    required String fileName,
    Map<String, String> fields = const {},
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll(_headers(json: false))
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(fileField, bytes, filename: fileName),
      );

    // Subir fotos puede tardar más que una petición normal.
    final response = await _perform(
      () async => http.Response.fromStream(await _http.send(request)),
      timeout: ApiConfig.timeout * 4,
    );
    return _asObject(_decode(response));
  }

  /// Descarga un archivo (por ejemplo, una foto) y devuelve sus bytes.
  Future<Uint8List> getBytes(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _perform(
      () => _http.get(uri, headers: _headers(json: false)),
      timeout: ApiConfig.timeout * 2,
    );
    return response.bodyBytes;
  }

  // ----------------------------------------------------------------- Interno

  Map<String, String> _headers({bool json = true}) {
    return {
      if (json) 'Content-Type': 'application/json',
      if (json) 'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = _headers();

    final response = await _perform(
      () => switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'POST' => _http.post(uri, headers: headers, body: jsonEncode(body)),
        'PATCH' => _http.patch(uri, headers: headers, body: jsonEncode(body)),
        'PUT' => _http.put(uri, headers: headers, body: jsonEncode(body)),
        'DELETE' => _http.delete(uri, headers: headers),
        _ => throw ArgumentError('Método no soportado: $method'),
      },
    );
    return _decode(response);
  }

  /// Envía la petición y convierte los problemas de red y las respuestas de
  /// error en [ApiException]. Devuelve la respuesta solo si fue exitosa.
  Future<http.Response> _perform(
    Future<http.Response> Function() send, {
    Duration? timeout,
  }) async {
    final http.Response response;
    try {
      response = await send().timeout(timeout ?? ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException(
        'El servidor ($baseUrl) tardó demasiado en responder. Revisa que la '
        'dirección sea correcta y que el firewall permita el puerto.',
      );
    } on http.ClientException {
      throw ApiException(
        'No se pudo conectar con $baseUrl. Revisa tu conexión y que el '
        'servidor esté encendido.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    // Token vencido o inválido en una petición con sesión.
    if (response.statusCode == 401 && token != null) {
      token = null;
      onUnauthorized?.call();
      throw const ApiException(
        'Tu sesión expiró. Inicia sesión de nuevo.',
        statusCode: 401,
      );
    }

    if (response.statusCode == 429) {
      throw const ApiException(
        'Demasiados intentos. Espera un minuto e inténtalo de nuevo.',
        statusCode: 429,
      );
    }

    if (response.statusCode == 413) {
      throw const ApiException(
        'El archivo es demasiado grande.',
        statusCode: 413,
      );
    }

    throw ApiException(
      _errorMessage(response),
      statusCode: response.statusCode,
    );
  }

  /// Interpreta el cuerpo JSON de una respuesta exitosa (`null` si está vacío).
  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ApiException(
        'Respuesta inesperada del servidor.',
        statusCode: response.statusCode,
      );
    }
  }

  /// Lee el mensaje de error del servidor (campos `detail` o `errors`).
  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data is Map) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;

        final errors = data['errors'];
        if (errors is Map) {
          final messages = <String>[
            for (final value in errors.values)
              if (value is List) ...value.map((item) => item.toString()),
          ];
          if (messages.isNotEmpty) return messages.join('\n');
        }

        final title = data['title'];
        if (title is String && title.isNotEmpty) return title;
      }
    } on FormatException {
      // El cuerpo no es JSON: se usa el mensaje genérico.
    }

    return switch (response.statusCode) {
      403 => 'No tienes permiso para realizar esta acción.',
      404 => 'No se encontró lo que buscas.',
      >= 500 => 'El servidor tuvo un problema. Inténtalo más tarde.',
      _ => 'No se pudo completar la operación (${response.statusCode}).',
    };
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is! List) {
      throw const ApiException('Respuesta inesperada del servidor.');
    }
    return [for (final item in data) Map<String, dynamic>.from(item as Map)];
  }

  Map<String, dynamic> _asObject(dynamic data) {
    if (data is! Map) {
      throw const ApiException('Respuesta inesperada del servidor.');
    }
    return Map<String, dynamic>.from(data);
  }
}
