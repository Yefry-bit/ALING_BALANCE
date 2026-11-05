import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../core/theme/app_decorations.dart';

/// Tarjeta con los datos de una cuenta de usuario.
class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    required this.isCurrentUser,
    required this.onToggleActive,
  });

  final AppUser user;

  /// `true` si es la cuenta con la que se inició sesión.
  final bool isCurrentUser;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == UserRole.admin;
    final roleColor = isAdmin ? AppColors.violet : AppColors.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.panel(radius: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withValues(alpha: 0.15),
            child: Icon(
              isAdmin
                  ? Icons.admin_panel_settings_outlined
                  : Icons.badge_outlined,
              color: roleColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? '${user.name} (tú)' : user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _Tag(label: user.role.label, color: roleColor),
                    _Tag(
                      label: user.active ? 'Activo' : 'Inactivo',
                      color: user.active
                          ? AppColors.accent
                          : Colors.orangeAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isCurrentUser
                ? 'No puedes desactivar tu propia cuenta'
                : (user.active ? 'Desactivar usuario' : 'Activar usuario'),
            onPressed: isCurrentUser ? null : onToggleActive,
            icon: Icon(
              user.active ? Icons.person_off_outlined : Icons.person_add_alt_1,
              color: user.active ? Colors.orangeAccent : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
