import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'icon_badge.dart';

/// Título grande y descripción que abren cada sección.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.description,
    this.icon,
  });

  final String title;
  final String description;

  /// Icono de la sección (opcional) en una insignia con el degradado.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          if (icon != null) ...[
            IconBadge(icon: icon!, brand: true, size: 52),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
