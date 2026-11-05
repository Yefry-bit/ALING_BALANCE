import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/utils/formatters.dart';
import '../core/utils/photo_picker.dart';
import '../models/service_photo.dart';
import '../models/service_record.dart';
import '../state/workshop_controller.dart';
import 'confirm_dialog.dart';
import 'finish_service_dialog.dart';
import 'photo_thumbnail.dart';
import 'plate_badge.dart';

/// Galería con las fotos de evidencia de un servicio. Permite ampliarlas,
/// agregar más y eliminarlas (quien la tomó o un administrador).
class ServicePhotosDialog extends StatefulWidget {
  const ServicePhotosDialog({
    super.key,
    required this.operation,
    required this.controller,
    required this.currentUserId,
    required this.isAdmin,
    this.picker = const PhotoPicker(),
  });

  final int operation;
  final WorkshopController controller;
  final int currentUserId;
  final bool isAdmin;
  final PhotoPicker picker;

  @override
  State<ServicePhotosDialog> createState() => _ServicePhotosDialogState();
}

class _ServicePhotosDialogState extends State<ServicePhotosDialog> {
  late Future<List<ServicePhoto>> _photos;

  ServiceRecord get _service => widget.controller.services.firstWhere(
    (s) => s.operation == widget.operation,
  );

  @override
  void initState() {
    super.initState();
    _photos = widget.controller.photosFor(widget.operation);
  }

  void _reload() {
    setState(() => _photos = widget.controller.photosFor(widget.operation));
  }

  bool _canDelete(ServicePhoto photo) =>
      widget.isAdmin || photo.takenById == widget.currentUserId;

  Future<void> _addPhotos() async {
    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FinishServiceDialog(
        service: _service,
        finishing: false,
        picker: widget.picker,
        onFinish: (photos, onProgress) async {
          final total = photos.length;
          var done = 0;
          while (photos.isNotEmpty) {
            onProgress(done, total);
            final error = await widget.controller.uploadPhoto(
              widget.operation,
              photos.first,
            );
            if (error != null) return error;
            photos.removeAt(0);
            done++;
          }
          onProgress(done, total);
          return null;
        },
      ),
    );
    if (added == true && mounted) _reload();
  }

  Future<void> _open(ServicePhoto photo) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => _PhotoViewer(
        photo: photo,
        controller: widget.controller,
        canDelete: _canDelete(photo),
      ),
    );
    if (deleted == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    final full = service.photoCount >= PhotoKinds.maxPerService;

    return AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      title: Row(
        children: [
          PlateBadge(plate: service.plate, vehicleType: service.vehicleType),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fotos · servicio #${service.operation}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: FutureBuilder<List<ServicePhoto>>(
          future: _photos,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              );
            }

            final photos = snapshot.data!;
            if (photos.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(28),
                decoration: AppDecorations.inset(radius: 14),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 40,
                      color: AppColors.mutedText,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Este servicio no tiene fotos todavía.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 480 ? 4 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  itemCount: photos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return _GridPhoto(
                      photo: photo,
                      bytes: widget.controller.photoBytes(photo.id),
                      onTap: () => _open(photo),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondaryText),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          onPressed: full ? null : _addPhotos,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(full ? 'Máximo de fotos' : 'Agregar fotos'),
        ),
      ],
    );
  }
}

class _GridPhoto extends StatelessWidget {
  const _GridPhoto({
    required this.photo,
    required this.bytes,
    required this.onTap,
  });

  final ServicePhoto photo;
  final Future<Uint8List> bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isProblem =
        photo.kind == PhotoKinds.damage || photo.kind == PhotoKinds.missing;

    return Tooltip(
      message: photo.note.isEmpty ? photo.kind : '${photo.kind}: ${photo.note}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PhotoThumbnail(bytes: bytes, size: null),
            Positioned(
              left: 6,
              bottom: 6,
              right: 6,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (isProblem ? AppColors.danger : AppColors.background)
                        .withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    photo.kind,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto ampliada con sus datos y el botón de eliminar.
class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({
    required this.photo,
    required this.controller,
    required this.canDelete,
  });

  final ServicePhoto photo;
  final WorkshopController controller;
  final bool canDelete;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  bool _deleting = false;

  Future<void> _delete() async {
    final confirmed = await confirmAction(
      context,
      title: 'Eliminar foto',
      message:
          'La foto se eliminará del servicio. Esta acción no se puede '
          'deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    final error = await widget.controller.deletePhoto(widget.photo);
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 820),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: Container(
                color: Colors.black,
                child: InteractiveViewer(
                  maxScale: 5,
                  child: PhotoThumbnail(
                    bytes: widget.controller.photoBytes(photo.id),
                    size: null,
                    radius: 0,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.kind,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        if (photo.note.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(photo.note),
                        ],
                        const SizedBox(height: 3),
                        Text(
                          '${formatDate(photo.createdAt)}'
                          '${photo.takenBy.isEmpty ? '' : ' · ${photo.takenBy}'}',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.canDelete)
                    IconButton(
                      tooltip: 'Eliminar foto',
                      onPressed: _deleting ? null : _delete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                    ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
