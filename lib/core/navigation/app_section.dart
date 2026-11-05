import 'package:flutter/material.dart';

/// Secciones del panel de administración.
enum AppSection {
  inicio(title: 'Inicio', icon: Icons.dashboard_rounded, description: ''),
  servicios(
    title: 'Servicios',
    icon: Icons.car_repair_rounded,
    description: 'Registra vehículos, asigna servicios y actualiza su estado.',
  ),
  empleados(
    title: 'Empleados',
    icon: Icons.groups_rounded,
    description: 'Organiza el personal y consulta las comisiones por trabajo.',
  ),
  clientes(
    title: 'Clientes',
    icon: Icons.people_alt_rounded,
    description:
        'Registra clientes, sus vehículos y consulta el historial '
        'de servicios de cada uno.',
  ),
  contabilidad(
    title: 'Contabilidad',
    icon: Icons.account_balance_wallet_rounded,
    description: 'Ingresos, gastos y ganancias de cada mes.',
  ),
  usuarios(
    title: 'Usuarios',
    icon: Icons.manage_accounts_rounded,
    description:
        'Crea cuentas de acceso y define si son administradores o empleados.',
  );

  const AppSection({
    required this.title,
    required this.icon,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String description;
}
