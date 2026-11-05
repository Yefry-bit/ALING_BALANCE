import 'package:aling_balance/data/api_client.dart';
import 'package:aling_balance/data/workshop_repository.dart';
import 'package:aling_balance/models/new_employee_data.dart';
import 'package:aling_balance/models/new_service_data.dart';
import 'package:aling_balance/models/service_status.dart';
import 'package:aling_balance/state/workshop_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

NewServiceData _service({
  String plate = 'ABC-123',
  String serviceType = 'Balanceo',
  ServiceStatus status = ServiceStatus.inProgress,
  int price = 30000,
  int? employeeId,
}) {
  return NewServiceData(
    plate: plate,
    brand: 'Kia',
    model: 'Rio',
    vehicleType: 'Taxi',
    serviceType: serviceType,
    status: status,
    price: price,
    employeeId: employeeId,
  );
}

void main() {
  late FakeApi fake;
  late WorkshopController controller;

  setUp(() async {
    fake = FakeApi();
    final api = ApiClient(httpClient: fake.client, baseUrl: 'http://test');
    api.token = 'token-1'; // sesión del administrador
    controller = WorkshopController(repository: WorkshopRepository(api));
    await controller.load();
  });

  group('carga de datos', () {
    test('empieza vacío cuando la base de datos no tiene registros', () {
      expect(controller.isLoading, isFalse);
      expect(controller.loadError, isNull);
      expect(controller.services, isEmpty);
      expect(controller.employees, isEmpty);
    });

    test('descarga lo que ya está guardado en el servidor', () async {
      fake.addEmployee(name: 'Carlos Pérez', document: '123456');

      final error = await controller.refresh();

      expect(error, isNull);
      expect(controller.employees.length, 1);
    });

    test('si no hay conexión informa el error y no se rompe', () async {
      fake.offline = true;

      final error = await controller.refresh();

      expect(error, contains('No se pudo conectar'));
      expect(controller.loadError, isNotNull);
    });
  });

  group('servicios', () {
    test('registra un servicio en el servidor y lo muestra primero', () async {
      expect(await controller.addService(_service()), isNull);
      expect(await controller.addService(_service(plate: 'DEF-456')), isNull);

      expect(fake.services.length, 2);
      expect(controller.services.first.plate, 'DEF-456');
      expect(controller.services.first.registeredBy, 'Administrador');
      expect(controller.services.first.vehicle, 'Kia Rio');
    });

    test('calcula totales y contadores', () async {
      await controller.addService(_service(price: 30000));
      await controller.addService(
        _service(
          plate: 'DEF-456',
          status: ServiceStatus.finished,
          price: 50000,
        ),
      );

      expect(controller.totalRevenue, 80000);
      expect(controller.inProgressCount, 1);
      expect(controller.completedCount, 1);
    });

    test(
      'devuelve el error del servidor si el servicio está repetido',
      () async {
        await controller.addService(_service());

        final error = await controller.addService(_service());

        expect(error, contains('en proceso para la placa ABC-123'));
        expect(controller.services.length, 1);
      },
    );

    test('exige empleado cuando hay empleados activos', () async {
      await controller.addEmployee(
        const NewEmployeeData(name: 'Carlos Pérez', document: '123456'),
      );

      final error = await controller.addService(_service());

      expect(error, contains('Selecciona el empleado'));
    });

    test('alterna el estado de un servicio', () async {
      await controller.addService(_service());
      final operation = controller.services.first.operation;

      expect(await controller.toggleServiceStatus(operation), isNull);
      expect(controller.completedCount, 1);

      expect(await controller.toggleServiceStatus(operation), isNull);
      expect(controller.inProgressCount, 1);
    });

    test('avisa si el servicio no existe', () async {
      expect(await controller.toggleServiceStatus(999), isNotNull);
    });
  });

  group('empleados', () {
    const carlos = NewEmployeeData(name: 'Carlos Pérez', document: '123456');

    test('registra un empleado y detecta documentos repetidos', () async {
      expect(controller.documentExists('123456'), isFalse);

      expect(await controller.addEmployee(carlos), isNull);

      expect(controller.employees.length, 1);
      expect(controller.documentExists('123456'), isTrue);
      expect(
        await controller.addEmployee(carlos),
        'Ya existe un empleado con esa identificación.',
      );
      expect(controller.employees.length, 1);
    });

    test('activa y desactiva un empleado', () async {
      await controller.addEmployee(carlos);
      final id = controller.employees.first.id;

      expect(await controller.toggleEmployeeActive(id), isNull);

      expect(controller.employees.first.active, isFalse);
    });

    test('no deja desactivar a un empleado con servicios en proceso', () async {
      await controller.addEmployee(carlos);
      final id = controller.employees.first.id;
      await controller.addService(_service(employeeId: id));

      final error = await controller.toggleEmployeeActive(id);

      expect(error, contains('tiene 1 servicio(s) en proceso'));
      expect(controller.employees.first.active, isTrue);
    });
  });

  group('comisiones', () {
    test(
      'solo cuentan los servicios terminados con empleado asignado',
      () async {
        await controller.addEmployee(
          const NewEmployeeData(name: 'Carlos Pérez', document: '123456'),
        );
        final id = controller.employees.first.id;

        await controller.addService(
          _service(
            plate: 'AAA-111',
            status: ServiceStatus.finished,
            price: 50000,
            employeeId: id,
          ),
        );
        await controller.addService(
          _service(plate: 'BBB-222', price: 30000, employeeId: id),
        );

        var summary = controller.commissionsByEmployee.first;
        expect(summary.employeeName, 'Carlos Pérez');
        expect(summary.assignedCount, 2);
        expect(summary.finishedCount, 1);
        expect(summary.commission, 15000);
        expect(controller.totalCommissions, 15000);

        final pending = controller.services
            .firstWhere((s) => s.plate == 'BBB-222')
            .operation;
        await controller.toggleServiceStatus(pending);

        summary = controller.commissionsByEmployee.first;
        expect(summary.commission, 24000);
        expect(controller.totalCommissions, 24000);
      },
    );

    test('los servicios sin empleado no generan comisión', () async {
      await controller.addService(_service(status: ServiceStatus.finished));

      expect(controller.unassignedCount, 1);
      expect(controller.totalCommissions, 0);
    });
  });
}
