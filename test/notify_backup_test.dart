import 'package:aling_balance/core/theme/app_theme.dart';
import 'package:aling_balance/core/utils/client_notifier.dart';
import 'package:aling_balance/data/api_client.dart';
import 'package:aling_balance/models/service_record.dart';
import 'package:aling_balance/models/service_status.dart';
import 'package:aling_balance/screens/dashboard/dashboard_screen.dart';
import 'package:aling_balance/state/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

/// Guarda los enlaces en vez de abrir WhatsApp.
class _RecordingLauncher extends MessageLauncher {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

void main() {
  group('aviso al cliente', () {
    test('solo los celulares colombianos tienen WhatsApp', () {
      expect(whatsappNumber('3001234567'), '573001234567');
      expect(whatsappNumber('300 123 4567'), '573001234567');
      expect(whatsappNumber('+57 300-123-4567'), '573001234567');
      expect(whatsappNumber('6015551234'), isNull); // fijo con indicativo
      expect(whatsappNumber('5551234'), isNull); // fijo
      expect(whatsappNumber(''), isNull);
    });

    test('mensaje y enlace de WhatsApp', () {
      final service = ServiceRecord(
        operation: 7,
        plate: 'ABC-123',
        vehicle: 'Kia Rio',
        vehicleType: 'Taxi',
        service: 'Balanceo',
        status: ServiceStatus.finished,
        price: 30000,
        date: DateTime(2026, 11, 5),
      );

      final message = readyMessage(clientName: 'Ana Torres', service: service);
      expect(message, startsWith('Hola Ana, le escribimos de AlingBalance.'));
      expect(message, contains('Kia Rio de placa ABC-123 ya está listo'));
      expect(message, contains(r'Valor: $30.000.'));

      final uri = whatsappUri('573001234567', message);
      expect(uri.host, 'wa.me');
      expect(uri.path, '/573001234567');
      expect(uri.queryParameters['text'], message);
      // Espacios como %20, no "+".
      expect(uri.toString(), isNot(contains('+')));

      expect(
        smsUri('573001234567', 'Hola Ana').toString(),
        'sms:+573001234567?body=Hola%20Ana',
      );
    });
  });

  Future<(FakeApi, _RecordingLauncher)> openDashboard(
    WidgetTester tester, {
    String phone = '3001234567',
  }) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeApi()..addEmployee(name: 'Ana', document: '1001');
    final client = fake.addClient(
      name: 'Ana Torres',
      document: '1065123456',
      phone: phone,
    );
    fake.addVehicle(
      client['id'] as int,
      plate: 'ABC-123',
      brand: 'Kia',
      model: 'Rio',
      vehicleType: 'Taxi',
    );
    fake.addService(
      plate: 'ABC-123',
      price: 30000,
      date: DateTime.now(),
      status: 'En proceso',
      employeeId: 1,
    );

    final api = ApiClient(httpClient: fake.client, baseUrl: 'http://test');
    final auth = AuthController(api);
    await tester.runAsync(() => auth.login('admin', 'admin123'));
    final launcher = _RecordingLauncher();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: DashboardScreen(auth: auth, messageLauncher: launcher),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servicios').first);
    await tester.pumpAndSettle();
    return (fake, launcher);
  }

  testWidgets('al finalizar se ofrece avisar por WhatsApp', (tester) async {
    final (_, launcher) = await openDashboard(tester);

    // En proceso todavía no se ofrece.
    expect(find.text('Avisar al cliente'), findsNothing);

    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar servicio'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Avisar por WhatsApp'));
    await tester.pumpAndSettle();

    // En el celular (Android en las pruebas) se elige WhatsApp o SMS.
    expect(find.text('Mensaje de texto (SMS)'), findsOneWidget);
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();

    final uri = launcher.opened.single;
    expect(uri.host, 'wa.me');
    expect(uri.path, '/573001234567');
    expect(uri.queryParameters['text'], contains('ABC-123'));

    // Y queda el botón en la tarjeta para volver a avisar.
    await tester.tap(find.text('Avisar al cliente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mensaje de texto (SMS)'));
    await tester.pumpAndSettle();
    expect(launcher.opened.last.scheme, 'sms');
  });

  testWidgets('sin celular del cliente no aparece el aviso', (tester) async {
    await openDashboard(tester, phone: '5551234');

    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar servicio'));
    await tester.pumpAndSettle();

    expect(find.text('Avisar por WhatsApp'), findsNothing);
    expect(find.text('Avisar al cliente'), findsNothing);
  });

  testWidgets('copias de seguridad en Usuarios', (tester) async {
    final (fake, _) = await openDashboard(tester);
    await tester.tap(find.text('Usuarios').first);
    await tester.pumpAndSettle();

    expect(find.text('Copias de seguridad'), findsOneWidget);
    expect(find.text('Aún no hay copias.'), findsOneWidget);

    await tester.ensureVisible(find.text('Hacer copia ahora'));
    await tester.tap(find.text('Hacer copia ahora'));
    await tester.pumpAndSettle();

    expect(fake.backups, hasLength(1));
    expect(find.textContaining('Última copia:'), findsOneWidget);
    expect(find.textContaining('2,0 MB'), findsOneWidget);
  });
}
