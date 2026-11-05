import 'package:aling_balance/core/utils/formatters.dart';
import 'package:aling_balance/data/api_client.dart';
import 'package:aling_balance/data/workshop_repository.dart';
import 'package:aling_balance/models/client.dart';
import 'package:aling_balance/models/expense.dart';
import 'package:aling_balance/state/workshop_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  late FakeApi fake;
  late WorkshopController controller;

  WorkshopController buildController({
    String token = 'token-1',
    bool finances = true,
  }) {
    final api = ApiClient(httpClient: fake.client, baseUrl: 'http://test');
    api.token = token;
    return WorkshopController(
      repository: WorkshopRepository(api),
      includeFinances: finances,
    );
  }

  setUp(() async {
    fake = FakeApi();
    controller = buildController();
    await controller.load();
  });

  group('clientes y vehículos', () {
    test('un cliente puede tener varios vehículos', () async {
      expect(
        await controller.addClient(
          const ClientData(name: 'Ana Torres', document: '1065123456'),
        ),
        isNull,
      );
      final client = controller.clients.single;

      for (final plate in ['ABC-123', 'XYZ-987', 'JKL-456']) {
        final error = await controller.addVehicle(
          client.id,
          NewVehicleData(
            plate: plate,
            brand: 'Kia',
            model: 'Rio',
            vehicleType: 'Taxi',
          ),
        );
        expect(error, isNull);
      }

      expect(controller.clients.single.vehicles.length, 3);
      expect(controller.clientForPlate('XYZ-987')?.name, 'Ana Torres');
      expect(controller.vehicleForPlate('JKL-456')?.brand, 'Kia');
      expect(controller.clientForPlate('NOP-000'), isNull);
    });

    test('una placa no puede pertenecer a dos clientes', () async {
      final ana = fake.addClient(name: 'Ana Torres', document: '11111');
      fake.addVehicle(ana['id'] as int, plate: 'ABC-123');
      final luis = fake.addClient(name: 'Luis Díaz', document: '22222');
      await controller.refresh();

      final error = await controller.addVehicle(
        luis['id'] as int,
        const NewVehicleData(
          plate: 'ABC-123',
          brand: 'Kia',
          model: 'Rio',
          vehicleType: 'Taxi',
        ),
      );

      expect(error, contains('Ana Torres'));
      // Se rechaza en la app, sin llegar al servidor.
      expect(fake.requests.where((r) => r.contains('/vehicles')), isEmpty);
    });

    test(
      'el historial del cliente reúne los servicios de sus placas',
      () async {
        final ana = fake.addClient(name: 'Ana Torres', document: '11111');
        fake.addVehicle(ana['id'] as int, plate: 'ABC-123');
        fake.addVehicle(ana['id'] as int, plate: 'XYZ-987');
        fake.addService(plate: 'ABC-123', price: 30000, date: DateTime.now());
        fake.addService(plate: 'XYZ-987', price: 50000, date: DateTime.now());
        fake.addService(plate: 'OTR-111', price: 20000, date: DateTime.now());
        await controller.refresh();

        final services = controller.servicesForClient(
          controller.clients.single,
        );

        expect(
          services.map((s) => s.plate),
          unorderedEquals(['ABC-123', 'XYZ-987']),
        );
      },
    );

    test('valida la identificación repetida y permite editar', () async {
      fake.addClient(name: 'Ana Torres', document: '11111');
      await controller.refresh();
      final id = controller.clients.single.id;

      expect(controller.clientDocumentExists('11111'), isTrue);
      expect(controller.clientDocumentExists('11111', exceptId: id), isFalse);

      final error = await controller.updateClient(
        id,
        const ClientData(
          name: 'Ana María Torres',
          document: '11111',
          phone: '3001234567',
        ),
      );

      expect(error, isNull);
      expect(controller.clients.single.name, 'Ana María Torres');
      expect(controller.clients.single.phone, '3001234567');
    });

    test('quitar un vehículo y eliminar el cliente', () async {
      final ana = fake.addClient(name: 'Ana Torres', document: '11111');
      final car = fake.addVehicle(ana['id'] as int, plate: 'ABC-123');
      fake.addVehicle(ana['id'] as int, plate: 'XYZ-987');
      await controller.refresh();

      expect(
        await controller.removeVehicle(ana['id'] as int, car['id'] as int),
        isNull,
      );
      expect(controller.clients.single.vehicles.single.plate, 'XYZ-987');

      expect(await controller.deleteClient(ana['id'] as int), isNull);
      expect(controller.clients, isEmpty);
    });

    test('un empleado ve los clientes pero no descarga los gastos', () async {
      fake.addUser(
        name: 'María Gómez',
        username: 'maria',
        password: 'clave123',
        role: 'empleado',
      );
      fake.addClient(name: 'Ana Torres', document: '11111');
      fake.requests.clear();

      final employee = buildController(token: 'token-2', finances: false);
      await employee.load();

      expect(employee.loadError, isNull);
      expect(employee.clients.length, 1);
      expect(fake.requests, isNot(contains('GET /api/expenses')));
    });
  });

  group('gastos y resumen mensual', () {
    test('registrar y eliminar un gasto', () async {
      final error = await controller.addExpense(
        NewExpenseData(
          description: 'Arriendo del local',
          category: 'Arriendo',
          amount: 1500000,
          date: DateTime(2026, 11, 1),
        ),
      );

      expect(error, isNull);
      expect(fake.expenses.single['date'], '2026-11-01');
      expect(controller.expensesIn(2026, 11).single.amount, 1500000);

      expect(
        await controller.deleteExpense(controller.expenses.single.id),
        isNull,
      );
      expect(controller.expenses, isEmpty);
    });

    test('muestra el error del servidor si el gasto no es válido', () async {
      final error = await controller.addExpense(
        NewExpenseData(
          description: 'Nada',
          category: 'Otros',
          amount: 0,
          date: DateTime(2026, 11, 1),
        ),
      );

      expect(error, 'El valor debe ser mayor a cero.');
    });

    test('ganancia = servicios terminados − comisiones − gastos', () async {
      // Noviembre: 2 terminados (uno con empleado), 1 en proceso.
      fake.addService(
        plate: 'ABC-123',
        price: 100000,
        date: DateTime(2026, 11, 10, 12),
        employeeId: 1,
      );
      fake.addService(
        plate: 'XYZ-987',
        price: 50000,
        date: DateTime(2026, 11, 12, 12),
      );
      fake.addService(
        plate: 'JKL-456',
        price: 40000,
        date: DateTime(2026, 11, 13, 12),
        status: 'En proceso',
      );
      // Octubre: no debe contar en noviembre.
      fake.addService(
        plate: 'ABC-123',
        price: 70000,
        date: DateTime(2026, 10, 20, 12),
      );
      fake.addExpense(
        description: 'Arriendo',
        amount: 60000,
        date: '2026-11-01',
      );
      fake.addExpense(
        description: 'Luz',
        amount: 15000,
        date: '2026-11-15',
        category: 'Servicios públicos',
      );
      fake.addExpense(
        description: 'Arriendo',
        amount: 60000,
        date: '2026-10-01',
      );
      await controller.refresh();

      final november = controller.monthlySummary(2026, 11);

      expect(november.income, 150000); // el "En proceso" no cuenta
      expect(november.finishedServices, 2);
      expect(november.commissions, 30000); // 30 % de 100.000
      expect(november.expenses, 75000);
      expect(november.outflow, 105000);
      expect(november.profit, 45000);
      expect(november.margin, closeTo(0.3, 0.001));

      final october = controller.monthlySummary(2026, 10);
      expect(october.income, 70000);
      expect(october.profit, 10000);

      final categories = controller.expensesByCategory(2026, 11);
      expect(categories.first.key, 'Arriendo');
      expect(categories.last.value, 15000);
    });

    test('un mes con más gastos que ingresos da pérdida', () async {
      fake.addExpense(
        description: 'Nómina',
        amount: 900000,
        date: '2026-09-30',
      );
      await controller.refresh();

      final september = controller.monthlySummary(2026, 9);

      expect(september.profit, -900000);
      expect(september.margin, 0);
    });

    test('los últimos meses van en orden y cruzan de año', () {
      final months = controller.recentMonths(6, DateTime(2026, 2));

      expect(months.map((m) => '${m.year}-${m.month}'), [
        '2025-9',
        '2025-10',
        '2025-11',
        '2025-12',
        '2026-1',
        '2026-2',
      ]);
    });
  });

  group('formato de dinero', () {
    test('maneja valores negativos', () {
      expect(formatMoney(150000), r'$150.000');
      expect(formatMoney(-150000), r'-$150.000');
      expect(formatMoney(0), r'$0');
    });

    test('versión corta para los gráficos', () {
      expect(formatMoneyShort(1500000), r'$1,5 M');
      expect(formatMoneyShort(2000000), r'$2 M');
      expect(formatMoneyShort(85000), r'$85 mil');
      expect(formatMoneyShort(-45000), r'-$45 mil');
      expect(formatMoneyShort(500), r'$500');
    });

    test('nombre del mes', () {
      expect(formatMonth(2026, 11), 'Noviembre 2026');
      expect(formatMonthShort(1), 'Ene');
    });
  });
}
