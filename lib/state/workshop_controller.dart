import 'package:flutter/foundation.dart';

import '../models/service_photo.dart';

import '../data/api_client.dart';
import '../data/workshop_repository.dart';
import '../models/client.dart';
import '../models/employee.dart';
import '../models/employee_commission.dart';
import '../models/expense.dart';
import '../models/monthly_summary.dart';
import '../models/new_employee_data.dart';
import '../models/new_service_data.dart';
import '../models/service_record.dart';
import '../models/service_status.dart';

/// Guarda el estado del taller (servicios y empleados) y las reglas de negocio.
///
/// Los datos viven en la base de datos del servidor; este controlador los
/// descarga, los mantiene en memoria y avisa a las pantallas cuando cambian.
/// Los métodos que pueden fallar devuelven el mensaje de error, o `null`
/// cuando la operación fue exitosa.
class WorkshopController extends ChangeNotifier {
  WorkshopController({required this._repository, this.includeFinances = false});

  /// Porcentaje de comisión que gana el empleado por servicio terminado.
  static const double commissionRate = 0.3;

  final WorkshopRepository _repository;

  /// Si es `true` también descarga los gastos (solo administradores pueden
  /// verlos; para un empleado el servidor respondería 403).
  final bool includeFinances;

  final List<ServiceRecord> _services = [];
  final List<Employee> _employees = [];
  final List<Client> _clients = [];
  final List<Expense> _expenses = [];

  bool _isLoading = true;
  String? _loadError;

  // ---------------------------------------------------------------- Lectura

  /// `true` mientras se hace la primera descarga de datos.
  bool get isLoading => _isLoading;

  /// Último error al descargar datos, o `null` si todo está bien.
  String? get loadError => _loadError;

  List<ServiceRecord> get services => List.unmodifiable(_services);
  List<Employee> get employees => List.unmodifiable(_employees);
  List<Client> get clients => List.unmodifiable(_clients);
  List<Expense> get expenses => List.unmodifiable(_expenses);

  int get totalRevenue {
    return _services.fold<int>(0, (total, item) => total + item.price);
  }

  int get inProgressCount {
    return _services
        .where((item) => item.status == ServiceStatus.inProgress)
        .length;
  }

  int get completedCount {
    return _services
        .where((item) => item.status == ServiceStatus.finished)
        .length;
  }

  bool documentExists(String document) {
    return _employees.any((employee) => employee.document == document.trim());
  }

  // -------------------------------------------------------------- Comisiones

  /// Comisión que genera un servicio (porcentaje fijo del precio).
  int commissionFor(ServiceRecord service) {
    return (service.price * commissionRate).round();
  }

  /// Servicios que todavía no tienen un empleado asignado.
  int get unassignedCount {
    return _services.where((s) => s.employeeId == null).length;
  }

  /// Suma de las comisiones de los servicios terminados que tienen empleado.
  int get totalCommissions {
    return _services
        .where(
          (s) => s.employeeId != null && s.status == ServiceStatus.finished,
        )
        .fold<int>(0, (total, s) => total + commissionFor(s));
  }

  /// Resumen de comisiones por empleado, de mayor a menor.
  ///
  /// Una comisión solo se acumula cuando el servicio está **terminado**.
  List<EmployeeCommission> get commissionsByEmployee {
    final names = <int, String>{};
    final assigned = <int, int>{};
    final finished = <int, int>{};
    final amount = <int, int>{};

    for (final service in _services) {
      final id = service.employeeId;
      if (id == null) continue;

      names[id] ??= service.employeeName;
      assigned[id] = (assigned[id] ?? 0) + 1;

      if (service.status == ServiceStatus.finished) {
        finished[id] = (finished[id] ?? 0) + 1;
        amount[id] = (amount[id] ?? 0) + commissionFor(service);
      }
    }

    // Todos los empleados registrados aparecen, incluso sin servicios.
    for (final employee in _employees) {
      names[employee.id] = employee.name;
    }

    final result = [
      for (final id in names.keys)
        EmployeeCommission(
          employeeId: id,
          employeeName: names[id]!,
          assignedCount: assigned[id] ?? 0,
          finishedCount: finished[id] ?? 0,
          commission: amount[id] ?? 0,
        ),
    ];

    result.sort((a, b) => b.commission.compareTo(a.commission));
    return result;
  }

  // ------------------------------------------------------------------ Carga

  /// Primera descarga de datos al abrir el panel.
  Future<void> load() async {
    await _fetch();
    _isLoading = false;
    notifyListeners();
  }

  /// Vuelve a descargar los datos (para ver lo que registraron otros
  /// dispositivos). Devuelve el error, o `null` si salió bien.
  Future<String?> refresh() async {
    await _fetch();
    notifyListeners();
    return _loadError;
  }

  Future<void> _fetch() async {
    try {
      final results = await Future.wait([
        _repository.fetchServices(),
        _repository.fetchEmployees(),
        _repository.fetchClients(),
        if (includeFinances) _repository.fetchExpenses(),
      ]);

      _services
        ..clear()
        ..addAll(results[0] as List<ServiceRecord>);
      _employees
        ..clear()
        ..addAll(results[1] as List<Employee>);
      _clients
        ..clear()
        ..addAll(results[2] as List<Client>);
      if (includeFinances) {
        _expenses
          ..clear()
          ..addAll(results[3] as List<Expense>);
      }
      _loadError = null;
    } on ApiException catch (error) {
      _loadError = error.message;
    }
  }

  // --------------------------------------------------------------- Servicios

  /// Registra un servicio en el servidor y lo agrega al inicio de la lista.
  Future<String?> addService(NewServiceData data) async {
    try {
      final created = await _repository.createService(data);
      _services.insert(0, created);
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// Alterna entre "En proceso" y "Terminado".
  Future<String?> toggleServiceStatus(int operation) async {
    final index = _services.indexWhere((s) => s.operation == operation);
    if (index == -1) return 'No se encontró el servicio.';

    final newStatus = _services[index].status.toggled;

    try {
      final updated = await _repository.updateServiceStatus(
        operation,
        newStatus,
      );
      final current = _services.indexWhere((s) => s.operation == operation);
      if (current != -1) _services[current] = updated;
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  // --------------------------------------------------------------- Empleados

  Future<String?> addEmployee(NewEmployeeData data) async {
    try {
      final created = await _repository.createEmployee(data);
      _employees.add(created);
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// Activa o desactiva un empleado. No se puede desactivar a quien todavía
  /// tiene servicios en proceso.
  Future<String?> toggleEmployeeActive(int id) async {
    final index = _employees.indexWhere((e) => e.id == id);
    if (index == -1) return 'No se encontró el empleado.';

    final employee = _employees[index];

    if (employee.active) {
      final pending = _services
          .where(
            (s) => s.employeeId == id && s.status == ServiceStatus.inProgress,
          )
          .length;
      if (pending > 0) {
        return 'No puedes desactivar a ${employee.name}: '
            'tiene $pending servicio(s) en proceso.';
      }
    }

    try {
      final updated = await _repository.setEmployeeActive(id, !employee.active);
      final current = _employees.indexWhere((e) => e.id == id);
      if (current != -1) _employees[current] = updated;
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  // ------------------------------------------------------------------- Fotos

  /// Imágenes ya descargadas (las fotos no cambian, se guardan en memoria).
  final Map<int, Future<Uint8List>> _photoBytes = {};

  Future<List<ServicePhoto>> photosFor(int operation) {
    return _repository.fetchPhotos(operation);
  }

  /// Bytes de la imagen; se descarga una sola vez por sesión.
  Future<Uint8List> photoBytes(int photoId) {
    return _photoBytes.putIfAbsent(photoId, () {
      final future = _repository.fetchPhotoBytes(photoId);
      // Si falla, se olvida para poder reintentar.
      future.catchError((_) {
        _photoBytes.remove(photoId);
        return Uint8List(0);
      });
      return future;
    });
  }

  /// Sube una foto al servicio y actualiza su contador.
  Future<String?> uploadPhoto(int operation, NewPhotoData photo) async {
    try {
      final created = await _repository.uploadPhoto(operation, photo);
      // Ya se tienen los bytes: no hace falta descargarlos de nuevo.
      _photoBytes[created.id] = Future.value(photo.bytes);
      _changePhotoCount(operation, 1);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> deletePhoto(ServicePhoto photo) async {
    try {
      await _repository.deletePhoto(photo.id);
      _photoBytes.remove(photo.id);
      _changePhotoCount(photo.operation, -1);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  void _changePhotoCount(int operation, int delta) {
    final index = _services.indexWhere((s) => s.operation == operation);
    if (index == -1) return;
    final service = _services[index];
    _services[index] = service.copyWith(
      photoCount: (service.photoCount + delta).clamp(0, 1 << 30),
    );
    notifyListeners();
  }

  /// Finaliza un servicio subiendo antes sus fotos de evidencia.
  ///
  /// Las fotos que se suben bien se quitan de [photos]; si alguna falla, el
  /// servicio **no** se finaliza y se devuelve el error, así se puede
  /// reintentar sin repetir las que ya subieron. [onProgress] recibe
  /// (subidas, total).
  Future<String?> finishService(
    int operation,
    List<NewPhotoData> photos, {
    void Function(int done, int total)? onProgress,
  }) async {
    final total = photos.length;
    var done = 0;

    while (photos.isNotEmpty) {
      onProgress?.call(done, total);
      final error = await uploadPhoto(operation, photos.first);
      if (error != null) return 'No se pudo subir una foto: $error';
      photos.removeAt(0);
      done++;
    }
    onProgress?.call(done, total);

    final index = _services.indexWhere((s) => s.operation == operation);
    if (index == -1) return 'No se encontró el servicio.';
    if (_services[index].status == ServiceStatus.finished) return null;

    return toggleServiceStatus(operation);
  }

  // ---------------------------------------------------------------- Clientes

  /// Cliente dueño de la placa, o `null` si la placa no está registrada.
  Client? clientForPlate(String plate) {
    for (final client in _clients) {
      for (final vehicle in client.vehicles) {
        if (vehicle.plate == plate) return client;
      }
    }
    return null;
  }

  /// Vehículo registrado con esa placa, o `null`.
  Vehicle? vehicleForPlate(String plate) {
    for (final client in _clients) {
      for (final vehicle in client.vehicles) {
        if (vehicle.plate == plate) return vehicle;
      }
    }
    return null;
  }

  /// Servicios hechos a los vehículos del cliente, del más reciente al más
  /// antiguo.
  List<ServiceRecord> servicesForClient(Client client) {
    final plates = {for (final v in client.vehicles) v.plate};
    return _services.where((s) => plates.contains(s.plate)).toList();
  }

  /// Indica si otro cliente ya usa esa identificación.
  bool clientDocumentExists(String document, {int? exceptId}) {
    final value = document.trim();
    return _clients.any((c) => c.document == value && c.id != exceptId);
  }

  Future<String?> addClient(ClientData data) async {
    try {
      final created = await _repository.createClient(data);
      _clients
        ..add(created)
        ..sort(_byName);
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> updateClient(int id, ClientData data) async {
    try {
      _replaceClient(await _repository.updateClient(id, data));
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> deleteClient(int id) async {
    try {
      await _repository.deleteClient(id);
      _clients.removeWhere((c) => c.id == id);
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> addVehicle(int clientId, NewVehicleData data) async {
    final owner = clientForPlate(data.plate);
    if (owner != null) {
      return 'La placa ${data.plate} ya está registrada a nombre de '
          '${owner.name}.';
    }

    try {
      _replaceClient(await _repository.addVehicle(clientId, data));
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> removeVehicle(int clientId, int vehicleId) async {
    try {
      _replaceClient(await _repository.removeVehicle(clientId, vehicleId));
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  void _replaceClient(Client updated) {
    final index = _clients.indexWhere((c) => c.id == updated.id);
    if (index == -1) {
      _clients.add(updated);
    } else {
      _clients[index] = updated;
    }
    _clients.sort(_byName);
    notifyListeners();
  }

  static int _byName(Client a, Client b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  // ------------------------------------------------------------------ Gastos

  Future<String?> addExpense(NewExpenseData data) async {
    try {
      final created = await _repository.createExpense(data);
      _expenses
        ..add(created)
        ..sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  // ------------------------------------------------------- Resumen mensual

  static bool _inMonth(DateTime date, int year, int month) =>
      date.year == year && date.month == month;

  /// Gastos del mes, del más reciente al más antiguo.
  List<Expense> expensesIn(int year, int month) {
    return _expenses.where((e) => _inMonth(e.date, year, month)).toList();
  }

  /// Total de gastos del mes por categoría, de mayor a menor.
  List<MapEntry<String, int>> expensesByCategory(int year, int month) {
    final totals = <String, int>{};
    for (final expense in expensesIn(year, month)) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Ingresos, comisiones, gastos y ganancia de un mes.
  ///
  /// Solo cuentan como ingreso los servicios **terminados** (fecha de
  /// registro dentro del mes): uno "En proceso" todavía no se ha cobrado.
  MonthlySummary monthlySummary(int year, int month) {
    var income = 0;
    var commissions = 0;
    var finished = 0;

    for (final service in _services) {
      if (service.status != ServiceStatus.finished) continue;
      if (!_inMonth(service.date, year, month)) continue;

      finished++;
      income += service.price;
      if (service.employeeId != null) commissions += commissionFor(service);
    }

    final expenses = expensesIn(
      year,
      month,
    ).fold<int>(0, (total, e) => total + e.amount);

    return MonthlySummary(
      year: year,
      month: month,
      income: income,
      commissions: commissions,
      expenses: expenses,
      finishedServices: finished,
    );
  }

  /// Resumen de los últimos [count] meses terminando en [until] (incluido),
  /// del más antiguo al más reciente.
  List<MonthlySummary> recentMonths(int count, DateTime until) {
    return [
      for (var i = count - 1; i >= 0; i--)
        () {
          final date = DateTime(until.year, until.month - i);
          return monthlySummary(date.year, date.month);
        }(),
    ];
  }
}
