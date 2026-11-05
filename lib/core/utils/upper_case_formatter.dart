import 'package:flutter/services.dart';

/// Convierte lo que se escribe a mayúsculas (para la placa).
class UpperCaseFormatter extends TextInputFormatter {
  const UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

/// Filtros del campo placa: letras, números, guion y espacio, en mayúsculas.
final List<TextInputFormatter> plateInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\- ]')),
  const UpperCaseFormatter(),
];
