import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/validators.dart';
import '../models/expense.dart';
import 'form_error_banner.dart';

/// Crear o editar un gasto fijo mensual (arriendo, nómina…).
/// Devuelve `true` si se guardó.
class RecurringExpenseFormDialog extends StatefulWidget {
  const RecurringExpenseFormDialog({
    super.key,
    required this.onSubmit,
    this.initial,
    this.today,
  });

  /// Gasto fijo a editar; `null` para crear uno nuevo.
  final RecurringExpense? initial;

  final Future<String?> Function(RecurringExpenseData data) onSubmit;

  /// Fecha actual (se puede fijar en pruebas).
  final DateTime? today;

  @override
  State<RecurringExpenseFormDialog> createState() =>
      _RecurringExpenseFormDialogState();
}

class _RecurringExpenseFormDialogState
    extends State<RecurringExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late final _amount = TextEditingController(
    text: widget.initial?.amount.toString() ?? '',
  );
  late String _category =
      ExpenseCategories.all.contains(widget.initial?.category)
      ? widget.initial!.category
      : ExpenseCategories.all.first;
  late int _day = widget.initial?.dayOfMonth ?? 1;
  late bool _active = widget.initial?.active ?? true;
  bool _includeCurrentMonth = true;

  bool _saving = false;
  String? _error;

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.onSubmit(
      RecurringExpenseData(
        description: Validators.normalizeText(_description.text),
        category: _category,
        amount: int.parse(_amount.text.trim()),
        dayOfMonth: _day,
        active: _active,
        includeCurrentMonth: _includeCurrentMonth,
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
    final today = widget.today ?? DateTime.now();
    final dayPassed = _day <= today.day;
    const small = TextStyle(color: AppColors.secondaryText, fontSize: 12);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        children: [
          const Icon(Icons.autorenew_rounded, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_editing ? 'Editar gasto fijo' : 'Nuevo gasto fijo'),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) FormErrorBanner(message: _error!),
                const Text(
                  'Se registra solo cada mes en el día indicado, así no '
                  'tienes que ingresarlo a mano.',
                  style: small,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej. Arriendo del local',
                    prefixIcon: Icon(Icons.notes),
                    counterText: '',
                  ),
                  validator: Validators.expenseDescription,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    for (final category in ExpenseCategories.all)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _category = value);
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Valor mensual (COP)',
                    hintText: 'Ej. 1500000',
                    prefixIcon: Icon(Icons.payments_outlined),
                    counterText: '',
                  ),
                  validator: Validators.expenseAmount,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _day,
                  isExpanded: true,
                  menuMaxHeight: 320,
                  decoration: const InputDecoration(
                    labelText: 'Día del mes',
                    prefixIcon: Icon(Icons.event_repeat_outlined),
                    helperText:
                        'Del 1 al 28, para que exista en todos los '
                        'meses.',
                  ),
                  items: [
                    for (var day = 1; day <= 28; day++)
                      DropdownMenuItem(value: day, child: Text('Día $day')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _day = value);
                        },
                ),
                const SizedBox(height: 6),
                if (_editing)
                  SwitchListTile(
                    value: _active,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _active = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activo'),
                    subtitle: Text(
                      _active
                          ? 'Se registra cada mes.'
                          : 'En pausa: no se registra hasta reanudarlo.',
                      style: small,
                    ),
                  )
                else if (dayPassed)
                  CheckboxListTile(
                    value: _includeCurrentMonth,
                    onChanged: _saving
                        ? null
                        : (value) =>
                              setState(() => _includeCurrentMonth = value!),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Registrar también el de este mes'),
                    subtitle: const Text(
                      'Desmárcalo si este mes ya lo registraste a mano.',
                      style: small,
                    ),
                  )
                else
                  Text(
                    'El primero se registrará el día $_day de este mes.',
                    style: small,
                  ),
                if (_editing)
                  const Text(
                    'Los cambios aplican a los próximos meses; los gastos ya '
                    'registrados se editan uno por uno.',
                    style: small,
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
                : _editing
                ? 'Guardar cambios'
                : 'Crear gasto fijo',
          ),
        ),
      ],
    );
  }
}
