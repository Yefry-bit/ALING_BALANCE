import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/navigation/app_section.dart';
import '../core/theme/app_decorations.dart';
import 'icon_badge.dart';

/// Menú lateral para pantallas anchas (escritorio / web).
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.sections,
    required this.selected,
    required this.roleLabel,
    required this.onSelected,
    this.userName = '',
  });

  /// Secciones que el rol del usuario puede abrir.
  final List<AppSection> sections;
  final String roleLabel;
  final String userName;
  final AppSection selected;
  final ValueChanged<AppSection> onSelected;

  @override
  Widget build(BuildContext context) {
    // Material (y no un Container con color) para que los ListTile del menú
    // pinten su fondo y el efecto al tocarlos.
    return Material(
      color: AppColors.panel.withValues(alpha: 0.92),
      shape: const Border(right: BorderSide(color: AppColors.border)),
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 26, 16, 30),
              child: Row(
                children: [
                  IconBadge(
                    icon: Icons.tire_repair_rounded,
                    brand: true,
                    size: 42,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AlingBalance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Alineación y balanceo',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 16, 10),
              child: Text(
                'MENÚ PRINCIPAL',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 10.5,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final section in sections)
              _SidebarItem(
                section: section,
                selected: selected == section,
                onTap: () => onSelected(section),
              ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: AppDecorations.panel(radius: 14),
              child: Row(
                children: [
                  _Initials(name: userName),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (userName.isNotEmpty)
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        Text(
                          'Sesión: $roleLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.accent,
                    size: 18,
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

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final AppSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Stack(
        children: [
          ListTile(
            selected: selected,
            selectedTileColor: AppColors.accent.withValues(alpha: 0.12),
            hoverColor: Colors.white.withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Icon(
              section.icon,
              color: selected ? AppColors.accent : AppColors.secondaryText,
            ),
            title: Text(
              section.title,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.secondaryText,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            onTap: onTap,
          ),
          // Barra de acento a la izquierda del elemento activo.
          if (selected)
            Positioned(
              left: 0,
              top: 12,
              bottom: 12,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: AppDecorations.brandGradient,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Avatar con las iniciales del usuario sobre el degradado de la marca.
class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppDecorations.brandGradient,
      ),
      child: initials.isEmpty
          ? const Icon(Icons.person, size: 18, color: AppColors.background)
          : Text(
              initials,
              style: const TextStyle(
                color: AppColors.background,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
    );
  }
}
