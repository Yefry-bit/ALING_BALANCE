import '../core/navigation/app_section.dart';

/// Rol de un usuario del sistema y los permisos que tiene.
///
/// Toda la tabla de permisos está en este archivo: para cambiar qué puede
/// hacer un rol, solo hay que editar los getters de abajo.
enum UserRole {
  admin(id: 'administrador', label: 'Administrador'),
  employee(id: 'empleado', label: 'Empleado');

  const UserRole({required this.id, required this.label});

  /// Texto guardado en el almacenamiento.
  final String id;

  /// Texto mostrado en pantalla.
  final String label;

  // ---------------------------------------------------------------- Permisos

  /// Crear cuentas y activarlas o desactivarlas.
  bool get canManageUsers => this == UserRole.admin;

  /// Registrar empleados y activarlos o desactivarlos.
  bool get canManageEmployees => this == UserRole.admin;

  /// Ver totales de dinero y contabilidad.
  bool get canViewFinances => this == UserRole.admin;

  /// Cambiar el precio de un servicio. Los empleados usan el precio fijo.
  bool get canEditPrices => this == UserRole.admin;

  /// Eliminar clientes y quitarles vehículos. Registrar y editar clientes lo
  /// puede hacer cualquier usuario.
  bool get canDeleteClients => this == UserRole.admin;

  /// Registrar y eliminar gastos del taller.
  bool get canManageExpenses => this == UserRole.admin;

  bool canAccess(AppSection section) {
    switch (section) {
      case AppSection.inicio:
      case AppSection.servicios:
      case AppSection.clientes:
        return true;
      case AppSection.empleados:
        return canManageEmployees;
      case AppSection.contabilidad:
        return canViewFinances;
      case AppSection.usuarios:
        return canManageUsers;
    }
  }

  /// Secciones del menú que este rol puede abrir.
  List<AppSection> get sections {
    return AppSection.values.where(canAccess).toList();
  }

  /// Convierte el texto guardado en un rol. Si no se reconoce, usa el rol de
  /// menos permisos (empleado).
  static UserRole fromId(String? id) {
    return UserRole.values.firstWhere(
      (role) => role.id == id,
      orElse: () => UserRole.employee,
    );
  }
}
