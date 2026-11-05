import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/validators.dart';
import '../models/new_employee_data.dart';
import 'form_error_banner.dart';

/// Diálogo para registrar un empleado nuevo.
///
/// Valida los datos antes de enviar y muestra el error del servidor sin
/// cerrarse. Devuelve `true` si el empleado se guardó.
class EmployeeFormDialog extends StatefulWidget {
  const EmployeeFormDialog({
    super.key,
    required this.documentExists,
    required this.onSubmit,
  });

  /// Indica si ya hay un empleado con esa identificación.
  final bool Function(String document) documentExists;

  /// Envía el empleado al servidor. Devuelve un mensaje de error o `null`.
  final Future<String?> Function(NewEmployeeData data) onSubmit;

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.onSubmit(
      NewEmployeeData(
        name: Validators.normalizeText(_nameController.text),
        document: _documentController.text.trim(),
        phone: Validators.normalizePhone(_phoneController.text),
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
      title: const Text('Registrar empleado'),
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
                  controller: _documentController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Número de identificación',
                    prefixIcon: Icon(Icons.badge),
                    counterText: '',
                  ),
                  validator: (value) {
                    final basic = Validators.document(value);
                    if (basic != null) return basic;
                    if (widget.documentExists(value!)) {
                      return 'Ya existe un empleado con esa identificación.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  maxLength: 16,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    prefixIcon: Icon(Icons.phone),
                    counterText: '',
                  ),
                  validator: Validators.phone,
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
          child: Text(_saving ? 'Guardando…' : 'Guardar empleado'),
        ),
      ],
    );
  }
}
