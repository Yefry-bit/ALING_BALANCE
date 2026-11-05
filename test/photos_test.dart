import 'dart:typed_data';

import 'package:aling_balance/app.dart';
import 'package:aling_balance/core/utils/photo_picker.dart';
import 'package:aling_balance/data/api_client.dart';
import 'package:aling_balance/data/workshop_repository.dart';
import 'package:aling_balance/models/service_photo.dart';
import 'package:aling_balance/models/service_status.dart';
import 'package:aling_balance/state/auth_controller.dart';
import 'package:aling_balance/state/workshop_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

/// PNG válido de 1×1 píxel.
final Uint8List _png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB0, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Cámara simulada: siempre "toma" la cantidad de fotos indicada.
class _FakePicker extends PhotoPicker {
  int calls = 0;

  @override
  bool get canUseCamera => true;

  @override
  Future<List<NewPhotoData>> pick({required bool camera}) async {
    calls++;
    return [NewPhotoData(bytes: _png, fileName: 'foto.png')];
  }
}

void main() {
  group('controlador', () {
    late FakeApi fake;
    late WorkshopController controller;

    setUp(() async {
      fake = FakeApi();
      final api = ApiClient(httpClient: fake.client, baseUrl: 'http://test');
      api.token = 'token-1';
      controller = WorkshopController(repository: WorkshopRepository(api));
      fake.addService(
        plate: 'ABC-123',
        price: 30000,
        date: DateTime.now(),
        status: 'En proceso',
      );
      await controller.load();
    });

    test('finalizar sube las fotos y luego cambia el estado', () async {
      final photos = [
        NewPhotoData(
          bytes: _png,
          fileName: 'a.png',
          kind: PhotoKinds.damage,
          note: 'Rayón en la puerta',
        ),
        NewPhotoData(bytes: _png, fileName: 'b.png', kind: PhotoKinds.machine),
      ];
      final progress = <int>[];

      final error = await controller.finishService(
        1,
        photos,
        onProgress: (done, _) => progress.add(done),
      );

      expect(error, isNull);
      expect(photos, isEmpty);
      expect(progress, [0, 1, 2]);
      expect(fake.photos.length, 2);
      expect(fake.photos.first['kind'], 'Falla o daño');
      expect(fake.photos.first['note'], 'Rayón en la puerta');
      expect(fake.photoBytes[1], _png);

      final service = controller.services.single;
      expect(service.status, ServiceStatus.finished);
      expect(service.photoCount, 2);
    });

    test('si una foto falla no se finaliza el servicio', () async {
      fake.failPhotoUploads = true;
      final photos = [NewPhotoData(bytes: _png, fileName: 'a.png')];

      final error = await controller.finishService(1, photos);

      expect(error, contains('No se pudo subir una foto'));
      expect(photos.length, 1); // queda para reintentar
      expect(controller.services.single.status, ServiceStatus.inProgress);
      expect(fake.requests, isNot(contains('PATCH /api/services/1/status')));
    });

    test('finalizar sin fotos solo cambia el estado', () async {
      expect(await controller.finishService(1, []), isNull);
      expect(controller.services.single.status, ServiceStatus.finished);
      expect(fake.photos, isEmpty);
    });

    test('lista, descarga una sola vez y elimina fotos', () async {
      await controller.uploadPhoto(
        1,
        NewPhotoData(bytes: _png, fileName: 'a.png'),
      );
      final photos = await controller.photosFor(1);
      expect(photos.single.kind, PhotoKinds.vehicle);
      expect(photos.single.takenBy, 'Administrador');

      // Recién subida: los bytes ya están en memoria, no se descargan.
      fake.requests.clear();
      expect(await controller.photoBytes(photos.single.id), _png);
      expect(fake.requests, isEmpty);

      expect(await controller.deletePhoto(photos.single), isNull);
      expect(fake.photos, isEmpty);
      expect(controller.services.single.photoCount, 0);
    });

    test('un empleado no puede borrar la foto de otro', () async {
      await controller.uploadPhoto(
        1,
        NewPhotoData(bytes: _png, fileName: 'a.png'),
      );
      fake.addUser(
        name: 'María Gómez',
        username: 'maria',
        password: 'clave123',
        role: 'empleado',
      );
      final api = ApiClient(httpClient: fake.client, baseUrl: 'http://test');
      api.token = 'token-2';
      final employee = WorkshopController(repository: WorkshopRepository(api));
      await employee.load();

      final photo = (await employee.photosFor(1)).single;
      final error = await employee.deletePhoto(photo);

      expect(error, contains('Solo quien tomó la foto'));
      expect(fake.photos.length, 1);
    });
  });

  testWidgets('el empleado finaliza un servicio tomando una foto de la falla', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeApi()
      ..addUser(
        name: 'María Gómez',
        username: 'maria',
        password: 'clave123',
        role: 'empleado',
      )
      ..addService(
        plate: 'ABC-123',
        price: 30000,
        date: DateTime.now(),
        status: 'En proceso',
      );
    final picker = _FakePicker();
    final api = ApiClient(httpClient: fake.client, baseUrl: 'http://test');

    await tester.pumpWidget(
      AlingBalanceApp(auth: AuthController(api), photoPicker: picker),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'maria');
    await tester.enterText(find.byType(TextFormField).at(1), 'clave123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Servicios').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar servicio #1'), findsOneWidget);
    expect(
      find.text('Aún no hay fotos. Puedes finalizar sin ellas.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    expect(picker.calls, 1);

    await tester.tap(find.text('Falla o daño'));
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ),
      'Llanta delantera con desgaste',
    );
    await tester.pump();
    await tester.tap(find.text('Subir 1 foto(s) y finalizar'));
    await tester.pumpAndSettle();

    expect(fake.photos.single['kind'], 'Falla o daño');
    expect(fake.photos.single['note'], 'Llanta delantera con desgaste');
    expect(fake.photos.single['takenBy'], 'María Gómez');
    expect(fake.services.single['status'], 'Terminado');
    expect(find.text('Fotos (1)'), findsOneWidget);

    // La galería muestra la foto con su tipo.
    await tester.tap(find.text('Fotos (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Fotos · servicio #1'), findsOneWidget);
    expect(find.text('Falla o daño'), findsOneWidget);
  });
}
