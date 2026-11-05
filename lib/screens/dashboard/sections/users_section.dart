import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_section.dart';
import '../../../models/app_user.dart';
import '../../../state/auth_controller.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/user_card.dart';

/// Sección "Usuarios" (solo administradores): lista de cuentas y alta de nuevas.
class UsersSection extends StatelessWidget {
  const UsersSection({
    super.key,
    required this.auth,
    required this.onNewUser,
    required this.onToggleActive,
  });

  final AuthController auth;
  final VoidCallback onNewUser;
  final ValueChanged<AppUser> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final users = auth.users;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: AppSection.usuarios.icon,
          title: AppSection.usuarios.title,
          description: AppSection.usuarios.description,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '${users.length} usuarios registrados',
                style: const TextStyle(color: AppColors.secondaryText),
              ),
            ),
            FilledButton.icon(
              onPressed: onNewUser,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nuevo usuario'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (final user in users)
          UserCard(
            user: user,
            isCurrentUser: user.id == auth.currentUser?.id,
            onToggleActive: () => onToggleActive(user),
          ),
      ],
    );
  }
}
