import '../models/app_user.dart';
import 'api_client.dart';

/// Operaciones de acceso y de usuarios contra la API.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// Inicia sesión: guarda el token en el cliente y devuelve el usuario.
  Future<AppUser> login(String username, String password) async {
    final data = await _api.postObject('/api/auth/login', {
      'username': username.trim(),
      'password': password,
    });

    _api.token = data['token'] as String;
    return AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
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

  Future<AppUser> setUserActive(int id, bool active) async {
    final json = await _api.patchObject('/api/users/$id/active', {
      'active': active,
    });
    return AppUser.fromJson(json);
  }
}
