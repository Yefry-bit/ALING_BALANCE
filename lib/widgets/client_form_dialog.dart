import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/validators.dart';
import '../models/client.dart';
import 'form_error_banner.dart';

/// Diálogo para registrar un cliente nuevo o editar uno existente.
///
/// Devuelve `true` si se guardó. Si el servidor rechaza los datos, el
/// diálogo sigue abierto mostrando el motivo.
class ClientFormDialog extends StatefulWidget {
  const ClientFormDialog({
    super.key,
    required this.documentExists,
    required this.onSubmit,
    this.initial,
  });

  /// Cliente a editar; `null` para registrar uno nuevo.
  final Client? initial;

  /// Indica si otro cliente ya tiene esa identificación.
  final bool Function(String document) documentExists;

  /// Envía los datos al servidor. Devuelve un mensaje de error o `null`.
  final Future<String?> Function(ClientData data) onSubmit;

  @override
  State<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initial?.name,
  );
  late final _documentController = TextEditingController(
    text: widget.initial?.document,
  );
  late final _phoneController = TextEditingController(
    text: widget.initial?.phone,
  );

  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.initial != null;

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
      ClientData(
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(_isEditing ? 'Editar cliente' : 'Registrar cliente'),
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
                      return 'Ya existe un cliente con esa identificación.';
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
          child: Text(
            _saving
                ? 'Guardando…'
                : (_isEditing ? 'Guardar cambios' : 'Guardar cliente'),
          ),
        ),
      ],
    );
  }
}
