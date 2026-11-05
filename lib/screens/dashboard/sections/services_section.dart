import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/service_record.dart';
import '../../../state/workshop_controller.dart';
import '../../../widgets/empty_module.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/service_card.dart';
import '../../../core/navigation/app_section.dart';

/// Sección "Servicios": lista de operaciones y botón para registrar una nueva.
class ServicesSection extends StatelessWidget {
  const ServicesSection({
    super.key,
    required this.controller,
    required this.onNewService,
    required this.onToggleStatus,
    this.onPhotos,
  });

  final WorkshopController controller;
  final VoidCallback onNewService;
  final ValueChanged<ServiceRecord> onToggleStatus;
  final ValueChanged<ServiceRecord>? onPhotos;

  @override
  Widget build(BuildContext context) {
    final services = controller.services;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: AppSection.servicios.icon,
          title: AppSection.servicios.title,
          description: AppSection.servicios.description,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '${services.length} operaciones registradas',
                style: const TextStyle(color: AppColors.secondaryText),
              ),
            ),
            FilledButton.icon(
              onPressed: onNewService,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo servicio'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (services.isEmpty)
          const EmptyModule(
            icon: Icons.car_repair_rounded,
            title: 'No hay servicios registrados',
            description: 'Pulsa “Nuevo servicio” para agregar el primero.',
          ),
        for (final service in services)
          ServiceCard(
            service: service,
            clientName: controller.clientForPlate(service.plate)?.name,
            onChangeStatus: () => onToggleStatus(service),
            onPhotos: onPhotos == null ? null : () => onPhotos!(service),
          ),
      ],
    );
  }
}
