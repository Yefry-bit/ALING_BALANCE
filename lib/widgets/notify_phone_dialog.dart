import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/client_notifier.dart';
import '../models/service_record.dart';
import 'plate_badge.dart';

/// Datos que se escriben para avisar a un cliente sin celular registrado.
class NotifyContact {
  const NotifyContact({
    required this.phone,
    required this.name,
    required this.saveToClient,
  });

  /// Celular de 10 dígitos (sin indicativo).
  final String phone;
  final String name;

  /// Guardar el celular en la ficha del cliente.
  final bool saveToClient;
}

/// Pide el celular (y el nombre) para avisar que el vehículo está listo
/// cuando la placa no tiene un cliente con celular registrado.
class NotifyPhoneDialog extends StatefulWidget {
  const NotifyPhoneDialog({super.key, required this.service, this.clientName});

  final ServiceRecord service;

  /// Cliente dueño de la placa, si está registrado (sin celular).
  final String? clientName;

  @override
  State<NotifyPhoneDialog> createState() => _NotifyPhoneDialogState();
}

class _NotifyPhoneDialogState extends State<NotifyPhoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  late final _name = TextEditingController(text: widget.clientName ?? '');
  bool _save = true;

  bool get _hasClient => widget.clientName != null;

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      NotifyContact(
        phone: _phone.text.trim(),
        name: _name.text.trim(),
        saveToClient: _hasClient && _save,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(color: AppColors.secondaryText, fontSize: 12);

    return AlertDialog(
      backgroundColor: AppColors.panel,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Row(
        children: [
          Icon(Icons.chat_outlined, color: AppColors.whatsapp),
          SizedBox(width: 10),
          Expanded(child: Text('Avisar al cliente')),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PlateBadge(
                      plate: widget.service.plate,
                      vehicleType: widget.service.vehicleType,
                      small: true,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.service.vehicle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _hasClient
                      ? '${widget.clientName} no tiene celular registrado. '
                            'Escríbelo para enviarle el aviso.'
                      : 'Este vehículo no está registrado a un cliente. '
                            'Escribe el celular de quien lo trajo.',
                  style: small,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Celular (WhatsApp)',
                    hintText: 'Ej. 3001234567',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                    counterText: '',
                  ),
                  validator: (value) => whatsappNumber(value ?? '') == null
                      ? 'Escribe un celular de 10 dígitos que empiece por 3.'
                      : null,
                  onFieldSubmitted: (_) => _send(),
                ),
                if (!_hasClient) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Nombre (opcional)',
                      hintText: 'Para saludarlo por su nombre',
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '',
                    ),
                  ),
                ],
                if (_hasClient)
                  CheckboxListTile(
                    value: _save,
                    onChanged: (value) => setState(() => _save = value!),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Guardar el celular en su ficha'),
                    subtitle: const Text(
                      'Así la próxima vez el aviso sale con un toque.',
                      style: small,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _send,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.whatsapp,
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text('Enviar aviso'),
        ),
      ],
    );
  }
}
