import 'package:aling_balance/app.dart';
import 'package:aling_balance/core/constants/vehicle_catalog.dart';
import 'package:aling_balance/core/utils/formatters.dart';
import 'package:aling_balance/data/api_client.dart';
import 'package:aling_balance/models/service_record.dart';
import 'package:aling_balance/state/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  group('catálogo de marcas y modelos', () {
    test('corrige mayúsculas, tildes, espacios y guiones de la marca', () {
      expect(VehicleCatalog.canonicalBrand('chevrolet'), 'Chevrolet');
      expect(VehicleCatalog.canonicalBrand('  CHEVROLET '), 'Chevrolet');
      expect(VehicleCatalog.canonicalBrand('mercedes benz'), 'Mercedes-Benz');
      expect(VehicleCatalog.canonicalBrand('citroen'), 'Citroën');
      expect(VehicleCatalog.canonicalBrand('volks wagen'), 'Volkswagen');
      expect(VehicleCatalog.canonicalBrand('byd'), 'BYD');
    });

    test('una marca desconocida queda con mayúscula inicial', () {
      expect(VehicleCatalog.canonicalBrand('tata   motors'), 'Tata Motors');
    });

    test('corrige el modelo según la marca', () {
      expect(VehicleCatalog.canonicalModel('mazda', 'cx5'), 'CX-5');
      expect(
        VehicleCatalog.canonicalModel('Chevrolet', 'spark gt'),
        'Spark GT',
      );
      expect(
        VehicleCatalog.canonicalModel('hyundai', 'grand i 10'),
        'Grand i10',
      );
      // Modelo que no está en la lista: se deja como se escribió.
      expect(VehicleCatalog.canonicalModel('Kia', 'Rio  Xcite'), 'Rio Xcite');
      // Marca desconocida: no se toca el modelo.
      expect(VehicleCatalog.canonicalModel('Tata', 'nano'), 'nano');
    });

    test('sugiere primero lo que empieza igual y luego lo que contiene', () {
      expect(VehicleCatalog.brandSuggestions('chev'), ['Chevrolet']);
      expect(VehicleCatalog.brandSuggestions('che'), [
        'Chevrolet',
        'Chery',
        'Porsche',
      ]);
      expect(VehicleCatalog.brandSuggestions('ren').first, 'Renault');
      expect(VehicleCatalog.modelSuggestions('Mazda', 'cx'), [
        'CX-3',
        'CX-30',
        'CX-5',
        'CX-50',
        'CX-60',
        'CX-7',
        'CX-70',
        'CX-9',
        'CX-90',
      ]);
      expect(VehicleCatalog.modelSuggestions('Chevrolet', 'gt'), ['Spark GT']);
    });

    test('sin texto muestra las marcas más comunes', () {
      expect(VehicleCatalog.brandSuggestions('').take(3), [
        'Chevrolet',
        'Renault',
        'Mazda',
      ]);
    });

    test('no repite como sugerencia lo que ya está escrito completo', () {
      expect(VehicleCatalog.brandSuggestions('Kia'), isEmpty);
    });

    test('no hay marcas ni modelos repetidos', () {
      final brandKeys = VehicleCatalog.brands.map(VehicleCatalog.key).toList();
      expect(brandKeys.toSet().length, brandKeys.length);
      for (final entry in VehicleCatalog.models.entries) {
        final keys = entry.value.map(VehicleCatalog.key).toList();
        expect(keys.toSet().length, keys.length, reason: entry.key);
      }
      expect(VehicleCatalog.brands.length, greaterThanOrEqualTo(60));
    });

    test('todas las marcas y modelos pasan la validación del formulario', () {
      final valid = RegExp(
        r'^[\p{L}\p{N}][\p{L}\p{N}\p{M} .\-/+]*$',
        unicode: true,
      );
      for (final entry in VehicleCatalog.models.entries) {
        expect(valid.hasMatch(entry.key), isTrue, reason: entry.key);
        expect(entry.key.length, inInclusiveRange(2, 30));
        for (final model in entry.value) {
          expect(valid.hasMatch(model), isTrue, reason: model);
          expect(model.length, inInclusiveRange(2, 30), reason: model);
        }
      }
    });
  });

  group('hora de finalización', () {
    test('formato de hora y duración', () {
      expect(formatTime(DateTime(2026, 11, 5, 9, 5)), '9:05 a. m.');
      expect(formatTime(DateTime(2026, 11, 5, 0, 30)), '12:30 a. m.');
      expect(formatTime(DateTime(2026, 11, 5, 12, 0)), '12:00 p. m.');
      expect(formatTime(DateTime(2026, 11, 5, 16, 41)), '4:41 p. m.');
      expect(
        formatDateTime(DateTime(2026, 11, 5, 16, 41)),
        '05/11/2026 · 4:41 p. m.',
      );
      expect(formatDuration(const Duration(seconds: 20)), 'menos de 1 min');
      expect(formatDuration(const Duration(minutes: 45)), '45 min');
      expect(formatDuration(const Duration(hours: 2)), '2 h');
      expect(
        formatDuration(const Duration(hours: 2, minutes: 10)),
        '2 h 10 min',
      );
      expect(formatDuration(const Duration(days: 1, hours: 3)), '1 d 3 h');
    });

    test('lee la hora de finalización y calcula la duración', () {
      final service = ServiceRecord.fromJson({
        'operation': 1,
        'plate': 'ABC-123',
        'vehicle': 'Kia Rio',
        'vehicleType': 'Taxi',
        'service': 'Balanceo',
        'status': 'Terminado',
        'price': 30000,
        'date': '2026-11-05T14:00:00Z',
        'finishedAt': '2026-11-05T15:25:00Z',
      });

      expect(service.finishedAt, isNotNull);
      expect(service.duration, const Duration(hours: 1, minutes: 25));
    });

    test('servicios antiguos sin hora de finalización', () {
      final service = ServiceRecord.fromJson({
        'operation': 1,
        'plate': 'ABC-123',
        'vehicle': 'Kia Rio',
        'vehicleType': 'Taxi',
        'service': 'Balanceo',
        'status': 'Terminado',
        'price': 30000,
        'date': '2026-11-05T14:00:00Z',
      });

      expect(service.finishedAt, isNull);
      expect(service.duration, isNull);
    });
  });

  testWidgets('registrar con marca sugerida y ver la hora al finalizar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeApi();
    final api = ApiClient(httpClient: fake.client, baseUrl: 'http://test');
    await tester.pumpWidget(AlingBalanceApp(auth: AuthController(api)));
    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Servicios').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo servicio'));
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), 'abc123');

    // Marca: al escribir "chev" aparece "Chevrolet" para elegir.
    await tester.tap(fields.at(1));
    await tester.enterText(fields.at(1), 'chev');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chevrolet').last);
    await tester.pumpAndSettle();

    // Modelo: sugerencias de esa marca.
    await tester.tap(fields.at(2));
    await tester.enterText(fields.at(2), 'spark g');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spark GT').last);
    await tester.pumpAndSettle();

    // El nombre y el celular del cliente son obligatorios.
    await tester.ensureVisible(fields.at(3));
    await tester.enterText(fields.at(3), 'Ana Torres');
    await tester.enterText(fields.at(4), '3001234567');

    await tester.tap(find.text('Guardar servicio'));
    await tester.pumpAndSettle();

    expect(fake.services.single['vehicle'], 'Chevrolet Spark GT');

    // Sin hora de finalización mientras está en proceso.
    expect(find.text('Terminó '), findsNothing);

    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar servicio'));
    await tester.pumpAndSettle();

    expect(fake.services.single['finishedAt'], isNotNull);
    expect(find.text('Terminó '), findsOneWidget);
    expect(find.text('Duración '), findsOneWidget);
    expect(find.text('menos de 1 min'), findsOneWidget);
  });

  testWidgets('si se escribe la marca a mano se guarda bien escrita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeApi();
    final api = ApiClient(httpClient: fake.client, baseUrl: 'http://test');
    await tester.pumpWidget(AlingBalanceApp(auth: AuthController(api)));
    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
    await tester.tap(find.text('Iniciar sesión'));
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

    await tester.ensureVisible(fields.at(3));
    await tester.enterText(fields.at(3), 'Ana Torres');
    await tester.enterText(fields.at(4), '3001234567');
    await tester.tap(find.text('Guardar servicio'));
    await tester.pumpAndSettle();

    expect(fake.services.single['vehicle'], 'Mazda CX-5');
  });
}
