import 'package:flutter/material.dart';

import '../core/constants/service_catalog.dart';
import '../core/constants/vehicle_catalog.dart';
import '../core/utils/upper_case_formatter.dart';
import '../core/utils/validators.dart';
import '../models/client.dart';
import 'form_error_banner.dart';
import 'catalog_field.dart';

/// Diálogo para agregar un vehículo a un cliente. Devuelve `true` si se
/// guardó.
class VehicleFormDialog extends StatefulWidget {
  const VehicleFormDialog({
    super.key,
    required this.clientName,
    required this.plateOwner,
    required this.onSubmit,
  });

  final String clientName;

  /// Nombre del cliente que ya tiene la placa registrada, o `null`.
  final String? Function(String plate) plateOwner;

  /// Envía el vehículo al servidor. Devuelve un mensaje de error o `null`.
  final Future<String?> Function(NewVehicleData data) onSubmit;

  @override
  State<VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  String _vehicleType = ServiceCatalog.vehicleTypes.first;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.onSubmit(
      NewVehicleData(
        plate: Validators.normalizePlate(_plateController.text),
        // Misma escritura siempre: "chevrolet" → "Chevrolet", "cx5" → "CX-5".
        brand: VehicleCatalog.canonicalBrand(_brandController.text),
        model: VehicleCatalog.canonicalModel(
          _brandController.text,
          _modelController.text,
        ),
        vehicleType: _vehicleType,
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
      title: Text('Agregar vehículo a ${widget.clientName}'),
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
                  controller: _plateController,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  inputFormatters: plateInputFormatters,
                  decoration: const InputDecoration(
                    labelText: 'Placa',
                    hintText: 'Ej. ABC-123',
                    prefixIcon: Icon(Icons.pin_outlined),
                    counterText: '',
                  ),
                  validator: (value) {
                    final basic = Validators.plate(value);
                    if (basic != null) return basic;
                    final owner = widget.plateOwner(
                      Validators.normalizePlate(value),
                    );
                    if (owner != null) {
                      return 'Esta placa ya está registrada a nombre de $owner.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CatalogField(
                  controller: _brandController,
                  enabled: !_saving,
                  maxLength: 30,
                  options: VehicleCatalog.brands,
                  otherLabel: 'Otra marca',
                  pickerTitle: 'Elige la marca',
                  customHint: 'Escribe la marca',
                  // Al cambiar de marca, el modelo anterior ya no aplica.
                  onSelected: (_) => setState(_modelController.clear),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    hintText: 'Escribe o elige: Chevrolet, Renault, Mazda…',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                  validator: (value) =>
                      Validators.vehicleText(value, 'La marca'),
                ),
                const SizedBox(height: 12),
                CatalogField(
                  controller: _modelController,
                  enabled: !_saving,
                  maxLength: 30,
                  options: VehicleCatalog.modelsFor(_brandController.text),
                  otherLabel: 'Otro modelo',
                  pickerTitle: 'Elige el modelo',
                  customHint: 'Escribe el modelo',
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    hintText: 'Escribe o elige el modelo',
                    prefixIcon: Icon(Icons.car_rental_outlined),
                  ),
                  validator: (value) =>
                      Validators.vehicleText(value, 'El modelo'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _vehicleType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de vehículo',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    for (final type in ServiceCatalog.vehicleTypes)
                      DropdownMenuItem(value: type, child: Text(type)),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _vehicleType = value);
                          }
                        },
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
          child: Text(_saving ? 'Guardando…' : 'Agregar vehículo'),
        ),
      ],
    );
  }
}
