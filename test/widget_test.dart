import 'package:aling_balance/app.dart';
import 'package:aling_balance/data/api_client.dart';
import 'package:aling_balance/state/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

/// Abre la app contra el servidor simulado, con pantalla ancha (menú lateral).
Future<FakeApi> _openApp(
  WidgetTester tester, {
  void Function(FakeApi fake)? prepare,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final fake = FakeApi();
  prepare?.call(fake);

  final api = ApiClient(httpClient: fake.client, baseUrl: 'http://test');
  await tester.pumpWidget(AlingBalanceApp(auth: AuthController(api)));
  return fake;
}

Future<void> _login(WidgetTester tester, String user, String password) async {
  await tester.enterText(find.byType(TextFormField).at(0), user);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.text('Iniciar sesión'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el login exige usuario y contraseña', (tester) async {
    await _openApp(tester);

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Ingresa tu usuario.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
  });

  testWidgets('rechaza credenciales incorrectas', (tester) async {
    await _openApp(tester);

    await _login(tester, 'admin', 'incorrecta');

    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Resumen del taller'), findsNothing);
  });

  testWidgets('el administrador ve todas las secciones', (tester) async {
    await _openApp(tester);

    await _login(tester, 'admin', 'admin123');

    expect(find.text('Resumen del taller'), findsOneWidget);
    expect(find.text('Usuarios'), findsOneWidget);
    expect(find.text('Contabilidad'), findsOneWidget);
    expect(find.text('Empleados'), findsOneWidget);
  });

  testWidgets('el empleado no ve usuarios, empleados ni contabilidad', (
    tester,
  ) async {
    await _openApp(
      tester,
      prepare: (fake) => fake.addUser(
        name: 'María Gómez',
        username: 'maria',
        password: 'clave123',
        role: 'empleado',
      ),
    );

    await _login(tester, 'maria', 'clave123');

    expect(find.text('Resumen del taller'), findsOneWidget);
    expect(find.text('Servicios'), findsWidgets);
    expect(find.text('Usuarios'), findsNothing);
    expect(find.text('Empleados'), findsNothing);
    expect(find.text('Contabilidad'), findsNothing);
  });

  testWidgets('muestra los servicios guardados en el servidor', (tester) async {
    await _openApp(
      tester,
      prepare: (fake) => fake.services.add({
        'operation': 1,
        'plate': 'ABC-123',
        'vehicle': 'Chevrolet Spark',
        'vehicleType': 'Particular',
        'service': 'Balanceo',
        'status': 'En proceso',
        'price': 30000,
        'date': DateTime.now().toUtc().toIso8601String(),
        'registeredBy': 'Administrador',
        'employeeId': null,
        'employeeName': '',
      }),
    );

    await _login(tester, 'admin', 'admin123');

    expect(find.text('ABC-123'), findsWidgets);
    expect(find.text('Chevrolet Spark'), findsWidgets);
  });

  testWidgets('clientes: muestra sus vehículos y permite agregar otro', (
    tester,
  ) async {
    final fake = await _openApp(
      tester,
      prepare: (fake) {
        final ana = fake.addClient(name: 'Ana Torres', document: '1065123456');
        fake.addVehicle(ana['id'] as int, plate: 'ABC-123');
        fake.addService(plate: 'ABC-123', price: 30000, date: DateTime.now());
      },
    );

    await _login(tester, 'admin', 'admin123');
    await tester.tap(find.text('Clientes').first);
    await tester.pumpAndSettle();

    expect(find.text('Ana Torres'), findsOneWidget);
    expect(find.text('1 vehículo'), findsOneWidget);
    expect(find.text('1 servicio'), findsOneWidget);
    expect(find.text(r'Facturado: $30.000'), findsOneWidget);

    // Desplegar la tarjeta y agregar un segundo vehículo.
    await tester.tap(find.text('Ana Torres'));
    await tester.pumpAndSettle();
    expect(find.text('Kia Rio'), findsOneWidget);

    await tester.tap(find.text('Agregar vehículo'));
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), 'xyz987');
    await tester.enterText(fields.at(1), 'Mazda');
    await tester.pump();
    await tester.enterText(fields.at(2), 'CX-5');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Agregar vehículo'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 vehículos'), findsOneWidget);
    expect(find.text('Mazda CX-5'), findsOneWidget);
    expect(find.text('XYZ-987'), findsOneWidget);
    expect((fake.clients.single['vehicles'] as List).map((v) => v['plate']), [
      'ABC-123',
      'XYZ-987',
    ]);
  });

  testWidgets('el empleado puede ver clientes pero no eliminarlos', (
    tester,
  ) async {
    await _openApp(
      tester,
      prepare: (fake) {
        fake.addUser(
          name: 'María Gómez',
          username: 'maria',
          password: 'clave123',
          role: 'empleado',
        );
        fake.addClient(name: 'Ana Torres', document: '1065123456');
      },
    );

    await _login(tester, 'maria', 'clave123');
    await tester.tap(find.text('Clientes').first);
    await tester.pumpAndSettle();

    expect(find.text('Ana Torres'), findsOneWidget);
    await tester.tap(find.text('Ana Torres'));
    await tester.pumpAndSettle();
    expect(find.text('Editar datos'), findsOneWidget);
    expect(find.text('Eliminar cliente'), findsNothing);
    expect(find.textContaining('Facturado'), findsNothing);
  });

  testWidgets('contabilidad: ganancia del mes con gastos y comisiones', (
    tester,
  ) async {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');

    await _openApp(
      tester,
      prepare: (fake) {
        fake.addEmployee(name: 'Carlos Pérez', document: '123456');
        fake.addService(
          plate: 'ABC-123',
          price: 100000,
          date: now,
          employeeId: 1,
        );
        fake.addExpense(
          description: 'Arriendo del local',
          amount: 50000,
          date: '${now.year}-$month-01',
        );
      },
    );

    await _login(tester, 'admin', 'admin123');

    // En Inicio: ganancia = 100.000 − 30.000 (comisión) − 50.000 (gasto).
    expect(find.text('Ganancia del mes'), findsOneWidget);
    expect(find.text(r'$20.000'), findsOneWidget);

    await tester.tap(find.text('Contabilidad').first);
    await tester.pumpAndSettle();

    expect(find.text('Ganancia neta'), findsOneWidget);
    expect(find.text(r'$100.000'), findsWidgets);
    expect(find.text('Arriendo del local'), findsOneWidget);
    expect(find.text('Ingresos y egresos'), findsOneWidget);
    expect(find.text('Resumen por mes'), findsOneWidget);
  });

  testWidgets('desde la ficha del cliente se registra y finaliza un servicio', (
    tester,
  ) async {
    final fake = await _openApp(
      tester,
      prepare: (fake) {
        final ana = fake.addClient(name: 'Ana Torres', document: '1065123456');
        fake.addVehicle(ana['id'] as int, plate: 'ABC-123');
        fake.addVehicle(
          ana['id'] as int,
          plate: 'XYZ-987',
          brand: 'Mazda',
          model: 'CX-5',
          vehicleType: 'Camioneta',
        );
      },
    );

    await _login(tester, 'admin', 'admin123');
    await tester.tap(find.text('Clientes').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Torres'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tiene servicios terminados.'), findsOneWidget);

    // Botón "Registrar servicio" de la fila de la camioneta (XYZ-987).
    final rowButtons = find.widgetWithText(TextButton, 'Registrar servicio');
    expect(rowButtons, findsNWidgets(2));
    await tester.ensureVisible(rowButtons.at(1));
    await tester.pumpAndSettle();
    await tester.tap(rowButtons.at(1));
    await tester.pumpAndSettle();

    // El formulario llega con los datos del vehículo.
    expect(find.text('Registrar servicio'), findsWidgets);
    expect(find.text('XYZ-987'), findsWidgets);
    expect(
      find.text('Vehículo de Ana Torres · datos completados'),
      findsOneWidget,
    );

    // El nombre llega del dueño de la placa; el celular hay que escribirlo.
    final contactFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(contactFields.at(4));
    await tester.enterText(contactFields.at(4), '3001234567');

    await tester.tap(find.text('Guardar servicio'));
    await tester.pumpAndSettle();

    expect(fake.services.single['contactName'], 'Ana Torres');
    expect(fake.services.single['contactPhone'], '3001234567');
    expect(fake.services.single['plate'], 'XYZ-987');
    expect(fake.services.single['vehicle'], 'Mazda CX-5');
    expect(fake.services.single['vehicleType'], 'Camioneta');

    // Se queda en la ficha del cliente, con el carro "en el taller".
    expect(find.text('En el taller ahora (1)'), findsOneWidget);
    expect(find.text('1 en el taller'), findsOneWidget);

    await tester.ensureVisible(find.text('Finalizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar servicio'));
    await tester.pumpAndSettle();

    expect(fake.services.single['status'], 'Terminado');
    expect(find.text('En el taller ahora (1)'), findsNothing);
    expect(find.textContaining('Terminó:'), findsOneWidget);
  });
}
