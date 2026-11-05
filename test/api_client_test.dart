import 'dart:convert';

import 'package:aling_balance/data/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(int status, Object body) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

ApiClient _client(Future<http.Response> Function(http.Request) handler) {
  return ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test');
}

Future<String> _messageOf(Future<dynamic> Function() action) async {
  try {
    await action();
  } on ApiException catch (error) {
    return error.message;
  }
  fail('Se esperaba un ApiException');
}

void main() {
  test('envía el token y el tipo de contenido JSON', () async {
    late http.Request captured;
    final api = _client((request) async {
      captured = request;
      return _json(200, <dynamic>[]);
    });
    api.token = 'abc123';

    await api.getList('/api/services');

    expect(captured.headers['Authorization'], 'Bearer abc123');
    expect(captured.headers['Content-Type'], contains('application/json'));
    expect(captured.url.toString(), 'http://test/api/services');
  });

  test('no envía Authorization cuando no hay sesión', () async {
    late http.Request captured;
    final api = _client((request) async {
      captured = request;
      return _json(200, {'ok': true});
    });

    await api.postObject('/api/auth/login', {'username': 'a'});

    expect(captured.headers.containsKey('Authorization'), isFalse);
  });

  test('lee el mensaje "detail" del servidor', () async {
    final api = _client((_) async => _json(409, {'detail': 'Ya existe.'}));

    expect(await _messageOf(() => api.postObject('/api/x', {})), 'Ya existe.');
  });

  test('junta los errores de validación por campo', () async {
    final api = _client(
      (_) async => _json(400, {
        'errors': {
          'plate': ['La placa debe tener el formato ABC-123.'],
          'price': ['El precio debe ser mayor a cero.'],
        },
      }),
    );

    final message = await _messageOf(() => api.postObject('/api/x', {}));

    expect(message, contains('La placa debe tener el formato ABC-123.'));
    expect(message, contains('El precio debe ser mayor a cero.'));
  });

  test('usa mensajes claros cuando el servidor no explica el error', () async {
    expect(
      await _messageOf(
        () => _client((_) async => _json(403, {})).getList('/a'),
      ),
      contains('permiso'),
    );
    expect(
      await _messageOf(
        () => _client((_) async => _json(404, {})).getList('/a'),
      ),
      contains('No se encontró'),
    );
    expect(
      await _messageOf(
        () => _client((_) async => _json(500, {})).getList('/a'),
      ),
      contains('servidor'),
    );
  });

  test('avisa cuando hay demasiados intentos (429)', () async {
    final api = _client((_) async => _json(429, {}));

    expect(
      await _messageOf(() => api.postObject('/a', {})),
      contains('Demasiados'),
    );
  });

  test('traduce los fallos de red a un mensaje claro', () async {
    final api = _client((_) async => throw http.ClientException('sin red'));

    expect(
      await _messageOf(() => api.getList('/a')),
      contains('No se pudo conectar'),
    );
  });

  test('una respuesta que no es JSON no rompe la app', () async {
    final api = _client((_) async => http.Response('no soy json', 200));

    expect(
      await _messageOf(() => api.getList('/a')),
      contains('Respuesta inesperada'),
    );
  });

  test('un 401 con sesión limpia el token y avisa', () async {
    var notified = false;
    final api = _client((_) async => _json(401, {}));
    api.token = 'vencido';
    api.onUnauthorized = () => notified = true;

    final message = await _messageOf(() => api.getList('/api/services'));

    expect(message, contains('sesión expiró'));
    expect(api.token, isNull);
    expect(notified, isTrue);
  });

  test('un 401 sin sesión (login) muestra el mensaje del servidor', () async {
    var notified = false;
    final api = _client(
      (_) async => _json(401, {'detail': 'Credenciales malas.'}),
    );
    api.onUnauthorized = () => notified = true;

    final message = await _messageOf(
      () => api.postObject('/api/auth/login', {}),
    );

    expect(message, 'Credenciales malas.');
    expect(notified, isFalse);
  });
}
