import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Miniatura de una foto: muestra los bytes en cuanto llegan, con un
/// indicador mientras se descarga y un icono si falla.
class PhotoThumbnail extends StatelessWidget {
  const PhotoThumbnail({
    super.key,
    required this.bytes,
    this.size = 72,
    this.radius = 12,
    this.fit = BoxFit.cover,
  });

  final Future<Uint8List> bytes;
  final double? size;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: AppColors.background,
        child: FutureBuilder<Uint8List>(
          future: bytes,
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data != null && data.isNotEmpty) {
              return Image.memory(
                data,
                fit: fit,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const _Placeholder(broken: true),
              );
            }
            if (snapshot.hasError || data != null) {
              return const _Placeholder(broken: true);
            }
            return const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.broken});

  final bool broken;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        broken ? Icons.broken_image_outlined : Icons.image_outlined,
        color: AppColors.mutedText,
      ),
    );
  }
}
