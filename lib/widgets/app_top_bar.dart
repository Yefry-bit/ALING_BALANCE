import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/utils/formatters.dart';

/// Barra superior: saludo, sección actual, actualizar y cerrar sesión.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    required this.userName,
    required this.roleLabel,
    required this.onRefresh,
    required this.onLogout,
  });

  final String title;
  final String userName;
  final String roleLabel;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'Buenos días';
    if (now.hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstName = userName.trim().split(RegExp(r'\s+')).first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.75),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // En pantallas angostas (celular) solo caben el título y los
          // botones; el nombre queda en el tooltip del avatar.
          final wide = constraints.maxWidth >= 560;

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (wide)
                      Text(
                        '${_greeting(now)}, $firstName · '
                        '${formatDate(now)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (wide) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: AppDecorations.tinted(
                    AppColors.accent,
                    radius: 20,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.circle,
                        color: AppColors.accent,
                        size: 8,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        roleLabel,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Tooltip(
                message: '$userName · $roleLabel',
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppDecorations.brandGradient,
                  ),
                  child: const Icon(Icons.person, color: AppColors.background),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Actualizar datos',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          );
        },
      ),
    );
  }
}
