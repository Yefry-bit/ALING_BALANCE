import 'package:aling_balance/core/navigation/app_section.dart';
import 'package:aling_balance/core/utils/formatters.dart';
import 'package:aling_balance/models/employee.dart';
import 'package:aling_balance/models/service_record.dart';
import 'package:aling_balance/models/service_status.dart';
import 'package:aling_balance/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ServiceRecord se convierte a JSON y de vuelta sin perder datos', () {
    final original = ServiceRecord(
      operation: 7,
      plate: 'ABC-123',
      vehicle: 'Chevrolet Spark',
      vehicleType: 'Particular',
      service: 'Balanceo',
      status: ServiceStatus.finished,
      price: 30000,
      date: DateTime(2026, 10, 23, 8, 30),
    );

    final copy = ServiceRecord.fromJson(original.toJson());

    expect(copy.operation, 7);
    expect(copy.plate, 'ABC-123');
    expect(copy.status, ServiceStatus.finished);
    expect(copy.price, 30000);
    expect(copy.date, original.date);
  });

  test('ServiceRecord conserva el contacto al que se avisa', () {
    final service = ServiceRecord(
      operation: 3,
      plate: 'ABC-123',
      vehicle: 'Kia Rio',
      vehicleType: 'Taxi',
      service: 'Balanceo',
      status: ServiceStatus.inProgress,
      price: 30000,
      date: DateTime(2026, 11, 5),
      contactName: 'Ana Torres',
      contactPhone: '3001234567',
    );

    final copy = ServiceRecord.fromJson(service.toJson());
    expect(copy.contactName, 'Ana Torres');
    expect(copy.contactPhone, '3001234567');

    // Cambiar el estado no pierde el contacto.
    final finished = service.copyWith(status: ServiceStatus.finished);
    expect(finished.contactName, 'Ana Torres');
    expect(finished.contactPhone, '3001234567');

    // Servicios anteriores a este dato llegan sin contacto.
    final legacy = ServiceRecord.fromJson({
      'operation': 4,
      'plate': 'DEF-456',
      'vehicle': 'Renault Logan',
      'vehicleType': 'Particular',
      'service': 'Balanceo',
      'status': 'Terminado',
      'price': 30000,
      'date': '2026-10-01T00:00:00.000',
    });
    expect(legacy.contactName, isEmpty);
    expect(legacy.contactPhone, isEmpty);
  });

  test(
    'ServiceRecord conserva el empleado asignado y tolera datos antiguos',
    () {
      final assigned = ServiceRecord(
        operation: 1,
        plate: 'ABC-123',
        vehicle: 'Mazda 3',
        vehicleType: 'Particular',
        service: 'Rines',
        status: ServiceStatus.inProgress,
        price: 50000,
        date: DateTime(2026, 10, 23),
        employeeId: 9,
        employeeName: 'Carlos Pérez',
      );

      final copy = ServiceRecord.fromJson(assigned.toJson());
      expect(copy.employeeId, 9);
      expect(copy.employeeName, 'Carlos Pérez');

      final legacy = ServiceRecord.fromJson({
        'operation': 2,
        'plate': 'DEF-456',
        'vehicle': 'Renault Logan',
        'vehicleType': 'Particular',
        'service': 'Balanceo',
        'status': 'Terminado',
        'price': 30000,
        'date': '2026-10-01T00:00:00.000',
      });
      expect(legacy.employeeId, isNull);
      expect(legacy.employeeName, '');
    },
  );

  test('Employee tolera datos incompletos al leer JSON', () {
    final employee = Employee.fromJson({'id': 1, 'name': 'Ana'});

    expect(employee.document, '');
    expect(employee.phone, '');
    expect(employee.active, isTrue);
  });

  test('formatMoney agrega separadores de miles', () {
    expect(formatMoney(0), r'$0');
    expect(formatMoney(950), r'$950');
    expect(formatMoney(20000), r'$20.000');
    expect(formatMoney(1250000), r'$1.250.000');
  });

  test('formatDate usa el formato dd/mm/aaaa', () {
    expect(formatDate(DateTime(2026, 3, 5)), '05/03/2026');
  });

  group('UserRole', () {
    test('el administrador accede a todas las secciones', () {
      expect(UserRole.admin.sections, AppSection.values);
      expect(UserRole.admin.canEditPrices, isTrue);
      expect(UserRole.admin.canManageUsers, isTrue);
    });

    test('el empleado solo accede a inicio, servicios y clientes', () {
      expect(UserRole.employee.sections, [
        AppSection.inicio,
        AppSection.servicios,
        AppSection.clientes,
      ]);
      expect(UserRole.employee.canEditPrices, isFalse);
      expect(UserRole.employee.canViewFinances, isFalse);
      expect(UserRole.employee.canManageUsers, isFalse);
    });

    test('un rol desconocido se trata como empleado', () {
      expect(UserRole.fromId('superusuario'), UserRole.employee);
      expect(UserRole.fromId('administrador'), UserRole.admin);
    });
  });
}
