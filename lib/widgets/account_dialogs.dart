import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/validators.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import 'form_error_banner.dart';

/// Estructura común de los diálogos de cuenta: título con icono, banner de
/// error del servidor, botones "Cancelar" / acción y estado "Guardando…".
/// Devuelve `true` al cerrarse si se guardó.
class _AccountDialog extends StatefulWidget {
  const _AccountDialog({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.fields,
    required this.onSave,
  });

  final IconData icon;
  final String title;
  final String actionLabel;

  /// Campos del formulario; reciben si se está guardando.
  final List<Widget> Function(bool saving) fields;

  /// Guarda y devuelve el error, o `null` si salió bien.
  final Future<String?> Function() onSave;

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.onSave();
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.panel,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        children: [
          Icon(widget.icon, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) FormErrorBanner(message: _error!),
                ...widget.fields(_saving),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando…' : widget.actionLabel),
        ),
      ],
    );
  }
}

/// Campo de contraseña con botón para mostrarla.
class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.validator,
    this.helperText,
    this.icon = Icons.lock_outline,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final FormFieldValidator<String> validator;
  final String? helperText;
  final IconData icon;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _hidden,
      maxLength: Validators.maxPasswordLength,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        counterText: '',
        prefixIcon: Icon(widget.icon),
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Mostrar' : 'Ocultar',
          onPressed: () => setState(() => _hidden = !_hidden),
          icon: Icon(
            _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: widget.validator,
    );
  }
}

const _passwordHelp = 'Mínimo 8 caracteres, con letras y números.';

/// Cambiar la contraseña propia (pide la actual).
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, required this.onSubmit});

  /// Recibe la contraseña actual y la nueva; devuelve el error o `null`.
  final Future<String?> Function(String current, String newPassword) onSubmit;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AccountDialog(
      icon: Icons.password_rounded,
      title: 'Cambiar contraseña',
      actionLabel: 'Cambiar contraseña',
      onSave: () => widget.onSubmit(_current.text, _password.text),
      fields: (saving) => [
        _PasswordField(
          controller: _current,
          label: 'Contraseña actual',
          enabled: !saving,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Ingresa tu contraseña actual.'
              : null,
        ),
        const SizedBox(height: 12),
        _PasswordField(
          controller: _password,
          label: 'Contraseña nueva',
          helperText: _passwordHelp,
          icon: Icons.lock_reset,
          enabled: !saving,
          validator: (value) {
            final basic = Validators.password(value);
            if (basic != null) return basic;
            if (value == _current.text) {
              return 'La contraseña nueva debe ser diferente a la actual.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _PasswordField(
          controller: _confirm,
          label: 'Confirmar contraseña nueva',
          icon: Icons.lock_reset,
          enabled: !saving,
          validator: (value) =>
              Validators.confirmPassword(value, _password.text),
        ),
        const SizedBox(height: 12),
        const Text(
          'Por seguridad se cerrará tu sesión en los demás dispositivos.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
        ),
      ],
    );
  }
}

/// El administrador edita el nombre y el rol de una cuenta.
class EditUserDialog extends StatefulWidget {
  const EditUserDialog({
    super.key,
    required this.user,
    required this.canChangeRole,
    required this.onSubmit,
    this.roleLockedReason,
  });

  final AppUser user;

  /// `false` para la cuenta propia o el último administrador activo.
  final bool canChangeRole;

  /// Por qué no se puede cambiar el rol (se muestra debajo).
  final String? roleLockedReason;

  final Future<String?> Function(String name, UserRole role) onSubmit;

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final _name = TextEditingController(text: widget.user.name);
  late UserRole _role = widget.user.role;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleChanged = _role != widget.user.role;

    return _AccountDialog(
      icon: Icons.manage_accounts_rounded,
      title: 'Editar usuario',
      actionLabel: 'Guardar cambios',
      onSave: () =>
          widget.onSubmit(Validators.normalizeText(_name.text), _role),
      fields: (saving) => [
        TextFormField(
          initialValue: '@${widget.user.username}',
          enabled: false,
          decoration: const InputDecoration(
            labelText: 'Usuario (no se puede cambiar)',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _name,
          enabled: !saving,
          textCapitalization: TextCapitalization.words,
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            prefixIcon: Icon(Icons.person),
            counterText: '',
          ),
          validator: Validators.personName,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<UserRole>(
          initialValue: _role,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Rol',
            prefixIcon: Icon(Icons.admin_panel_settings_outlined),
          ),
          items: [
            for (final role in UserRole.values)
              DropdownMenuItem(value: role, child: Text(role.label)),
          ],
          onChanged: saving || !widget.canChangeRole
              ? null
              : (value) {
                  if (value != null) setState(() => _role = value);
                },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            !widget.canChangeRole
                ? widget.roleLockedReason ?? 'El rol no se puede cambiar.'
                : roleChanged
                ? 'Al cambiar el rol se cerrará la sesión de '
                      '${widget.user.name} para que entre con los permisos '
                      'nuevos.'
                : _role == UserRole.admin
                ? 'Acceso total: usuarios, empleados, contabilidad y precios.'
                : 'Puede registrar servicios con precio fijo y cambiar su '
                      'estado.',
            style: TextStyle(
              color: roleChanged ? AppColors.warning : AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// El administrador asigna una contraseña nueva a otra cuenta.
class ResetPasswordDialog extends StatefulWidget {
  const ResetPasswordDialog({
    super.key,
    required this.user,
    required this.onSubmit,
  });

  final AppUser user;
  final Future<String?> Function(String password) onSubmit;

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AccountDialog(
      icon: Icons.lock_reset_rounded,
      title: 'Nueva contraseña',
      actionLabel: 'Asignar contraseña',
      onSave: () => widget.onSubmit(_password.text),
      fields: (saving) => [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Para ${widget.user.name} (@${widget.user.username}).',
            style: const TextStyle(color: AppColors.secondaryText),
          ),
        ),
        const SizedBox(height: 14),
        _PasswordField(
          controller: _password,
          label: 'Contraseña nueva',
          helperText: _passwordHelp,
          enabled: !saving,
          validator: Validators.password,
        ),
        const SizedBox(height: 12),
        _PasswordField(
          controller: _confirm,
          label: 'Confirmar contraseña',
          icon: Icons.lock_reset,
          enabled: !saving,
          validator: (value) =>
              Validators.confirmPassword(value, _password.text),
        ),
        const SizedBox(height: 12),
        const Text(
          'Su sesión se cerrará en todos los dispositivos. Entrégale la '
          'contraseña en persona; podrá cambiarla después.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
        ),
      ],
    );
  }
}
