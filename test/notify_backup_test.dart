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
      // Con formato de WhatsApp: emojis, negritas y secciones.
      expect(message, startsWith('✅ *¡Su vehículo está listo!* 🎉'));
      expect(message, contains('Hola *Ana*, le escribimos de *AlingBalance*.'));
      expect(message, contains('*Vehículo:* _Kia Rio_'));
      expect(message, contains('*Placa:* _ABC-123_'));
      expect(message, contains('*Servicio:* _Balanceo_'));
      expect(message, contains(r'*Valor:* _$30.000_'));
      expect(message, contains('\n'));

      // Sin precio no aparece el valor.
      expect(
        readyMessage(clientName: 'Ana', service: service, includePrice: false),
        isNot(contains('Valor')),
      );

      // Para SMS se quitan las marcas de formato.
      final plain = plainText(message);
      expect(plain, contains('Hola Ana, le escribimos de AlingBalance.'));
      expect(plain, contains('Placa: ABC-123'));
      expect(plain, isNot(contains('*')));

      final uri = whatsappUri('573001234567', message);
      expect(uri.host, 'wa.me');
      expect(uri.path, '/573001234567');
      expect(uri.queryParameters['text'], message);
      // Espacios como %20, no "+".
      expect(uri.toString(), isNot(contains('+')));
      // Los emojis viajan codificados en UTF-8.
      expect(uri.toString(), contains('%E2%9C%85')); // ✅

      // En el navegador o el computador se usa WhatsApp Web (conserva los
      // emojis, que la app de escritorio de Windows pierde).
      final web = whatsappUri('573001234567', message, desktop: true);
      expect(web.host, 'web.whatsapp.com');
      expect(web.path, '/send');
      expect(web.queryParameters['phone'], '573001234567');
      expect(web.queryParameters['text'], message);

      // Sin nombre, el saludo no deja un hueco.
      expect(
        readyMessage(clientName: '', service: service),
        contains('Hola, le escribimos de *AlingBalance*.'),
      );

      expect(
        smsUri('573001234567', 'Hola Ana').toString(),
        'sms:+573001234567?body=Hola%20Ana',
      );
    });
  });

  Future<(FakeApi, _RecordingLauncher)> openDashboard(
    WidgetTester tester, {
    String phone = '3001234567',
    String contactName = '',
    String contactPhone = '',
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
      contactName: contactName,
      contactPhone: contactPhone,
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

  testWidgets('al finalizar se abre WhatsApp con el mensaje listo', (
    tester,
  ) async {
    final (_, launcher) = await openDashboard(tester);

    // En proceso todavía no se ofrece.
    expect(find.text('Avisar al cliente'), findsNothing);

    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar servicio'));
    await tester.pumpAndSettle();

    // WhatsApp se abre solo, sin elegir nada: queda por tocar Enviar.
    final uri = launcher.opened.single;
    expect(uri.host, 'wa.me');
    expect(uri.path, '/573001234567');
    expect(uri.queryParameters['text'], contains('Hola *Ana*,'));
    expect(uri.queryParameters['text'], contains('ABC-123'));

    // Y queda el botón en la tarjeta para volver a avisar (WhatsApp o SMS).
    await tester.tap(find.text('Avisar al cliente'));
    await tester.pumpAndSettle();
    expect(find.text('Mensaje de texto (SMS)'), findsOneWidget);
    await tester.tap(find.text('Mensaje de texto (SMS)'));
    await tester.pumpAndSettle();
    expect(launcher.opened.last.scheme, 'sms');
  });

  testWidgets('sin celular del cliente no se abre WhatsApp', (tester) async {
    final (_, launcher) = await openDashboard(tester, phone: '5551234');

    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar servicio'));
    await tester.pumpAndSettle();

    expect(launcher.opened, isEmpty);
    expect(find.text('Avisar por WhatsApp'), findsNothing);
    expect(find.text('Avisar al cliente'), findsNothing);
  });

  testWidgets('el contacto del servicio tiene prioridad sobre el cliente', (
    tester,
  ) async {
    // El dueño de la placa solo tiene fijo, pero al registrar el servicio se
    // dejó un celular de contacto.
    final (_, launcher) = await openDashboard(
      tester,
      phone: '5551234',
      contactName: 'Luis Gómez',
      contactPhone: '3009998877',
    );

    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar servicio'));
    await tester.pumpAndSettle();

    final uri = launcher.opened.single;
    expect(uri.path, '/573009998877');
    expect(uri.queryParameters['text'], contains('Hola *Luis*,'));
  });

  testWidgets('el contacto se pide al registrar y al finalizar se avisa', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeApi();
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
    await tester.tap(find.text('Nuevo servicio'));
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), 'xyz987');
    await tester.enterText(fields.at(1), 'MAZDA');
    await tester.pump();
    await tester.enterText(fields.at(2), 'cx5');
    // Cierra la lista de sugerencias.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // Nombre y celular del cliente (el celular con espacios).
    await tester.ensureVisible(fields.at(3));
    await tester.enterText(fields.at(3), 'Luis Gómez');
    await tester.enterText(fields.at(4), '300 999 8877');
    await tester.tap(find.text('Guardar servicio'));
    await tester.pumpAndSettle();

    expect(fake.services.single['contactName'], 'Luis Gómez');
    expect(fake.services.single['contactPhone'], '3009998877');

    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar servicio'));
    await tester.pumpAndSettle();

    final uri = launcher.opened.single;
    expect(uri.path, '/573009998877');
    expect(uri.queryParameters['text'], contains('Hola *Luis*,'));
    expect(uri.queryParameters['text'], contains('XYZ-987'));
  });

  testWidgets('nombre y celular del cliente son obligatorios', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeApi();
    final api = ApiClient(httpClient: fake.client, baseUrl: 'http://test');
    final auth = AuthController(api);
    await tester.runAsync(() => auth.login('admin', 'admin123'));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: DashboardScreen(auth: auth),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servicios').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo servicio'));
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), 'xyz987');
    await tester.enterText(fields.at(1), 'MAZDA');
    await tester.pump();
    await tester.enterText(fields.at(2), 'cx5');
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // Sin contacto no se puede guardar.
    await tester.tap(find.text('Guardar servicio'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa el nombre del cliente.'), findsOneWidget);
    expect(find.text('Ingresa el celular del cliente.'), findsOneWidget);
    expect(fake.services, isEmpty);

    // Un fijo tampoco sirve: el aviso es por WhatsApp.
    await tester.ensureVisible(fields.at(3));
    await tester.enterText(fields.at(3), 'Luis Gómez');
    await tester.enterText(fields.at(4), '5551234');
    await tester.tap(find.text('Guardar servicio'));
    await tester.pumpAndSettle();
    expect(find.textContaining('empezar por 3'), findsOneWidget);
    expect(fake.services, isEmpty);
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
