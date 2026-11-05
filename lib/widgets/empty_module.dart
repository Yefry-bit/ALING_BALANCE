import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_decorations.dart';

/// Panel con icono y mensaje para secciones o listas vacías.
class EmptyModule extends StatelessWidget {
  const EmptyModule({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: AppDecorations.panel(radius: 18),
      child: Column(
        children: [
          Icon(icon, size: 52, color: AppColors.accent),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
