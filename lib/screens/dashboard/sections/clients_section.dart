import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_section.dart';
import '../../../models/client.dart';
import '../../../models/service_record.dart';
import '../../../models/user_role.dart';
import '../../../state/workshop_controller.dart';
import '../../../widgets/client_card.dart';
import '../../../widgets/empty_module.dart';
import '../../../widgets/section_header.dart';

/// Sección "Clientes": lista de clientes con sus vehículos, buscador y
/// botón para registrar uno nuevo.
class ClientsSection extends StatefulWidget {
  const ClientsSection({
    super.key,
    required this.controller,
    required this.role,
    required this.onNewClient,
    required this.onEditClient,
    required this.onDeleteClient,
    required this.onAddVehicle,
    required this.onRemoveVehicle,
    this.onNewService,
    this.onToggleStatus,
    this.onPhotos,
  });

  final WorkshopController controller;
  final UserRole role;
  final VoidCallback onNewClient;
  final ValueChanged<Client> onEditClient;
  final ValueChanged<Client> onDeleteClient;
  final ValueChanged<Client> onAddVehicle;
  final void Function(Client client, Vehicle vehicle) onRemoveVehicle;
  final ValueChanged<Vehicle>? onNewService;
  final ValueChanged<ServiceRecord>? onToggleStatus;
  final ValueChanged<ServiceRecord>? onPhotos;

  @override
  State<ClientsSection> createState() => _ClientsSectionState();
}

class _ClientsSectionState extends State<ClientsSection> {
  String _query = '';

  /// Busca por nombre, identificación o placa (sin importar mayúsculas ni el
  /// guion de la placa).
  bool _matches(Client client) {
    final query = _query.trim().toLowerCase().replaceAll('-', '');
    if (query.isEmpty) return true;

    return client.name.toLowerCase().contains(query) ||
        client.document.contains(query) ||
        client.vehicles.any(
          (v) => v.plate.toLowerCase().replaceAll('-', '').contains(query),
        );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final all = controller.clients;
    final clients = all.where(_matches).toList();
    final vehicleCount = all.fold<int>(
      0,
      (total, c) => total + c.vehicles.length,
    );
    final canDelete = widget.role.canDeleteClients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: AppSection.clientes.icon,
          title: AppSection.clientes.title,
          description: AppSection.clientes.description,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '${all.length} clientes · $vehicleCount vehículos registrados',
                style: const TextStyle(color: AppColors.secondaryText),
              ),
            ),
            FilledButton.icon(
              onPressed: widget.onNewClient,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nuevo cliente'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (all.isNotEmpty) ...[
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre, identificación o placa',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (all.isEmpty)
          const EmptyModule(
            icon: Icons.people_alt_rounded,
            title: 'No hay clientes registrados',
            description:
                'Pulsa “Nuevo cliente” para registrar al primero y '
                'luego agrégale sus vehículos.',
          )
        else if (clients.isEmpty)
          const EmptyModule(
            icon: Icons.search_off,
            title: 'Sin resultados',
            description: 'Ningún cliente coincide con la búsqueda.',
          ),
        for (final client in clients)
          ClientCard(
            key: ValueKey(client.id),
            client: client,
            services: controller.servicesForClient(client),
            showMoney: widget.role.canViewFinances,
            canDelete: canDelete,
            onEdit: () => widget.onEditClient(client),
            onDelete: () => widget.onDeleteClient(client),
            onAddVehicle: () => widget.onAddVehicle(client),
            onRemoveVehicle: (vehicle) =>
                widget.onRemoveVehicle(client, vehicle),
            onNewService: widget.onNewService,
            onToggleStatus: widget.onToggleStatus,
            onPhotos: widget.onPhotos,
          ),
      ],
    );
  }
}
