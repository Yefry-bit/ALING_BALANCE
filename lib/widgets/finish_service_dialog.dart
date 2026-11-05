import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/utils/photo_picker.dart';
import '../models/service_photo.dart';
import '../models/service_record.dart';
import 'form_error_banner.dart';
import 'icon_badge.dart';
import 'photo_thumbnail.dart';
import 'plate_badge.dart';

/// Tamaño máximo de una foto (igual que el servidor).
const int maxPhotoBytes = 5 * 1024 * 1024;

/// Diálogo para finalizar un servicio. Permite tomar fotos de evidencia del
/// carro, de las máquinas o de cualquier falla o pieza faltante antes de
/// marcarlo como "Terminado". Las fotos son opcionales.
///
/// Devuelve `true` si el servicio quedó terminado.
class FinishServiceDialog extends StatefulWidget {
  const FinishServiceDialog({
    super.key,
    required this.service,
    required this.onFinish,
    this.picker = const PhotoPicker(),
    this.finishing = true,
  });

  final ServiceRecord service;

  /// `true`: finaliza el servicio (fotos opcionales). `false`: solo agrega
  /// fotos a un servicio (al menos una).
  final bool finishing;

  /// Sube las fotos y finaliza. Las que se suben bien se quitan de la lista.
  final Future<String?> Function(
    List<NewPhotoData> photos,
    void Function(int done, int total) onProgress,
  )
  onFinish;

  final PhotoPicker picker;

  @override
  State<FinishServiceDialog> createState() => _FinishServiceDialogState();
}

class _FinishServiceDialogState extends State<FinishServiceDialog> {
  final List<NewPhotoData> _photos = [];

  bool _saving = false;
  bool _picking = false;
  String? _error;
  int _done = 0;
  int _total = 0;

  int get _remaining =>
      PhotoKinds.maxPerService - widget.service.photoCount - _photos.length;

  Future<void> _addPhotos({required bool camera}) async {
    if (_picking || _saving || _remaining <= 0) return;
    setState(() => _picking = true);

    try {
      final picked = await widget.picker.pick(camera: camera);
      if (!mounted) return;

      final tooBig = picked.where((p) => p.bytes.length > maxPhotoBytes).length;
      final valid = picked
          .where((p) => p.bytes.length <= maxPhotoBytes)
          .take(_remaining)
          .toList();

      setState(() {
        _photos.addAll(valid);
        _error = tooBig > 0
            ? '$tooBig foto(s) pesan más de 5 MB y no se agregaron.'
            : (valid.length < picked.length - tooBig
                  ? 'Solo se agregaron ${valid.length}: el máximo es '
                        '${PhotoKinds.maxPerService} fotos por servicio.'
                  : null);
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo abrir la cámara o la galería. Revisa los '
              'permisos del dispositivo.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _finish() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _error = null;
      _done = 0;
      _total = _photos.length;
    });

    final error = await widget.onFinish(_photos, (done, total) {
      if (mounted) setState(() => _done = done);
    });

    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context, true);
    } else {
      // Las fotos que sí subieron ya no están en la lista: al reintentar
      // solo se envían las que faltan.
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final canCamera = widget.picker.canUseCamera;

    return AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      title: Row(
        children: [
          const IconBadge(icon: Icons.task_alt_rounded, brand: true, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.finishing
                  ? 'Finalizar servicio #${service.operation}'
                  : 'Agregar fotos · servicio #${service.operation}',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              if (_error != null) FormErrorBanner(message: _error!),
              _ServiceSummary(service: service),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Fotos de evidencia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.finishing ? 'Opcional · ' : ''}'
                    '${_photos.length + service.photoCount}/'
                    '${PhotoKinds.maxPerService}',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Toma fotos del carro, de las máquinas usadas o de cualquier '
                'falla o pieza faltante. Quedan guardadas con el servicio.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (canCamera)
                    FilledButton.icon(
                      onPressed: _saving || _remaining <= 0
                          ? null
                          : () => _addPhotos(camera: true),
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Tomar foto'),
                    ),
                  OutlinedButton.icon(
                    onPressed: _saving || _remaining <= 0
                        ? null
                        : () => _addPhotos(camera: false),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      canCamera ? 'Desde la galería' : 'Elegir fotos',
                    ),
                  ),
                  if (_picking)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (_photos.isEmpty)
                _EmptyPhotos(finishing: widget.finishing)
              else
                for (final photo in _photos)
                  _PendingPhoto(
                    key: ObjectKey(photo),
                    photo: photo,
                    enabled: !_saving,
                    onRemove: () => setState(() => _photos.remove(photo)),
                    onChanged: () => setState(() {}),
                  ),
              if (_saving && _total > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _total == 0 ? null : _done / _total,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _done < _total
                      ? 'Subiendo foto ${_done + 1} de $_total…'
                      : (widget.finishing
                            ? 'Fotos subidas. Finalizando…'
                            : 'Fotos subidas.'),
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondaryText),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving || (!widget.finishing && _photos.isEmpty)
              ? null
              : _finish,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(
            !widget.finishing
                ? 'Subir ${_photos.length} foto(s)'
                : (_photos.isEmpty
                      ? 'Finalizar servicio'
                      : 'Subir ${_photos.length} foto(s) y finalizar'),
          ),
        ),
      ],
    );
  }
}

class _ServiceSummary extends StatelessWidget {
  const _ServiceSummary({required this.service});

  final ServiceRecord service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.inset(radius: 14),
      child: Row(
        children: [
          PlateBadge(plate: service.plate, vehicleType: service.vehicleType),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${service.vehicle} · ${service.service}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (service.employeeName.isNotEmpty)
                  Text(
                    'Realizado por ${service.employeeName}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPhotos extends StatelessWidget {
  const _EmptyPhotos({required this.finishing});

  final bool finishing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: AppDecorations.inset(radius: 14),
      child: Column(
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            color: AppColors.mutedText,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            finishing
                ? 'Aún no hay fotos. Puedes finalizar sin ellas.'
                : 'Toma o elige las fotos que quieres agregar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

/// Foto lista para subir: miniatura, qué muestra y una descripción.
class _PendingPhoto extends StatelessWidget {
  const _PendingPhoto({
    super.key,
    required this.photo,
    required this.enabled,
    required this.onRemove,
    required this.onChanged,
  });

  final NewPhotoData photo;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  static const Map<String, IconData> _icons = {
    PhotoKinds.vehicle: Icons.directions_car_outlined,
    PhotoKinds.machine: Icons.precision_manufacturing_outlined,
    PhotoKinds.damage: Icons.report_problem_outlined,
    PhotoKinds.missing: Icons.extension_off_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: AppDecorations.inset(radius: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotoThumbnail(bytes: Future.value(photo.bytes), size: 76),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final kind in PhotoKinds.all)
                      ChoiceChip(
                        label: Text(kind),
                        avatar: Icon(_icons[kind], size: 15),
                        selected: photo.kind == kind,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(fontSize: 11.5),
                        onSelected: enabled
                            ? (_) {
                                photo.kind = kind;
                                onChanged();
                              }
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: photo.note,
                  enabled: enabled,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Descripción (ej. rayón en la puerta trasera)',
                    counterText: '',
                  ),
                  onChanged: (value) => photo.note = value,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar foto',
            onPressed: enabled ? onRemove : null,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
