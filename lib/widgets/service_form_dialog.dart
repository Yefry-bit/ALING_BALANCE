import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/service_catalog.dart';
import '../core/constants/vehicle_catalog.dart';
import '../core/utils/client_notifier.dart';
import '../core/utils/upper_case_formatter.dart';
import '../core/utils/validators.dart';
import '../models/client.dart';
import '../models/employee.dart';
import '../models/new_service_data.dart';
import '../models/service_status.dart';
import 'form_error_banner.dart';
import 'catalog_field.dart';

/// Diálogo para registrar un servicio nuevo.
///
/// Valida cada campo antes de enviar. Al guardar llama a [onSubmit]; si el
/// servidor rechaza los datos, el diálogo sigue abierto mostrando el motivo,
/// así no se pierde lo que se escribió. Devuelve `true` si se guardó.
class ServiceFormDialog extends StatefulWidget {
  const ServiceFormDialog({
    super.key,
    required this.canEditPrice,
    required this.employees,
    required this.onSubmit,
    this.vehicleForPlate,
    this.clientForPlate,
    this.initialVehicle,
  });

  /// Vehículo con el que se abre el formulario (desde la ficha del cliente):
  /// llena placa, marca, modelo y tipo.
  final Vehicle? initialVehicle;

  /// Busca un vehículo registrado por placa para autocompletar sus datos.
  final Vehicle? Function(String plate)? vehicleForPlate;

  /// Cliente dueño de la placa (para mostrarlo en el formulario).
  final Client? Function(String plate)? clientForPlate;

  /// Si es `false`, el precio es fijo (el del catálogo) y no se puede editar.
  final bool canEditPrice;

  /// Empleados activos entre los que se elige quién realiza el trabajo.
  final List<Employee> employees;

  /// Envía el servicio al servidor. Devuelve un mensaje de error o `null`.
  final Future<String?> Function(NewServiceData data) onSubmit;

  @override
  State<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _priceController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  String _vehicleType = 'Particular';
  String _selectedService = 'Alineación sencilla';
  ServiceStatus _status = ServiceStatus.inProgress;
  int? _employeeId;

  bool _saving = false;
  String? _error;

  /// Cliente al que pertenece la placa escrita (si está registrada).
  Client? _owner;

  /// Si ya se escribió el contacto a mano, no se vuelve a autocompletar.
  bool _contactTouched = false;

  @override
  void initState() {
    super.initState();
    _updateSuggestedPrice();

    final vehicle = widget.initialVehicle;
    if (vehicle != null) {
      _plateController.text = vehicle.plate;
      _brandController.text = vehicle.brand;
      _modelController.text = vehicle.model;
      if (ServiceCatalog.vehicleTypes.contains(vehicle.vehicleType)) {
        _vehicleType = vehicle.vehicleType;
        _updateSuggestedPrice();
      }
      _owner = widget.clientForPlate?.call(vehicle.plate);
      _prefillContact(_owner);
    }
  }

  /// Sugiere como contacto al dueño de la placa (si tiene celular con
  /// WhatsApp), salvo que ya se haya escrito otro a mano.
  void _prefillContact(Client? owner) {
    if (_contactTouched) return;

    _contactNameController.text = owner?.name ?? '';
    _contactPhoneController.text =
        owner != null && whatsappNumber(owner.phone) != null
        ? Validators.normalizePhone(owner.phone)
        : '';
  }

  /// Si la placa pertenece a un vehículo registrado, completa marca, modelo
  /// y tipo con sus datos.
  void _onPlateChanged(String value) {
    final plate = Validators.normalizePlate(value);
    final vehicle = widget.vehicleForPlate?.call(plate);
    final owner = widget.clientForPlate?.call(plate);

    setState(() {
      _owner = owner;
      _prefillContact(owner);
      if (vehicle == null) return;

      _brandController.text = vehicle.brand;
      _modelController.text = vehicle.model;
      if (ServiceCatalog.vehicleTypes.contains(vehicle.vehicleType)) {
        _vehicleType = vehicle.vehicleType;
        _updateSuggestedPrice();
      }
    });
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _priceController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _updateSuggestedPrice() {
    final price = ServiceCatalog.suggestedPrice(_selectedService, _vehicleType);
    _priceController.text = price.toString();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.onSubmit(
      NewServiceData(
        plate: Validators.normalizePlate(_plateController.text),
        // Misma escritura siempre: "chevrolet" → "Chevrolet", "cx5" → "CX-5".
        brand: VehicleCatalog.canonicalBrand(_brandController.text),
        model: VehicleCatalog.canonicalModel(
          _brandController.text,
          _modelController.text,
        ),
        vehicleType: _vehicleType,
        serviceType: _selectedService,
        status: _status,
        price: int.parse(_priceController.text.trim()),
        employeeId: _employeeId,
        contactName: Validators.normalizeText(_contactNameController.text),
        contactPhone: Validators.normalizePhone(_contactPhoneController.text),
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
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Row(
        children: [
          Icon(Icons.car_repair_rounded, color: AppColors.accent),
          SizedBox(width: 10),
          Expanded(
            child: Text('Registrar servicio', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) FormErrorBanner(message: _error!),
                _buildOperationBadge(),
                const SizedBox(height: 20),
                _fieldLabel('Placa del vehículo'),
                TextFormField(
                  controller: _plateController,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  inputFormatters: plateInputFormatters,
                  onChanged: _onPlateChanged,
                  decoration: const InputDecoration(
                    hintText: 'Ej. ABC-123',
                    prefixIcon: Icon(Icons.pin_outlined),
                    counterText: '',
                  ),
                  validator: Validators.plate,
                ),
                if (_owner != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_pin_outlined,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Vehículo de ${_owner!.name} · datos completados',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _fieldLabel('Marca'),
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
                    hintText: 'Escribe o elige: Chevrolet, Renault, Mazda…',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                  validator: (value) =>
                      Validators.vehicleText(value, 'La marca'),
                ),
                const SizedBox(height: 16),
                _fieldLabel('Modelo'),
                CatalogField(
                  controller: _modelController,
                  enabled: !_saving,
                  maxLength: 30,
                  options: VehicleCatalog.modelsFor(_brandController.text),
                  otherLabel: 'Otro modelo',
                  pickerTitle: 'Elige el modelo',
                  customHint: 'Escribe el modelo',
                  decoration: const InputDecoration(
                    hintText: 'Escribe o elige el modelo',
                    prefixIcon: Icon(Icons.car_rental_outlined),
                  ),
                  validator: (value) =>
                      Validators.vehicleText(value, 'El modelo'),
                ),
                const SizedBox(height: 16),
                _fieldLabel('Tipo de vehículo'),
                DropdownButtonFormField<String>(
                  initialValue: _vehicleType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    for (final type in ServiceCatalog.vehicleTypes)
                      DropdownMenuItem(value: type, child: Text(type)),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _vehicleType = value;
                            _updateSuggestedPrice();
                          });
                        },
                ),
                const SizedBox(height: 16),
                _fieldLabel('Servicio que se realizará'),
                DropdownButtonFormField<String>(
                  initialValue: _selectedService,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.build_outlined),
                  ),
                  items: [
                    for (final service in ServiceCatalog.serviceTypes)
                      DropdownMenuItem(value: service, child: Text(service)),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedService = value;
                            _updateSuggestedPrice();
                          });
                        },
                ),
                const SizedBox(height: 16),
                _fieldLabel('Empleado que realiza el servicio'),
                if (widget.employees.isEmpty)
                  const Text(
                    'No hay empleados activos: el servicio quedará sin '
                    'asignar y no generará comisión.',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue: _employeeId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Selecciona un empleado',
                      prefixIcon: Icon(Icons.engineering_outlined),
                    ),
                    items: [
                      for (final employee in widget.employees)
                        DropdownMenuItem(
                          value: employee.id,
                          child: Text(employee.name),
                        ),
                    ],
                    validator: (value) => value == null
                        ? 'Selecciona el empleado que realiza el trabajo.'
                        : null,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _employeeId = value),
                  ),
                const SizedBox(height: 16),
                _fieldLabel('Cliente (se le avisa por WhatsApp)'),
                TextFormField(
                  controller: _contactNameController,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 80,
                  onChanged: (_) => _contactTouched = true,
                  decoration: const InputDecoration(
                    hintText: 'Nombre del cliente',
                    prefixIcon: Icon(Icons.person_outline),
                    counterText: '',
                  ),
                  validator: (value) => Validators.personName(
                    value,
                    label: 'El nombre del cliente',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactPhoneController,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  maxLength: 16,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
                  ],
                  onChanged: (_) => _contactTouched = true,
                  decoration: const InputDecoration(
                    hintText: 'Celular. Ej. 300 123 4567',
                    prefixIcon: Icon(Icons.smartphone_outlined),
                    counterText: '',
                    helperText:
                        'Al terminar el servicio se abre WhatsApp con el aviso '
                        'listo para enviarle.',
                    helperMaxLines: 2,
                  ),
                  validator: Validators.mobilePhone,
                ),
                const SizedBox(height: 16),
                _fieldLabel('Precio del servicio (COP)'),
                TextFormField(
                  controller: _priceController,
                  enabled: !_saving,
                  readOnly: !widget.canEditPrice,
                  keyboardType: TextInputType.number,
                  maxLength: 7,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Ej. 20000',
                    counterText: '',
                    prefixIcon: Icon(
                      widget.canEditPrice
                          ? Icons.payments_outlined
                          : Icons.lock_outline,
                    ),
                    helperText: widget.canEditPrice
                        ? 'Precio sugerido editable.'
                        : 'Precio fijo según el catálogo.',
                  ),
                  validator: Validators.price,
                ),
                const SizedBox(height: 16),
                _fieldLabel('Estado inicial'),
                DropdownButtonFormField<ServiceStatus>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.pending_actions_outlined),
                  ),
                  items: [
                    for (final status in ServiceStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _status = value);
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
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Guardando…' : 'Guardar servicio'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
          ),
        ),
      ],
    );
  }

  Widget _buildOperationBadge() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.confirmation_number_outlined, color: AppColors.accent),
          SizedBox(width: 10),
          Expanded(child: Text('Número de operación')),
          Text(
            'Automático',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
