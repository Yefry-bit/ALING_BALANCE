import 'user_role.dart';

/// Cuenta de acceso a la aplicación (los datos vienen del servidor).
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.active = true,
  });

  final int id;
  final String name;

  /// Nombre de usuario para iniciar sesión.
  final String username;
  final UserRole role;
  final bool active;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: UserRole.fromId(json['role']?.toString()),
      active: json['active'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'role': role.id,
      'active': active,
    };
  }

  AppUser copyWith({String? name, UserRole? role}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      username: username,
      role: role ?? this.role,
      active: active,
    );
  }
}

/// Datos que escribe el administrador al crear un usuario.
class NewUserData {
  const NewUserData({
    required this.name,
    required this.username,
    required this.password,
    required this.role,
  });

  final String name;
  final String username;
  final String password;
  final UserRole role;
}
