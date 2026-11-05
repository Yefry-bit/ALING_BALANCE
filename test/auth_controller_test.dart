import 'package:aling_balance/data/api_client.dart';
import 'package:aling_balance/models/app_user.dart';
import 'package:aling_balance/models/user_role.dart';
import 'package:aling_balance/state/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

const _maria = NewUserData(
  name: 'María Gómez',
  username: 'maria',
  password: 'clave123',
  role: UserRole.employee,
);

void main() {
  late FakeApi fake;
  late ApiClient api;
  late AuthController auth;

  setUp(() {
    fake = FakeApi();
    api = ApiClient(httpClient: fake.client, baseUrl: 'http://test');
    auth = AuthController(api);
  });

  group('sesión', () {
    test('inicia sesión con el administrador y guarda el token', () async {
      final error = await auth.login('admin', 'admin123');

      expect(error, isNull);
      expect(auth.currentUser?.username, 'admin');
      expect(auth.currentUser?.role, UserRole.admin);
      expect(api.token, isNotNull);
    });

    test('el usuario no distingue mayúsculas ni espacios', () async {
      expect(await auth.login('  ADMIN ', 'admin123'), isNull);
    });

    test('rechaza credenciales incorrectas', () async {
      final error = await auth.login('admin', 'otra');

      expect(error, 'Usuario o contraseña incorrectos.');
      expect(auth.currentUser, isNull);
      expect(api.token, isNull);
    });

    test('una cuenta desactivada no puede entrar', () async {
      fake.addUser(
        name: 'María Gómez',
        username: 'maria',
        password: 'clave123',
        role: 'empleado',
        active: false,
      );

      final error = await auth.login('maria', 'clave123');

      expect(error, contains('desactivada'));
      expect(auth.currentUser, isNull);
    });

    test('cerrar sesión borra el usuario, la lista y el token', () async {
      await auth.login('admin', 'admin123');
      await auth.loadUsers();

      auth.logout();

      expect(auth.currentUser, isNull);
      expect(auth.users, isEmpty);
      expect(api.token, isNull);
    });

    test(
      'si el servidor rechaza el token, la sesión se cierra con aviso',
      () async {
        await auth.login('admin', 'admin123');
        fake.rejectTokens = true;

        final error = await auth.loadUsers();

        expect(error, contains('sesión expiró'));
        expect(auth.currentUser, isNull);
        expect(auth.takeSessionNotice(), contains('sesión expiró'));
        expect(auth.takeSessionNotice(), isNull);
      },
    );

    test('sin conexión el login muestra un mensaje claro', () async {
      fake.offline = true;

      final error = await auth.login('admin', 'admin123');

      expect(error, contains('No se pudo conectar'));
    });
  });

  group('usuarios', () {
    setUp(() async {
      await auth.login('admin', 'admin123');
      await auth.loadUsers();
    });

    test('crea un usuario y lo agrega a la lista', () async {
      expect(auth.users.length, 1);

      final error = await auth.createUser(_maria);

      expect(error, isNull);
      expect(auth.users.length, 2);
      expect(auth.users.last.role, UserRole.employee);
      expect(fake.users.length, 2);
    });

    test('devuelve el error del servidor si el usuario ya existe', () async {
      await auth.createUser(_maria);

      final error = await auth.createUser(_maria);

      expect(error, 'Ese nombre de usuario ya está en uso.');
      expect(auth.users.length, 2);
    });

    test('detecta nombres de usuario repetidos sin importar mayúsculas', () {
      expect(auth.usernameExists('ADMIN'), isTrue);
      expect(auth.usernameExists('nuevo'), isFalse);
    });

    test('activa y desactiva una cuenta', () async {
      await auth.createUser(_maria);
      final id = auth.users.firstWhere((u) => u.username == 'maria').id;

      expect(await auth.toggleUserActive(id), isNull);

      expect(auth.users.firstWhere((u) => u.id == id).active, isFalse);
    });

    test('no permite desactivar la propia cuenta', () async {
      final error = await auth.toggleUserActive(auth.currentUser!.id);

      expect(error, 'No puedes desactivar tu propia cuenta.');
      expect(auth.currentUser!.active, isTrue);
    });
  });
}
