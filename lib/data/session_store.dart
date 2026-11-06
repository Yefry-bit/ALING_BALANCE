import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_user.dart';

/// Sesión iniciada: token, vencimiento y datos del usuario.
class StoredSession {
  const StoredSession({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final DateTime expiresAt;
  final AppUser user;

  /// Vencida (o a punto de vencer: se deja un minuto de margen).
  bool isExpired([DateTime? now]) {
    final limit = expiresAt.subtract(const Duration(minutes: 1));
    return !(now ?? DateTime.now()).isBefore(limit);
  }

  StoredSession withUser(AppUser user) =>
      StoredSession(token: token, expiresAt: expiresAt, user: user);

  /// Respuesta de `/api/auth/login` o `/api/auth/change-password`.
  factory StoredSession.fromLoginJson(Map<String, dynamic> json) {
    return StoredSession(
      token: json['token'] as String,
      expiresAt:
          DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now().add(const Duration(hours: 8)),
      user: AppUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }

  String encode() => jsonEncode({
    'token': token,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'user': user.toJson(),
  });

  /// `null` si no hay nada guardado o si está dañado.
  static StoredSession? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return StoredSession.fromLoginJson(json);
    } catch (_) {
      return null;
    }
  }
}

/// Dónde se guarda la sesión para no pedir la contraseña cada vez que se
/// abre la app.
abstract class SessionStore {
  const SessionStore();

  /// `false` si este almacén no guarda nada (la sesión dura lo que dure la
  /// app abierta).
  bool get persistent;

  Future<StoredSession?> read();
  Future<void> write(StoredSession session);
  Future<void> clear();
}

/// No guarda la sesión (pruebas o si no se quiere recordar).
class NoSessionStore extends SessionStore {
  const NoSessionStore();

  @override
  bool get persistent => false;

  @override
  Future<StoredSession?> read() async => null;

  @override
  Future<void> write(StoredSession session) async {}

  @override
  Future<void> clear() async {}
}

/// Guarda la sesión en memoria (para pruebas).
class MemorySessionStore extends SessionStore {
  MemorySessionStore([this.session]);

  StoredSession? session;

  @override
  bool get persistent => true;

  @override
  Future<StoredSession?> read() async => session;

  @override
  Future<void> write(StoredSession session) async => this.session = session;

  @override
  Future<void> clear() async => session = null;
}

/// Guarda la sesión cifrada en el dispositivo: Keychain en iOS, Keystore en
/// Android, DPAPI en Windows y almacenamiento cifrado del navegador en web.
/// Nunca se guarda la contraseña, solo el token (que vence).
class SecureSessionStore extends SessionStore {
  const SecureSessionStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'alingbalance.session';

  final FlutterSecureStorage _storage;

  @override
  bool get persistent => true;

  @override
  Future<StoredSession?> read() async {
    try {
      return StoredSession.decode(await _storage.read(key: _key));
    } catch (_) {
      // Almacén no disponible o dañado: se pide iniciar sesión.
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) async {
    try {
      await _storage.write(key: _key, value: session.encode());
    } catch (_) {
      // Si no se puede guardar, la sesión sigue funcionando mientras la app
      // esté abierta.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
