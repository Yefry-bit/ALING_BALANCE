import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Servidor simulado en memoria para las pruebas.
///
/// Responde como la API real (mismos caminos, códigos y mensajes de error)
/// para probar controladores y pantallas sin red ni base de datos.
class FakeApi {
  FakeApi() {
    client = MockClient(_handle);
    addUser(
      name: 'Administrador',
      username: 'admin',
      password: 'admin123',
      role: 'administrador',
    );
  }

  late final MockClient client;

  final List<Map<String, dynamic>> users = [];
  final List<Map<String, dynamic>> employees = [];
  final List<Map<String, dynamic>> services = [];
  final Map<int, String> _passwords = {};

  /// Peticiones recibidas, por ejemplo "GET /api/services".
  final List<String> requests = [];

  /// Si es `true`, toda petición falla como si no hubiera internet.
  bool offline = false;

  /// Si es `true`, el servidor rechaza los tokens (sesión vencida).
  bool rejectTokens = false;

  int _nextUserId = 1;
  int _nextEmployeeId = 1;
  int _nextOperation = 1;
  int _nextClientId = 1;
  int _nextVehicleId = 1;
  int _nextExpenseId = 1;

  final List<Map<String, dynamic>> clients = [];
  final List<Map<String, dynamic>> expenses = [];
  final List<Map<String, dynamic>> recurringExpenses = [];
  final List<Map<String, dynamic>> backups = [];
  final List<Map<String, dynamic>> commissionPayments = [];
  int _nextRecurringId = 1;
  int _nextPaymentId = 1;

  /// Versión de las credenciales de cada usuario: al cambiar la contraseña o
  /// el rol aumenta y los tokens anteriores dejan de servir.
  final Map<int, int> _stamps = {};

  /// Último "rememberMe" recibido en el login.
  bool? lastRememberMe;

  String tokenFor(int userId) {
    final stamp = _stamps[userId] ?? 0;
    return stamp == 0 ? 'token-$userId' : 'token-$userId.$stamp';
  }

  int _commission(int price) => (price * 0.3).round();

  Map<String, dynamic> addClient({
    required String name,
    required String document,
    String phone = '',
  }) {
    final client = {
      'id': _nextClientId++,
      'name': name,
      'document': document,
      'phone': phone,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'vehicles': <Map<String, dynamic>>[],
    };
    clients.add(client);
    return client;
  }

  Map<String, dynamic> addVehicle(
    int clientId, {
    required String plate,
    String brand = 'Kia',
    String model = 'Rio',
    String vehicleType = 'Taxi',
  }) {
    final client = clients.firstWhere((c) => c['id'] == clientId);
    final vehicle = {
      'id': _nextVehicleId++,
      'clientId': clientId,
      'plate': plate,
      'brand': brand,
      'model': model,
      'vehicleType': vehicleType,
    };
    (client['vehicles'] as List).add(vehicle);
    return vehicle;
  }

  Map<String, dynamic> addExpense({
    required String description,
    required int amount,
    required String date,
    String category = 'Arriendo',
  }) {
    final expense = <String, dynamic>{
      'id': _nextExpenseId++,
      'description': description,
      'category': category,
      'amount': amount,
      'date': date,
      'registeredBy': 'Administrador',
    };
    expenses.add(expense);
    return expense;
  }

  /// Agrega un servicio ya registrado con fecha y estado a elección.
  Map<String, dynamic> addService({
    required String plate,
    required int price,
    required DateTime date,
    String status = 'Terminado',
    int? employeeId,
  }) {
    final service = {
      'operation': _nextOperation++,
      'plate': plate,
      'vehicle': 'Kia Rio',
      'vehicleType': 'Taxi',
      'service': 'Balanceo',
      'status': status,
      'price': price,
      'date': date.toUtc().toIso8601String(),
      'registeredBy': 'Administrador',
      'employeeId': employeeId,
      'employeeName': employeeId == null ? '' : 'Empleado $employeeId',
    };
    services.add(service);
    return service;
  }

  // ------------------------------------------------------- Datos de ejemplo

  Map<String, dynamic> addUser({
    required String name,
    required String username,
    required String password,
    required String role,
    bool active = true,
  }) {
    final user = {
      'id': _nextUserId++,
      'name': name,
      'username': username,
      'role': role,
      'active': active,
    };
    users.add(user);
    _passwords[user['id'] as int] = password;
    return user;
  }

  Map<String, dynamic> addEmployee({
    required String name,
    required String document,
    bool active = true,
  }) {
    final employee = {
      'id': _nextEmployeeId++,
      'name': name,
      'document': document,
      'phone': '',
      'active': active,
    };
    employees.add(employee);
    return employee;
  }

  // ---------------------------------------------------------------- Rutas

  Future<http.Response> _handle(http.Request request) async {
    if (offline) throw http.ClientException('sin conexión');

    final path = request.url.path;
    final method = request.method;
    requests.add('$method $path');

    final isMultipart = (request.headers['content-type'] ?? '').startsWith(
      'multipart/form-data',
    );
    final body = isMultipart
        ? _parseMultipart(request)
        : (request.bodyBytes.isEmpty
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(jsonDecode(request.body) as Map));

    if (method == 'POST' && path == '/api/auth/login') return _login(body);

    final current = _authenticate(request);
    if (current == null) return _problem(401, 'No autenticado.');

    final segments =
        request.url.pathSegments; // ['api', 'users', '2', 'active']
    final isAdmin = current['role'] == 'administrador';

    switch (segments[1]) {
      case 'auth':
        if (segments[2] == 'me') return _json(200, current);
        // POST /api/auth/change-password
        final id = current['id'] as int;
        if (_passwords[id] != body['currentPassword']) {
          return _json(400, {
            'errors': {
              'currentPassword': ['La contraseña actual no es correcta.'],
            },
          });
        }
        _passwords[id] = body['newPassword'].toString();
        _stamps[id] = (_stamps[id] ?? 0) + 1;
        return _session(current);
      case 'backups':
        if (!isAdmin) return _forbidden();
        if (method == 'POST') {
          final file = <String, dynamic>{
            'name': 'alingbalance-${backups.length + 1}.db',
            'sizeBytes': 2048000,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          };
          backups.insert(0, file);
          return _json(201, file);
        }
        return _json(200, {
          'available': true,
          'folder': r'C:	allerackups',
          'keep': 30,
          'files': backups,
        });
      case 'recurring-expenses':
        if (!isAdmin) return _forbidden();
        return _recurring(method, segments, body);
      case 'commissions':
        if (!isAdmin) return _forbidden();
        return _commissions(method, segments, body, current);
      case 'users':
        if (!isAdmin) return _forbidden();
        return _users(method, segments, body, current);
      case 'employees':
        if (!isAdmin && method != 'GET') return _forbidden();
        return _employees(method, segments, body, isAdmin);
      case 'services':
        if (segments.length == 4 && segments[3] == 'photos') {
          return _servicePhotos(method, int.parse(segments[2]), body, current);
        }
        return _services(method, segments, body, current);
      case 'photos':
        return _photo(method, int.parse(segments[2]), current, isAdmin);
      case 'clients':
        if (method == 'DELETE' && !isAdmin) return _forbidden();
        return _clients(method, segments, body);
      case 'expenses':
        if (!isAdmin) return _forbidden();
        return _expenses(method, segments, body, current);
    }

    return _problem(404, 'Ruta desconocida.');
  }

  Map<String, dynamic>? _authenticate(http.Request request) {
    if (rejectTokens) return null;

    final header = request.headers['Authorization'] ?? '';
    if (!header.startsWith('Bearer token-')) return null;

    final parts = header.substring('Bearer token-'.length).split('.');
    final id = int.tryParse(parts[0]);
    final stamp = parts.length > 1 ? int.tryParse(parts[1]) ?? -1 : 0;
    for (final user in users) {
      if (user['id'] == id &&
          user['active'] == true &&
          (_stamps[id] ?? 0) == stamp) {
        return user;
      }
    }
    return null;
  }

  http.Response _login(Map<String, dynamic> body) {
    final username = (body['username'] ?? '').toString().trim().toLowerCase();
    final password = (body['password'] ?? '').toString();

    final matches = users.where((u) => u['username'] == username);
    if (matches.isEmpty || _passwords[matches.first['id']] != password) {
      return _problem(401, 'Usuario o contraseña incorrectos.');
    }

    final user = matches.first;
    if (user['active'] != true) {
      return _problem(
        403,
        'Esta cuenta está desactivada. Consulta al administrador.',
      );
    }

    lastRememberMe = body['rememberMe'] as bool?;
    return _session(user, remember: lastRememberMe ?? false);
  }

  http.Response _session(Map<String, dynamic> user, {bool remember = false}) {
    final expires = DateTime.now().toUtc().add(
      remember ? const Duration(days: 30) : const Duration(hours: 8),
    );
    return _json(200, {
      'token': tokenFor(user['id'] as int),
      'expiresAt': expires.toIso8601String(),
      'user': user,
    });
  }

  http.Response _users(
    String method,
    List<String> segments,
    Map<String, dynamic> body,
    Map<String, dynamic> current,
  ) {
    if (method == 'GET') return _json(200, users);

    if (method == 'POST') {
      final username = (body['username'] ?? '').toString().toLowerCase();
      if (users.any((u) => u['username'] == username)) {
        return _problem(409, 'Ese nombre de usuario ya está en uso.');
      }
      final user = addUser(
        name: body['name'].toString(),
        username: username,
        password: body['password'].toString(),
        role: body['role'].toString(),
      );
      return _json(201, user);
    }

    final id = int.parse(segments[2]);
    final user = users.firstWhere((u) => u['id'] == id);

    // PUT /api/users/{id}
    if (method == 'PUT') {
      if (user['role'] != body['role']) {
        if (id == current['id']) {
          return _problem(400, 'No puedes cambiar tu propio rol.');
        }
        user['role'] = body['role'];
        _stamps[id] = (_stamps[id] ?? 0) + 1;
      }
      user['name'] = body['name'];
      return _json(200, user);
    }

    // PATCH /api/users/{id}/password
    if (segments.length == 4 && segments[3] == 'password') {
      _passwords[id] = body['password'].toString();
      _stamps[id] = (_stamps[id] ?? 0) + 1;
      return http.Response('', 204);
    }

    // PATCH /api/users/{id}/active
    user['active'] = body['active'];
    return _json(200, user);
  }

  http.Response _employees(
    String method,
    List<String> segments,
    Map<String, dynamic> body,
    bool isAdmin,
  ) {
    if (method == 'GET') {
      return _json(
        200,
        isAdmin
            ? employees
            : employees.where((e) => e['active'] == true).toList(),
      );
    }

    if (method == 'POST') {
      final document = body['document'].toString();
      if (employees.any((e) => e['document'] == document)) {
        return _problem(409, 'Ya existe un empleado con esa identificación.');
      }
      final employee = addEmployee(
        name: body['name'].toString(),
        document: document,
      );
      employee['phone'] = (body['phone'] ?? '').toString();
      return _json(201, employee);
    }

    final id = int.parse(segments[2]);
    final employee = employees.firstWhere((e) => e['id'] == id);
    employee['active'] = body['active'];
    return _json(200, employee);
  }

  http.Response _services(
    String method,
    List<String> segments,
    Map<String, dynamic> body,
    Map<String, dynamic> current,
  ) {
    if (method == 'GET') {
      return _json(200, services.reversed.toList());
    }

    if (method == 'POST') {
      final employeeId = body['employeeId'] as int?;
      final hasActiveEmployees = employees.any((e) => e['active'] == true);

      if (employeeId == null && hasActiveEmployees) {
        return _json(400, {
          'errors': {
            'employeeId': ['Selecciona el empleado que realiza el servicio.'],
          },
        });
      }

      final status = body['status'].toString();
      final plate = body['plate'].toString();
      final serviceType = body['serviceType'].toString();

      final duplicate = services.any(
        (s) =>
            s['plate'] == plate &&
            s['service'] == serviceType &&
            s['status'] == 'En proceso',
      );
      if (status == 'En proceso' && duplicate) {
        return _problem(
          409,
          'Ya hay un servicio «$serviceType» en proceso para la placa $plate.',
        );
      }

      String employeeName = '';
      if (employeeId != null) {
        employeeName = employees
            .firstWhere((e) => e['id'] == employeeId)['name']
            .toString();
      }

      final service = {
        'operation': _nextOperation++,
        'plate': plate,
        'vehicle': '${body['brand']} ${body['model']}',
        'vehicleType': body['vehicleType'],
        'service': serviceType,
        'status': status,
        'price': body['price'],
        'date': DateTime.now().toUtc().toIso8601String(),
        'registeredBy': current['name'],
        'employeeId': employeeId,
        'employeeName': employeeName,
      };
      services.add(service);
      return _json(201, service);
    }

    final operation = int.parse(segments[2]);
    final service = services.firstWhere((s) => s['operation'] == operation);

    // PATCH /api/services/{operation}/employee
    if (segments[3] == 'employee') {
      if (current['role'] != 'administrador') return _forbidden();
      if (service['commissionPaymentId'] != null) {
        return _problem(409, 'La comisión de este servicio ya se pagó.');
      }
      final employee = employees.firstWhere(
        (e) => e['id'] == body['employeeId'],
      );
      service['employeeId'] = employee['id'];
      service['employeeName'] = employee['name'];
      return _json(200, service);
    }

    // PATCH /api/services/{operation}/status
    if (body['status'] == 'En proceso' &&
        service['commissionPaymentId'] != null) {
      return _problem(
        409,
        'No se puede reabrir: la comisión de este servicio ya se pagó.',
      );
    }
    service['status'] = body['status'];
    service['finishedAt'] = body['status'] == 'Terminado'
        ? DateTime.now().toUtc().toIso8601String()
        : null;
    return _json(200, service);
  }

  http.Response _clients(
    String method,
    List<String> segments,
    Map<String, dynamic> body,
  ) {
    if (method == 'GET' && segments.length == 2) return _json(200, clients);

    if (method == 'POST' && segments.length == 2) {
      final document = body['document'].toString();
      if (clients.any((c) => c['document'] == document)) {
        return _problem(409, 'Ya existe un cliente con esa identificación.');
      }
      return _json(
        201,
        addClient(
          name: body['name'].toString(),
          document: document,
          phone: (body['phone'] ?? '').toString(),
        ),
      );
    }

    final id = int.parse(segments[2]);
    final matches = clients.where((c) => c['id'] == id);
    if (matches.isEmpty) return _problem(404, 'No se encontró el cliente.');
    final client = matches.first;

    // /api/clients/{id}
    if (segments.length == 3) {
      if (method == 'DELETE') {
        clients.remove(client);
        return http.Response('', 204);
      }
      // PUT
      client['name'] = body['name'];
      client['document'] = body['document'];
      client['phone'] = body['phone'] ?? '';
      return _json(200, client);
    }

    // /api/clients/{id}/vehicles[/{vehicleId}]
    final vehicles = client['vehicles'] as List;
    if (method == 'POST') {
      final plate = body['plate'].toString();
      for (final other in clients) {
        if ((other['vehicles'] as List).any((v) => v['plate'] == plate)) {
          return _problem(
            409,
            'La placa $plate ya está registrada a nombre de ${other['name']}.',
          );
        }
      }
      addVehicle(
        id,
        plate: plate,
        brand: body['brand'].toString(),
        model: body['model'].toString(),
        vehicleType: body['vehicleType'].toString(),
      );
      return _json(201, client);
    }

    // DELETE vehículo
    final vehicleId = int.parse(segments[4]);
    vehicles.removeWhere((v) => v['id'] == vehicleId);
    return _json(200, client);
  }

  http.Response _expenses(
    String method,
    List<String> segments,
    Map<String, dynamic> body,
    Map<String, dynamic> current,
  ) {
    if (method == 'GET') return _json(200, expenses);

    if (method == 'POST') {
      final amount = body['amount'] as int;
      if (amount <= 0) {
        return _json(400, {
          'errors': {
            'amount': ['El valor debe ser mayor a cero.'],
          },
        });
      }
      return _json(
        201,
        addExpense(
          description: body['description'].toString(),
          category: body['category'].toString(),
          amount: amount,
          date: body['date'].toString(),
        ),
      );
    }

    final id = int.parse(segments[2]);

    // PUT /api/expenses/{id}
    if (method == 'PUT') {
      final expense = expenses.firstWhere((e) => e['id'] == id);
      expense
        ..['description'] = body['description']
        ..['category'] = body['category']
        ..['amount'] = body['amount']
        ..['date'] = body['date'];
      return _json(200, expense);
    }

    // DELETE /api/expenses/{id}
    expenses.removeWhere((e) => e['id'] == id);
    return http.Response('', 204);
  }

  /// Fecha de hoy que usa el servidor falso para los gastos fijos.
  DateTime today = DateTime.now();

  http.Response _recurring(
    String method,
    List<String> segments,
    Map<String, dynamic> body,
  ) {
    if (method == 'GET') return _json(200, recurringExpenses);

    void generateThisMonth(Map<String, dynamic> item) {
      final day = item['dayOfMonth'] as int;
      if (item['active'] != true || day > today.day) return;
      final date = DateTime(today.year, today.month, day);
      final iso =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${day.toString().padLeft(2, '0')}';
      if (expenses.any(
        (e) => e['recurringExpenseId'] == item['id'] && e['date'] == iso,
      )) {
        return;
      }
      addExpense(
        description: item['description'].toString(),
        category: item['category'].toString(),
        amount: item['amount'] as int,
        date: iso,
      )['recurringExpenseId'] = item['id'];
    }

    if (method == 'POST') {
      final item = <String, dynamic>{
        'id': _nextRecurringId++,
        'description': body['description'],
        'category': body['category'],
        'amount': body['amount'],
        'dayOfMonth': body['dayOfMonth'],
        'active': body['active'] ?? true,
      };
      recurringExpenses.add(item);
      if (body['includeCurrentMonth'] != false) generateThisMonth(item);
      return _json(201, item);
    }

    final id = int.parse(segments[2]);
    final item = recurringExpenses.firstWhere((r) => r['id'] == id);

    if (method == 'PUT') {
      item
        ..['description'] = body['description']
        ..['category'] = body['category']
        ..['amount'] = body['amount']
        ..['dayOfMonth'] = body['dayOfMonth']
        ..['active'] = body['active'] ?? item['active'];
      return _json(200, item);
    }

    // DELETE
    recurringExpenses.remove(item);
    for (final e in expenses) {
      if (e['recurringExpenseId'] == id) e['recurringExpenseId'] = null;
    }
    return http.Response('', 204);
  }

  http.Response _commissions(
    String method,
    List<String> segments,
    Map<String, dynamic> body,
    Map<String, dynamic> current,
  ) {
    // /api/commissions/payments[/{id}]
    if (method == 'GET') return _json(200, commissionPayments);

    if (method == 'POST') {
      final employeeId = body['employeeId'] as int;
      final operations = (body['operations'] as List).cast<int>();
      final selected = services
          .where((s) => operations.contains(s['operation']))
          .toList();
      final valid =
          selected.length == operations.length &&
          selected.every(
            (s) =>
                s['employeeId'] == employeeId &&
                s['status'] == 'Terminado' &&
                s['commissionPaymentId'] == null,
          );
      if (!valid) return _problem(409, 'Algunos servicios cambiaron.');

      final payment = <String, dynamic>{
        'id': _nextPaymentId++,
        'employeeId': employeeId,
        'employeeName': employees.firstWhere(
          (e) => e['id'] == employeeId,
        )['name'],
        'year': body['year'],
        'month': body['month'],
        'amount': selected.fold<int>(
          0,
          (total, s) => total + _commission(s['price'] as int),
        ),
        'serviceCount': selected.length,
        'paidAt': DateTime.now().toUtc().toIso8601String(),
        'paidBy': current['name'],
      };
      commissionPayments.insert(0, payment);
      for (final s in selected) {
        s['commissionPaymentId'] = payment['id'];
      }
      return _json(201, payment);
    }

    // DELETE /api/commissions/payments/{id}
    final id = int.parse(segments[3]);
    commissionPayments.removeWhere((p) => p['id'] == id);
    for (final s in services) {
      if (s['commissionPaymentId'] == id) s['commissionPaymentId'] = null;
    }
    return http.Response('', 204);
  }

  // ------------------------------------------------------------------ Fotos

  final List<Map<String, dynamic>> photos = [];
  final Map<int, List<int>> photoBytes = {};
  int _nextPhotoId = 1;

  /// Si es `true`, el servidor rechaza la subida de fotos.
  bool failPhotoUploads = false;

  /// Lee los campos y el archivo de un cuerpo multipart (suficiente para
  /// las pruebas: campos de texto y un archivo).
  Map<String, dynamic> _parseMultipart(http.Request request) {
    final contentType = request.headers['content-type']!;
    final boundary = contentType.split('boundary=').last;
    final raw = latin1.decode(request.bodyBytes);
    final result = <String, dynamic>{};

    for (final part in raw.split('--$boundary')) {
      final split = part.indexOf('\r\n\r\n');
      if (split == -1) continue;
      final headers = part.substring(0, split);
      var content = part.substring(split + 4);
      if (content.endsWith('\r\n')) {
        content = content.substring(0, content.length - 2);
      }
      final name = RegExp(r'name="([^"]+)"').firstMatch(headers)?.group(1);
      if (name == null) continue;

      result[name] = headers.contains('filename=')
          ? latin1.encode(content)
          : utf8.decode(latin1.encode(content));
    }
    return result;
  }

  http.Response _servicePhotos(
    String method,
    int operation,
    Map<String, dynamic> body,
    Map<String, dynamic> current,
  ) {
    if (!services.any((s) => s['operation'] == operation)) {
      return _problem(404, 'No se encontró el servicio.');
    }

    if (method == 'GET') {
      return _json(
        200,
        photos.where((p) => p['operation'] == operation).toList(),
      );
    }

    if (failPhotoUploads) {
      return _problem(500, 'Error al guardar la foto.');
    }

    final bytes = body['file'] as List<int>?;
    if (bytes == null || bytes.isEmpty) {
      return _json(400, {
        'errors': {
          'file': ['Adjunta una foto.'],
        },
      });
    }

    final photo = {
      'id': _nextPhotoId++,
      'operation': operation,
      'kind': body['kind'],
      'note': body['note'] ?? '',
      'takenById': current['id'],
      'takenBy': current['name'],
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    photos.add(photo);
    photoBytes[photo['id'] as int] = bytes;
    _syncPhotoCount(operation);
    return _json(201, photo);
  }

  http.Response _photo(
    String method,
    int id,
    Map<String, dynamic> current,
    bool isAdmin,
  ) {
    final matches = photos.where((p) => p['id'] == id);
    if (matches.isEmpty) return _problem(404, 'No se encontró la foto.');
    final photo = matches.first;

    if (method == 'GET') {
      return http.Response.bytes(
        photoBytes[id]!,
        200,
        headers: {'content-type': 'image/png'},
      );
    }

    // DELETE
    if (!isAdmin && photo['takenById'] != current['id']) {
      return _problem(
        403,
        'Solo quien tomó la foto o un administrador puede eliminarla.',
      );
    }
    photos.remove(photo);
    photoBytes.remove(id);
    _syncPhotoCount(photo['operation'] as int);
    return http.Response('', 204);
  }

  void _syncPhotoCount(int operation) {
    final service = services.firstWhere((s) => s['operation'] == operation);
    service['photoCount'] = photos
        .where((p) => p['operation'] == operation)
        .length;
  }

  // ------------------------------------------------------------- Respuestas

  http.Response _json(int status, Object body) {
    return http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  http.Response _problem(int status, String detail) {
    return _json(status, {'status': status, 'detail': detail});
  }

  http.Response _forbidden() {
    return _problem(403, 'No tienes permiso para realizar esta acción.');
  }
}
