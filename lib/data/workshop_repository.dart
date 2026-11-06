import 'dart:typed_data';

import '../models/client.dart';
import '../models/commission_payment.dart';
import '../models/service_photo.dart';
import '../models/employee.dart';
import '../models/expense.dart';
import '../models/new_employee_data.dart';
import '../models/new_service_data.dart';
import '../models/service_record.dart';
import '../models/service_status.dart';
import 'api_client.dart';

/// Operaciones de servicios, empleados, clientes y gastos contra la API.
class WorkshopRepository {
  WorkshopRepository(this._api);

  final ApiClient _api;

  // --------------------------------------------------------------- Servicios

  Future<List<ServiceRecord>> fetchServices() async {
    final data = await _api.getList('/api/services');
    return data.map(ServiceRecord.fromJson).toList();
  }

  Future<ServiceRecord> createService(NewServiceData data) async {
    final json = await _api.postObject('/api/services', data.toJson());
    return ServiceRecord.fromJson(json);
  }

  Future<ServiceRecord> updateServiceStatus(
    int operation,
    ServiceStatus status,
  ) async {
    final json = await _api.patchObject('/api/services/$operation/status', {
      'status': status.label,
    });
    return ServiceRecord.fromJson(json);
  }

  /// Cambia el empleado que realiza el servicio (solo administradores).
  Future<ServiceRecord> assignEmployee(int operation, int employeeId) async {
    final json = await _api.patchObject('/api/services/$operation/employee', {
      'employeeId': employeeId,
    });
    return ServiceRecord.fromJson(json);
  }

  // --------------------------------------------------------------- Empleados

  Future<List<Employee>> fetchEmployees() async {
    final data = await _api.getList('/api/employees');
    return data.map(Employee.fromJson).toList();
  }

  Future<Employee> createEmployee(NewEmployeeData data) async {
    final json = await _api.postObject('/api/employees', data.toJson());
    return Employee.fromJson(json);
  }

  Future<Employee> setEmployeeActive(int id, bool active) async {
    final json = await _api.patchObject('/api/employees/$id/active', {
      'active': active,
    });
    return Employee.fromJson(json);
  }

  // ---------------------------------------------------------------- Clientes

  Future<List<Client>> fetchClients() async {
    final data = await _api.getList('/api/clients');
    return data.map(Client.fromJson).toList();
  }

  Future<Client> createClient(ClientData data) async {
    final json = await _api.postObject('/api/clients', data.toJson());
    return Client.fromJson(json);
  }

  Future<Client> updateClient(int id, ClientData data) async {
    final json = await _api.putObject('/api/clients/$id', data.toJson());
    return Client.fromJson(json);
  }

  Future<void> deleteClient(int id) async {
    await _api.delete('/api/clients/$id');
  }

  /// Agrega un vehículo y devuelve el cliente actualizado.
  Future<Client> addVehicle(int clientId, NewVehicleData data) async {
    final json = await _api.postObject(
      '/api/clients/$clientId/vehicles',
      data.toJson(),
    );
    return Client.fromJson(json);
  }

  /// Quita un vehículo y devuelve el cliente actualizado.
  Future<Client> removeVehicle(int clientId, int vehicleId) async {
    final json = await _api.delete(
      '/api/clients/$clientId/vehicles/$vehicleId',
    );
    if (json == null) {
      throw const ApiException('Respuesta inesperada del servidor.');
    }
    return Client.fromJson(json);
  }

  // ------------------------------------------------------------------- Fotos

  Future<List<ServicePhoto>> fetchPhotos(int operation) async {
    final data = await _api.getList('/api/services/$operation/photos');
    return data.map(ServicePhoto.fromJson).toList();
  }

  Future<ServicePhoto> uploadPhoto(int operation, NewPhotoData photo) async {
    final json = await _api.postMultipart(
      '/api/services/$operation/photos',
      fileField: 'file',
      bytes: photo.bytes,
      fileName: photo.fileName,
      fields: {'kind': photo.kind, 'note': photo.note.trim()},
    );
    return ServicePhoto.fromJson(json);
  }

  Future<Uint8List> fetchPhotoBytes(int photoId) {
    return _api.getBytes('/api/photos/$photoId');
  }

  Future<void> deletePhoto(int photoId) async {
    await _api.delete('/api/photos/$photoId');
  }

  // ------------------------------------------------------------------ Gastos

  Future<List<Expense>> fetchExpenses() async {
    final data = await _api.getList('/api/expenses');
    return data.map(Expense.fromJson).toList();
  }

  Future<Expense> createExpense(NewExpenseData data) async {
    final json = await _api.postObject('/api/expenses', data.toJson());
    return Expense.fromJson(json);
  }

  Future<Expense> updateExpense(int id, NewExpenseData data) async {
    final json = await _api.putObject('/api/expenses/$id', data.toJson());
    return Expense.fromJson(json);
  }

  Future<void> deleteExpense(int id) async {
    await _api.delete('/api/expenses/$id');
  }

  // ------------------------------------------------------------ Gastos fijos

  Future<List<RecurringExpense>> fetchRecurringExpenses() async {
    final data = await _api.getList('/api/recurring-expenses');
    return data.map(RecurringExpense.fromJson).toList();
  }

  Future<RecurringExpense> createRecurringExpense(
    RecurringExpenseData data,
  ) async {
    final json = await _api.postObject(
      '/api/recurring-expenses',
      data.toJson(),
    );
    return RecurringExpense.fromJson(json);
  }

  Future<RecurringExpense> updateRecurringExpense(
    int id,
    RecurringExpenseData data,
  ) async {
    final json = await _api.putObject(
      '/api/recurring-expenses/$id',
      data.toJson(),
    );
    return RecurringExpense.fromJson(json);
  }

  Future<void> deleteRecurringExpense(int id) async {
    await _api.delete('/api/recurring-expenses/$id');
  }

  // -------------------------------------------------------------- Comisiones

  Future<List<CommissionPayment>> fetchCommissionPayments() async {
    final data = await _api.getList('/api/commissions/payments');
    return data.map(CommissionPayment.fromJson).toList();
  }

  Future<CommissionPayment> payCommissions({
    required int employeeId,
    required int year,
    required int month,
    required List<int> operations,
  }) async {
    final json = await _api.postObject('/api/commissions/payments', {
      'employeeId': employeeId,
      'year': year,
      'month': month,
      'operations': operations,
    });
    return CommissionPayment.fromJson(json);
  }

  Future<void> undoCommissionPayment(int id) async {
    await _api.delete('/api/commissions/payments/$id');
  }
}
