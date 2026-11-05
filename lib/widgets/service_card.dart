import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/utils/formatters.dart';
import '../models/service_record.dart';
import '../models/service_status.dart';
import 'plate_badge.dart';
import 'status_tag.dart';

/// Tarjeta que resume una operación de servicio.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.onChangeStatus,
    this.clientName,
    this.onPhotos,
  });

  final ServiceRecord service;
  final VoidCallback onChangeStatus;

  /// Cliente dueño del vehículo, si la placa está registrada.
  final String? clientName;

  /// Abre la galería de fotos de evidencia del servicio.
  final VoidCallback? onPhotos;

  @override
  Widget build(BuildContext context) {
    final inProgress = service.status == ServiceStatus.inProgress;
    final statusColor = inProgress ? AppColors.warning : AppColors.accent;
    const small = TextStyle(color: AppColors.secondaryText, fontSize: 12);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.panel(radius: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franja con el color del estado.
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    PlateBadge(
                                      plate: service.plate,
                                      vehicleType: service.vehicleType,
                                    ),
                                    StatusTag(status: service.status),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  service.vehicle,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${service.vehicleType} · ${service.service}',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatMoney(service.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('#${service.operation}', style: small),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          if (clientName != null)
                            _Info(Icons.person_outline, 'Cliente: $clientName'),
                          if (service.employeeName.isNotEmpty)
                            _Info(
                              Icons.engineering_outlined,
                              'Empleado: ${service.employeeName}',
                            ),
                          if (service.registeredBy.isNotEmpty)
                            _Info(
                              Icons.edit_note_rounded,
                              'Registró: ${service.registeredBy}',
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Timeline(service: service),
                      const Divider(height: 20),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (onPhotos != null)
                            TextButton.icon(
                              onPressed: onPhotos,
                              style: TextButton.styleFrom(
                                foregroundColor: service.photoCount > 0
                                    ? AppColors.info
                                    : AppColors.secondaryText,
                              ),
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 18,
                              ),
                              label: Text(
                                service.photoCount > 0
                                    ? 'Fotos (${service.photoCount})'
                                    : 'Fotos',
                              ),
                            ),
                          inProgress
                              ? FilledButton.icon(
                                  onPressed: onChangeStatus,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                  ),
                                  label: const Text('Finalizar'),
                                )
                              : TextButton.icon(
                                  onPressed: onChangeStatus,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.secondaryText,
                                  ),
                                  icon: const Icon(
                                    Icons.replay_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Reabrir'),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.mutedText),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// Hora de ingreso y de finalización del servicio, con lo que tardó.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.service});

  final ServiceRecord service;

  @override
  Widget build(BuildContext context) {
    final finished = service.status == ServiceStatus.finished;
    final finishedAt = service.finishedAt;
    final duration = service.duration;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TimePill(
          icon: Icons.login_rounded,
          color: AppColors.info,
          label: 'Ingresó',
          value: formatDateTime(service.date),
        ),
        if (finished)
          _TimePill(
            icon: Icons.flag_rounded,
            color: AppColors.accent,
            label: 'Terminó',
            value: finishedAt == null
                ? 'Hora no registrada'
                : formatDateTime(finishedAt),
          ),
        if (finished && duration != null)
          _TimePill(
            icon: Icons.timer_outlined,
            color: AppColors.violet,
            label: 'Duración',
            value: formatDuration(duration),
          ),
      ],
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppDecorations.inset(radius: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label ',
            style: const TextStyle(color: AppColors.mutedText, fontSize: 11.5),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
