import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

/// Maneja la sesión y las cuentas de usuario (datos que vienen del servidor).
///
/// Los métodos que pueden fallar devuelven el mensaje de error, o `null`
/// cuando la operación fue exitosa.
class AuthController extends ChangeNotifier {
  AuthController(this.api) : _repository = AuthRepository(api) {
    api.onUnauthorized = _handleUnauthorized;
  }

  /// Cliente compartido con el resto de la app (lleva el token de la sesión).
  final ApiClient api;
  final AuthRepository _repository;

  final List<AppUser> _users = [];
  AppUser? _currentUser;
  String? _sessionNotice;

  List<AppUser> get users => List.unmodifiable(_users);

  /// Usuario con sesión iniciada, o `null` si nadie ha entrado.
  AppUser? get currentUser => _currentUser;

  // ------------------------------------------------------------------ Sesión

  Future<String?> login(String username, String password) async {
    try {
      _currentUser = await _repository.login(username, password);
      _sessionNotice = null;
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  void logout() {
    _repository.logout();
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
    _currentUser = null;
    _users.clear();
    _sessionNotice = 'Tu sesión expiró. Inicia sesión de nuevo.';
    notifyListeners();
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

  /// Activa o desactiva una cuenta. El servidor aplica las mismas reglas.
  Future<String?> toggleUserActive(int id) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return 'No se encontró el usuario.';

    final user = _users[index];

    if (user.id == _currentUser?.id) {
      return 'No puedes desactivar tu propia cuenta.';
    }

    final isLastActiveAdmin =
        user.active &&
        user.role == UserRole.admin &&
        _users.where((u) => u.active && u.role == UserRole.admin).length == 1;
    if (isLastActiveAdmin) {
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
