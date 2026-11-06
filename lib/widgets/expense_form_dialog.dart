import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/formatters.dart';
import '../core/utils/validators.dart';
import '../models/expense.dart';
import 'form_error_banner.dart';

/// Diálogo para registrar un gasto o corregir uno ya registrado ([initial]).
/// Devuelve `true` si se guardó.
class ExpenseFormDialog extends StatefulWidget {
  const ExpenseFormDialog({
    super.key,
    required this.onSubmit,
    this.initialDate,
    this.initial,
  });

  /// Fecha propuesta (por ejemplo, un día del mes que se está viendo).
  final DateTime? initialDate;

  /// Gasto a editar; `null` para registrar uno nuevo.
  final Expense? initial;

  /// Envía el gasto al servidor. Devuelve un mensaje de error o `null`.
  final Future<String?> Function(NewExpenseData data) onSubmit;

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = ExpenseCategories.all.first;
  late DateTime _date;

  bool _saving = false;
  String? _error;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    final expense = widget.initial;

    if (expense != null) {
      _descriptionController.text = expense.description;
      _amountController.text = expense.amount.toString();
      if (ExpenseCategories.all.contains(expense.category)) {
        _category = expense.category;
      }
      _date = expense.date.isAfter(today) ? today : expense.date;
      return;
    }

    final initial = widget.initialDate;
    _date = initial == null || initial.isAfter(today)
        ? today
        : DateUtils.dateOnly(initial);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Fecha del gasto',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.onSubmit(
      NewExpenseData(
        description: Validators.normalizeText(_descriptionController.text),
        category: _category,
        amount: int.parse(_amountController.text.trim()),
        date: _date,
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
      title: Text(_editing ? 'Editar gasto' : 'Registrar gasto'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) FormErrorBanner(message: _error!),
                if (widget.initial?.isRecurring ?? false)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.autorenew_rounded,
                          size: 16,
                          color: AppColors.info,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lo registró un gasto fijo. El cambio aplica solo '
                            'a este mes.',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _descriptionController,
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
                  controller: _amountController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Valor (COP)',
                    hintText: 'Ej. 150000',
                    prefixIcon: Icon(Icons.payments_outlined),
                    counterText: '',
                  ),
                  validator: Validators.expenseAmount,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _saving ? null : _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.event),
                    ),
                    child: Text(formatDate(_date)),
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
          child: Text(
            _saving
                ? 'Guardando…'
                : _editing
                ? 'Guardar cambios'
                : 'Guardar gasto',
          ),
        ),
      ],
    );
  }
}
