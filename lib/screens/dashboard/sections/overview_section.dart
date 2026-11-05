import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/service_record.dart';
import '../../../models/user_role.dart';
import '../../../state/workshop_controller.dart';
import '../../../widgets/icon_badge.dart';
import '../../../widgets/metric_card.dart';
import '../../../widgets/service_card.dart';
import '../../../core/navigation/app_section.dart';
import '../../../core/theme/app_decorations.dart';

/// Sección "Inicio": resumen del taller, accesos rápidos y servicios recientes.
class OverviewSection extends StatelessWidget {
  const OverviewSection({
    super.key,
    required this.controller,
    required this.role,
    required this.isDesktop,
    required this.onNewService,
    required this.onNavigate,
    required this.onToggleStatus,
    this.onPhotos,
  });

  final ValueChanged<ServiceRecord>? onPhotos;
  final WorkshopController controller;
  final UserRole role;
  final bool isDesktop;
  final VoidCallback onNewService;
  final ValueChanged<AppSection> onNavigate;
  final ValueChanged<ServiceRecord> onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final recent = _RecentServices(
      services: controller.services,
      clientName: (plate) => controller.clientForPlate(plate)?.name,
      onPhotos: onPhotos,
      onNewService: onNewService,
      onToggleStatus: onToggleStatus,
    );
    final quickActions = _QuickActions(
      role: role,
      onNewService: onNewService,
      onNavigate: onNavigate,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Hero(
          inShop: controller.inProgressCount,
          isDesktop: isDesktop,
          onNewService: onNewService,
        ),
        const SizedBox(height: 22),
        _buildMetrics(),
        const SizedBox(height: 30),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: recent),
              const SizedBox(width: 18),
              Expanded(flex: 2, child: quickActions),
            ],
          )
        else ...[
          quickActions,
          const SizedBox(height: 22),
          recent,
        ],
        const SizedBox(height: 22),
        _buildStorageBanner(),
      ],
    );
  }

  Widget _buildMetrics() {
    final showMoney = role.canViewFinances;

    return GridView.count(
      crossAxisCount: showMoney ? (isDesktop ? 4 : 2) : (isDesktop ? 3 : 2),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: isDesktop ? 1.08 : 0.91,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        MetricCard(
          title: 'Servicios registrados',
          value: '${controller.services.length}',
          detail: 'Operaciones en el sistema',
          icon: Icons.car_repair_rounded,
          color: AppColors.accent,
        ),
        if (showMoney) _buildProfitCard(),
        MetricCard(
          title: 'En proceso',
          value: '${controller.inProgressCount}',
          detail: 'Vehículos pendientes',
          icon: Icons.pending_actions_rounded,
          color: AppColors.warning,
        ),
        MetricCard(
          title: 'Terminados',
          value: '${controller.completedCount}',
          detail: 'Servicios finalizados',
          icon: Icons.task_alt_rounded,
          color: AppColors.violet,
        ),
      ],
    );
  }

  /// Ganancia del mes en curso (ingresos − gastos − comisiones).
  Widget _buildProfitCard() {
    final now = DateTime.now();
    final month = controller.monthlySummary(now.year, now.month);
    final profit = month.profit;

    return MetricCard(
      title: 'Ganancia del mes',
      value: formatMoney(profit),
      detail:
          'Ingresos ${formatMoney(month.income)} · '
          'Egresos ${formatMoney(month.outflow)}',
      icon: profit >= 0 ? Icons.savings_outlined : Icons.warning_amber_rounded,
      color: profit >= 0 ? AppColors.info : Colors.redAccent,
    );
  }

  Widget _buildStorageBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBanner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.loadError ??
                  'Los datos se guardan en el servidor y se comparten entre '
                      'todos los dispositivos. Usa el botón de actualizar '
                      'para ver lo que registraron los demás.',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de los 5 servicios más recientes.
class _RecentServices extends StatelessWidget {
  const _RecentServices({
    required this.services,
    required this.clientName,
    required this.onNewService,
    required this.onToggleStatus,
    this.onPhotos,
  });

  final ValueChanged<ServiceRecord>? onPhotos;
  final List<ServiceRecord> services;
  final String? Function(String plate) clientName;
  final VoidCallback onNewService;
  final ValueChanged<ServiceRecord> onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.panel(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Servicios recientes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vehículos registrados en el taller',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 18),
          if (services.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Todavía no hay servicios registrados.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ),
            ),
          for (final service in services.take(5))
            ServiceCard(
              service: service,
              clientName: clientName(service.plate),
              onChangeStatus: () => onToggleStatus(service),
              onPhotos: onPhotos == null ? null : () => onPhotos!(service),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onNewService,
              icon: const Icon(Icons.add),
              label: const Text('Registrar servicio'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Atajos hacia las acciones más usadas.
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.role,
    required this.onNewService,
    required this.onNavigate,
  });

  final UserRole role;
  final VoidCallback onNewService;
  final ValueChanged<AppSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        title: 'Registrar servicio',
        subtitle: 'Agregar un vehículo al taller',
        icon: Icons.add_circle_outline,
        onTap: onNewService,
      ),
      _QuickAction(
        title: 'Clientes y vehículos',
        subtitle: 'Registrar clientes y sus carros',
        icon: Icons.people_alt_outlined,
        onTap: () => onNavigate(AppSection.clientes),
      ),
      if (role.canManageEmployees)
        _QuickAction(
          title: 'Gestionar empleados',
          subtitle: 'Consultar el equipo de trabajo',
          icon: Icons.groups_outlined,
          onTap: () => onNavigate(AppSection.empleados),
        ),
      if (role.canViewFinances)
        _QuickAction(
          title: 'Ver contabilidad',
          subtitle: 'Gastos y ganancias del mes',
          icon: Icons.account_balance_wallet_outlined,
          onTap: () => onNavigate(AppSection.contabilidad),
        ),
      if (role.canManageUsers)
        _QuickAction(
          title: 'Gestionar usuarios',
          subtitle: 'Crear cuentas y asignar roles',
          icon: Icons.manage_accounts_outlined,
          onTap: () => onNavigate(AppSection.usuarios),
        ),
    ];

    // Material (no Container con color) para que los ListTile pinten su efecto.
    // Material transparente + Ink: los ListTile pintan su efecto sobre el
    // panel con degradado.
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: AppDecorations.panel(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Accesos rápidos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              for (final action in actions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: IconBadge(icon: action.icon, size: 42),
                  title: Text(
                    action.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    action.subtitle,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.secondaryText,
                  ),
                  onTap: action.onTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

/// Encabezado destacado de Inicio: saludo, fecha, vehículos en el taller y
/// el botón principal.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.inShop,
    required this.isDesktop,
    required this.onNewService,
  });

  final int inShop;
  final bool isDesktop;
  final VoidCallback onNewService;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: AppDecorations.tinted(AppColors.accent, radius: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accent),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  inShop == 1
                      ? '1 vehículo en el taller ahora'
                      : '$inShop vehículos en el taller ahora',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Resumen del taller',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Controla la operación diaria de tu negocio · '
          '${formatDate(DateTime.now())}',
          style: const TextStyle(color: AppColors.secondaryText),
        ),
      ],
    );

    final button = FilledButton.icon(
      onPressed: onNewService,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Registrar servicio'),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 26 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              AppColors.accent.withValues(alpha: 0.16),
              AppColors.panelHigh,
            ),
            Color.alphaBlend(
              AppColors.accentBlue.withValues(alpha: 0.10),
              AppColors.panel,
            ),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 20),
                const Icon(
                  Icons.tire_repair_rounded,
                  size: 64,
                  color: Color(0x3327D7B0),
                ),
                const SizedBox(width: 20),
                button,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 16), button],
            ),
    );
  }
}
