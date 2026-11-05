import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/validators.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import 'form_error_banner.dart';

/// Diálogo para crear un usuario nuevo.
///
/// Valida los datos antes de enviar y muestra el error del servidor sin
/// cerrarse. Devuelve `true` si el usuario se creó.
class UserFormDialog extends StatefulWidget {
  const UserFormDialog({
    super.key,
    required this.usernameExists,
    required this.onSubmit,
  });

  /// Indica si ya existe una cuenta con ese nombre de usuario.
  final bool Function(String username) usernameExists;

  /// Envía el usuario al servidor. Devuelve un mensaje de error o `null`.
  final Future<String?> Function(NewUserData data) onSubmit;

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  UserRole _role = UserRole.employee;
  bool _hidePassword = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.onSubmit(
      NewUserData(
        name: Validators.normalizeText(_nameController.text),
        username: Validators.normalizeUsername(_usernameController.text),
        password: _passwordController.text,
        role: _role,
      ),
    );

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
      title: const Row(
        children: [
          Icon(Icons.manage_accounts_rounded, color: AppColors.accent),
          SizedBox(width: 10),
          Expanded(child: Text('Crear usuario')),
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
                TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
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
                TextFormField(
                  controller: _usernameController,
                  enabled: !_saving,
                  autocorrect: false,
                  maxLength: 20,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9._]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    prefixIcon: Icon(Icons.alternate_email),
                    counterText: '',
                  ),
                  validator: (value) {
                    final basic = Validators.username(value);
                    if (basic != null) return basic;
                    if (widget.usernameExists(value!)) {
                      return 'Ese nombre de usuario ya está en uso.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_saving,
                  obscureText: _hidePassword,
                  maxLength: Validators.maxPasswordLength,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    helperText: 'Mínimo 8 caracteres, con letras y números.',
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _hidePassword = !_hidePassword);
                      },
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  enabled: !_saving,
                  obscureText: _hidePassword,
                  maxLength: Validators.maxPasswordLength,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
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
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _role = value);
                        },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _role == UserRole.admin
                        ? 'Acceso total: usuarios, empleados, contabilidad y '
                              'precios.'
                        : 'Puede registrar servicios con precio fijo y '
                              'cambiar su estado.',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
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
          child: Text(_saving ? 'Guardando…' : 'Crear usuario'),
        ),
      ],
    );
  }
}
