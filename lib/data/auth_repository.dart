import '../models/app_user.dart';
import '../models/user_role.dart';
import 'session_store.dart';
import 'api_client.dart';

/// Operaciones de acceso y de usuarios contra la API.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// Inicia sesión: guarda el token en el cliente y devuelve la sesión.
  ///
  /// Con [remember] el servidor entrega un token que dura días (para no
  /// pedir la contraseña cada vez que se abre la app).
  Future<StoredSession> login(
    String username,
    String password, {
    bool remember = false,
  }) async {
    final data = await _api.postObject('/api/auth/login', {
      'username': username.trim(),
      'password': password,
      'rememberMe': remember,
    });

    final session = StoredSession.fromLoginJson(data);
    _api.token = session.token;
    return session;
  }

  /// Datos de la cuenta con el token actual (sirve para validar una sesión
  /// guardada).
  Future<AppUser> me() async {
    final json = await _api.getObject('/api/auth/me');
    return AppUser.fromJson(json);
  }

  /// Cambia la contraseña propia. El servidor cierra las demás sesiones y
  /// devuelve un token nuevo para seguir en este dispositivo.
  Future<StoredSession> changePassword(
    String current,
    String newPassword,
  ) async {
    final data = await _api.postObject('/api/auth/change-password', {
      'currentPassword': current,
      'newPassword': newPassword,
    });

    final session = StoredSession.fromLoginJson(data);
    _api.token = session.token;
    return session;
  }

  void logout() {
    _api.token = null;
  }

  Future<List<AppUser>> fetchUsers() async {
    final data = await _api.getList('/api/users');
    return data.map(AppUser.fromJson).toList();
  }

  Future<AppUser> createUser(NewUserData data) async {
    final json = await _api.postObject('/api/users', {
      'name': data.name,
      'username': data.username,
      'password': data.password,
      'role': data.role.id,
    });
    return AppUser.fromJson(json);
  }

  Future<AppUser> updateUser(int id, String name, UserRole role) async {
    final json = await _api.putObject('/api/users/$id', {
      'name': name,
      'role': role.id,
    });
    return AppUser.fromJson(json);
  }

  Future<void> resetPassword(int id, String password) async {
    await _api.patch('/api/users/$id/password', {'password': password});
  }

  Future<AppUser> setUserActive(int id, bool active) async {
    final json = await _api.patchObject('/api/users/$id/active', {
      'active': active,
    });
    return AppUser.fromJson(json);
  }
}
