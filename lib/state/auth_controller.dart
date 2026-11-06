import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/session_store.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

/// Maneja la sesión y las cuentas de usuario (datos que vienen del servidor).
///
/// Los métodos que pueden fallar devuelven el mensaje de error, o `null`
/// cuando la operación fue exitosa.
class AuthController extends ChangeNotifier {
  AuthController(this.api, {SessionStore sessionStore = const NoSessionStore()})
    : _repository = AuthRepository(api),
      _store = sessionStore {
    api.onUnauthorized = _handleUnauthorized;
  }

  /// Cliente compartido con el resto de la app (lleva el token de la sesión).
  final ApiClient api;
  final AuthRepository _repository;
  final SessionStore _store;

  final List<AppUser> _users = [];
  AppUser? _currentUser;
  String? _sessionNotice;

  /// La sesión actual quedó guardada en el dispositivo.
  bool _remembered = false;

  List<AppUser> get users => List.unmodifiable(_users);

  /// Usuario con sesión iniciada, o `null` si nadie ha entrado.
  AppUser? get currentUser => _currentUser;

  /// Este dispositivo puede guardar la sesión ("Mantener la sesión iniciada").
  bool get canRememberSession => _store.persistent;

  // ------------------------------------------------------------------ Sesión

  /// Inicia sesión. Con [remember] la sesión queda guardada de forma segura
  /// en el dispositivo y no se pide la contraseña al volver a abrir la app.
  Future<String?> login(
    String username,
    String password, {
    bool remember = false,
  }) async {
    final keep = remember && _store.persistent;
    try {
      final session = await _repository.login(
        username,
        password,
        remember: keep,
      );
      _currentUser = session.user;
      _sessionNotice = null;
      _remembered = keep;

      if (keep) {
        await _store.write(session);
      } else {
        await _store.clear();
      }

      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// Recupera la sesión guardada al abrir la app. Devuelve `true` si se pudo
  /// entrar sin pedir la contraseña.
  ///
  /// Si la sesión venció, o el servidor la rechaza (cuenta desactivada,
  /// contraseña o rol cambiados), se borra y se pide iniciar sesión. Si el
  /// servidor no responde se entra con los datos guardados; las pantallas
  /// mostrarán el error de conexión.
  Future<bool> restoreSession() async {
    final saved = await _store.read();
    if (saved == null) return false;

    if (saved.isExpired()) {
      await _store.clear();
      return false;
    }

    api.token = saved.token;
    _remembered = true;

    AppUser user;
    try {
      user = await _repository.me();
    } on ApiException catch (error) {
      if (error.statusCode == 401 ||
          error.statusCode == 403 ||
          error.statusCode == 404) {
        api.token = null;
        _currentUser = null;
        _remembered = false;
        await _store.clear();
        return false;
      }
      user = saved.user;
    }

    _currentUser = user;
    await _store.write(saved.withUser(user));
    notifyListeners();
    return true;
  }

  void logout() {
    _repository.logout();
    _store.clear();
    _remembered = false;
    _currentUser = null;
    _users.clear();
    notifyListeners();
  }

  /// Mensaje pendiente para el login (por ejemplo, "sesión expirada").
  /// Se entrega una sola vez.
  String? takeSessionNotice() {
    final notice = _sessionNotice;
    _sessionNotice = null;
    return notice;
  }

  void _handleUnauthorized() {
    _store.clear();
    _remembered = false;
    _currentUser = null;
    _users.clear();
    _sessionNotice = 'Tu sesión expiró. Inicia sesión de nuevo.';
    notifyListeners();
  }

  /// Cambia la contraseña propia. Las sesiones en otros dispositivos se
  /// cierran; en este se sigue con un token nuevo.
  Future<String?> changePassword(String current, String newPassword) async {
    try {
      final session = await _repository.changePassword(current, newPassword);
      _currentUser = session.user;
      if (_remembered) await _store.write(session);
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  // ---------------------------------------------------------------- Usuarios

  /// Descarga la lista de usuarios (solo la puede ver un administrador).
  Future<String?> loadUsers() async {
    try {
      final users = await _repository.fetchUsers();
      _users
        ..clear()
        ..addAll(users);
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  bool usernameExists(String username) {
    final normalized = username.trim().toLowerCase();
    return _users.any((user) => user.username == normalized);
  }

  Future<String?> createUser(NewUserData data) async {
    try {
      final created = await _repository.createUser(data);
      _users.add(created);
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// Si [user] es el último administrador activo.
  bool isLastActiveAdmin(AppUser user) {
    return user.active &&
        user.role == UserRole.admin &&
        _users.where((u) => u.active && u.role == UserRole.admin).length == 1;
  }

  /// Edita nombre y rol. Si cambia el rol, las sesiones de esa persona se
  /// cierran para que entre con los permisos nuevos.
  Future<String?> updateUser(int id, String name, UserRole role) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return 'No se encontró el usuario.';
    final user = _users[index];

    if (role != user.role) {
      if (user.id == _currentUser?.id) {
        return 'No puedes cambiar tu propio rol. Pídeselo a otro administrador.';
      }
      if (isLastActiveAdmin(user)) {
        return 'Debe quedar al menos un administrador activo.';
      }
    }

    try {
      final updated = await _repository.updateUser(id, name, role);
      final current = _users.indexWhere((u) => u.id == id);
      if (current != -1) _users[current] = updated;
      if (_currentUser?.id == id) {
        _currentUser = _currentUser!.copyWith(name: updated.name);
      }
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// Asigna una contraseña nueva a otra cuenta (si la olvidó).
  Future<String?> resetPassword(int id, String password) async {
    if (id == _currentUser?.id) {
      return 'Para tu propia cuenta usa «Cambiar contraseña».';
    }
    try {
      await _repository.resetPassword(id, password);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// Activa o desactiva una cuenta. El servidor aplica las mismas reglas.
  Future<String?> toggleUserActive(int id) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return 'No se encontró el usuario.';

    final user = _users[index];

    if (user.id == _currentUser?.id) {
      return 'No puedes desactivar tu propia cuenta.';
    }

    if (isLastActiveAdmin(user)) {
      return 'Debe quedar al menos un administrador activo.';
    }

    try {
      final updated = await _repository.setUserActive(id, !user.active);
      final current = _users.indexWhere((u) => u.id == id);
      if (current != -1) _users[current] = updated;
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }
}
