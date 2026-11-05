import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/utils/formatters.dart';
import '../models/client.dart';
import '../models/service_record.dart';
import '../models/service_status.dart';
import 'plate_badge.dart';
import 'service_card.dart';

/// Tarjeta de un cliente: datos de contacto, sus vehículos y el historial de
/// servicios. Se despliega al tocarla.
class ClientCard extends StatefulWidget {
  const ClientCard({
    super.key,
    required this.client,
    required this.services,
    required this.showMoney,
    required this.canDelete,
    required this.onEdit,
    required this.onAddVehicle,
    this.onDelete,
    this.onRemoveVehicle,
    this.onNewService,
    this.onToggleStatus,
    this.onPhotos,
  });

  final Client client;

  /// Servicios hechos a los vehículos del cliente (más recientes primero).
  final List<ServiceRecord> services;

  /// Mostrar el total facturado al cliente (solo administradores).
  final bool showMoney;

  /// Mostrar los botones de eliminar (solo administradores).
  final bool canDelete;

  final VoidCallback onEdit;
  final VoidCallback onAddVehicle;
  final VoidCallback? onDelete;
  final ValueChanged<Vehicle>? onRemoveVehicle;

  /// Abre el formulario de servicio con el vehículo ya cargado.
  final ValueChanged<Vehicle>? onNewService;

  /// Finalizar (con fotos) o reabrir un servicio del cliente.
  final ValueChanged<ServiceRecord>? onToggleStatus;

  /// Galería de fotos de un servicio.
  final ValueChanged<ServiceRecord>? onPhotos;

  @override
  State<ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<ClientCard> {
  bool _expanded = false;

  int get _activeCount =>
      widget.services.where((s) => s.status == ServiceStatus.inProgress).length;

  static const _small = TextStyle(color: AppColors.secondaryText, fontSize: 12);

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final services = widget.services;
    final billed = services
        .where((s) => s.status == ServiceStatus.finished)
        .fold<int>(0, (total, s) => total + s.price);

    // Material (no Container con color) para que el InkWell muestre el efecto.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Ink(
          decoration: AppDecorations.panel(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.accent.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          client.name.isEmpty
                              ? '?'
                              : client.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Documento: ${client.document}'
                              '${client.phone.isEmpty ? '' : ' · Tel: ${client.phone}'}',
                              style: _small,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _Chip(
                                  icon: Icons.directions_car_outlined,
                                  label: _plural(
                                    client.vehicles.length,
                                    'vehículo',
                                    'vehículos',
                                  ),
                                ),
                                _Chip(
                                  icon: Icons.build_outlined,
                                  label: _plural(
                                    services.length,
                                    'servicio',
                                    'servicios',
                                  ),
                                ),
                                if (_activeCount > 0)
                                  _Chip(
                                    icon: Icons.build_circle_outlined,
                                    label: '$_activeCount en el taller',
                                    color: AppColors.warning,
                                  ),
                                if (widget.showMoney)
                                  _Chip(
                                    icon: Icons.payments_outlined,
                                    label: 'Facturado: ${formatMoney(billed)}',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) _buildDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails() {
    final client = widget.client;
    final services = widget.services;
    final active = services
        .where((s) => s.status == ServiceStatus.inProgress)
        .toList();
    final history = services
        .where((s) => s.status == ServiceStatus.finished)
        .toList();
    const historyLimit = 10;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.onNewService != null && client.vehicles.isNotEmpty)
                _NewServiceButton(
                  vehicles: client.vehicles,
                  onSelected: widget.onNewService!,
                ),
              OutlinedButton.icon(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar datos'),
              ),
              if (widget.canDelete)
                OutlinedButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar cliente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: _SectionTitle('Vehículos')),
              TextButton.icon(
                onPressed: widget.onAddVehicle,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar vehículo'),
              ),
            ],
          ),
          if (client.vehicles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Este cliente aún no tiene vehículos. Agrégale uno para '
                'registrarle servicios.',
                style: _small,
              ),
            ),
          for (final vehicle in client.vehicles)
            _VehicleRow(
              vehicle: vehicle,
              services: services
                  .where((s) => s.plate == vehicle.plate)
                  .toList(),
              onNewService: widget.onNewService == null
                  ? null
                  : () => widget.onNewService!(vehicle),
              onRemove: widget.canDelete && widget.onRemoveVehicle != null
                  ? () => widget.onRemoveVehicle!(vehicle)
                  : null,
            ),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 18),
            _SectionTitle('En el taller ahora (${active.length})'),
            const SizedBox(height: 10),
            for (final service in active)
              ServiceCard(
                service: service,
                onChangeStatus: () => widget.onToggleStatus?.call(service),
                onPhotos: widget.onPhotos == null
                    ? null
                    : () => widget.onPhotos!(service),
              ),
          ],
          const SizedBox(height: 18),
          const _SectionTitle('Historial de servicios'),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Text('Aún no tiene servicios terminados.', style: _small),
          for (final service in history.take(historyLimit))
            _HistoryRow(
              service: service,
              showMoney: widget.showMoney,
              onPhotos: widget.onPhotos == null
                  ? null
                  : () => widget.onPhotos!(service),
            ),
          if (history.length > historyLimit)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Y ${history.length - historyLimit} más en la sección '
                'Servicios.',
                style: _small,
              ),
            ),
        ],
      ),
    );
  }

  static String _plural(int count, String one, String many) =>
      '$count ${count == 1 ? one : many}';
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({
    required this.vehicle,
    required this.services,
    this.onNewService,
    this.onRemove,
  });

  final Vehicle vehicle;
  final List<ServiceRecord> services;
  final VoidCallback? onNewService;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final inProgress = services
        .where((s) => s.status == ServiceStatus.inProgress)
        .length;
    final last = services.isEmpty ? null : services.first.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
      decoration: AppDecorations.inset(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlateBadge(
                plate: vehicle.plate,
                vehicleType: vehicle.vehicleType,
                small: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vehicle.description,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Quitar vehículo',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: const Icon(Icons.link_off, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 2,
            children: [
              Text(
                '${vehicle.vehicleType} · ${services.length} servicio(s)'
                '${last == null ? '' : ' · Último: ${formatDate(last)}'}',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
              if (inProgress > 0)
                const Text(
                  '● En el taller',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (onNewService != null)
                TextButton.icon(
                  onPressed: onNewService,
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('Registrar servicio'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Registrar servicio": con un solo vehículo lo abre directo; con varios
/// pregunta para cuál.
class _NewServiceButton extends StatelessWidget {
  const _NewServiceButton({required this.vehicles, required this.onSelected});

  final List<Vehicle> vehicles;
  final ValueChanged<Vehicle> onSelected;

  @override
  Widget build(BuildContext context) {
    if (vehicles.length == 1) {
      return FilledButton.icon(
        onPressed: () => onSelected(vehicles.single),
        icon: const Icon(Icons.add_task_rounded, size: 18),
        label: const Text('Registrar servicio'),
      );
    }

    return PopupMenuButton<Vehicle>(
      tooltip: 'Elegir vehículo',
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final vehicle in vehicles)
          PopupMenuItem(
            value: vehicle,
            child: Row(
              children: [
                PlateBadge(
                  plate: vehicle.plate,
                  vehicleType: vehicle.vehicleType,
                  small: true,
                ),
                const SizedBox(width: 10),
                Text(vehicle.description),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_task_rounded, size: 18, color: AppColors.background),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Registrar servicio',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, color: AppColors.background),
          ],
        ),
      ),
    );
  }
}

/// Servicio terminado: qué se hizo, cuándo terminó y acceso a sus fotos.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.service,
    required this.showMoney,
    this.onPhotos,
  });

  final ServiceRecord service;
  final bool showMoney;
  final VoidCallback? onPhotos;

  @override
  Widget build(BuildContext context) {
    final finishedAt = service.finishedAt;
    final when = finishedAt == null
        ? 'Ingresó: ${formatDateTime(service.date)}'
        : 'Terminó: ${formatDateTime(finishedAt)}'
              '${service.duration == null ? '' : ' · ${formatDuration(service.duration!)}'}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          PlateBadge(
            plate: service.plate,
            vehicleType: service.vehicleType,
            small: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showMoney
                      ? '${service.service} · ${formatMoney(service.price)}'
                      : service.service,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  when,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (onPhotos != null && service.photoCount > 0)
            IconButton(
              tooltip: 'Fotos (${service.photoCount})',
              visualDensity: VisualDensity.compact,
              onPressed: onPhotos,
              icon: const Icon(
                Icons.photo_library_outlined,
                size: 19,
                color: AppColors.info,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    this.color = AppColors.accent,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: AppDecorations.inset(radius: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
