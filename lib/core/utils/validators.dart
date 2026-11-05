/// Validaciones y normalización de datos de los formularios.
///
/// Son las mismas reglas que aplica el servidor
/// (backend/AlingBalance.Api/Validation/Rules.cs): validar aquí da respuesta
/// inmediata al usuario y el servidor vuelve a validar por seguridad.
///
/// Cada validador devuelve el mensaje de error o `null` si el dato es válido,
/// así que se puede usar directamente en `TextFormField.validator`.
abstract final class Validators {
  static const int maxPrice = 5000000;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;

  static final RegExp _personName = RegExp(
    r"^[\p{L}][\p{L}\p{M}'. -]*$",
    unicode: true,
  );
  static final RegExp _vehicleText = RegExp(
    r'^[\p{L}\p{N}][\p{L}\p{N}\p{M} .\-/+]*$',
    unicode: true,
  );
  static final RegExp _plate = RegExp(r'^[A-Z]{3}-\d{3}$');
  static final RegExp _plateWithoutHyphen = RegExp(r'^[A-Z]{3}\d{3}$');
  static final RegExp _username = RegExp(r'^[a-z0-9._]+$');
  static final RegExp _document = RegExp(r'^\d{5,12}$');
  static final RegExp _phone = RegExp(r'^(\d{7}|3\d{9}|60\d{8})$');

  // ------------------------------------------------------------ Normalizar

  /// Quita espacios al inicio y al final, y junta los espacios repetidos.
  static String normalizeText(String? value) {
    return (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// "abc123" o "ABC 123" se convierten en "ABC-123".
  static String normalizePlate(String? value) {
    var plate = (value ?? '').trim().toUpperCase().replaceAll(' ', '');
    if (_plateWithoutHyphen.hasMatch(plate)) {
      plate = '${plate.substring(0, 3)}-${plate.substring(3)}';
    }
    return plate;
  }

  static String normalizeUsername(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  /// Deja solo los dígitos y quita el indicativo +57.
  static String normalizePhone(String? value) {
    var phone = (value ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
    if (phone.startsWith('+57')) phone = phone.substring(3);
    return phone;
  }

  // -------------------------------------------------------------- Validar

  static String? required(String? value, String message) {
    return (value == null || value.trim().isEmpty) ? message : null;
  }

  static String? personName(String? value, {String label = 'El nombre'}) {
    final name = normalizeText(value);

    if (name.isEmpty) return 'Ingresa ${label.toLowerCase()}.';
    if (name.length < 3) return '$label debe tener al menos 3 caracteres.';
    if (name.length > 80) return '$label no puede superar los 80 caracteres.';
    if (!_personName.hasMatch(name)) {
      return '$label solo puede tener letras, espacios, puntos, '
          'apóstrofes y guiones.';
    }
    return null;
  }

  static String? document(String? value) {
    final document = (value ?? '').trim();

    if (document.isEmpty) return 'Ingresa el número de identificación.';
    if (!_document.hasMatch(document)) {
      return 'La identificación debe tener solo números '
          '(entre 5 y 12 dígitos).';
    }
    return null;
  }

  /// El teléfono es opcional; si se escribe debe ser válido.
  static String? phone(String? value) {
    final phone = normalizePhone(value);

    if (phone.isEmpty) return null;
    if (!_phone.hasMatch(phone)) {
      return 'El teléfono debe tener 7 dígitos (fijo) o 10 dígitos (celular).';
    }
    return null;
  }

  static String? plate(String? value) {
    final plate = normalizePlate(value);

    if (plate.isEmpty) return 'Ingresa la placa del vehículo.';
    if (!_plate.hasMatch(plate)) {
      return 'La placa debe tener el formato ABC-123.';
    }
    return null;
  }

  /// Marca o modelo del vehículo.
  static String? vehicleText(String? value, String label) {
    final text = normalizeText(value);

    if (text.isEmpty) return 'Ingresa ${label.toLowerCase()}.';
    if (text.length < 2) return '$label debe tener al menos 2 caracteres.';
    if (text.length > 30) return '$label no puede superar los 30 caracteres.';
    if (!_vehicleText.hasMatch(text)) {
      return '$label contiene caracteres no permitidos.';
    }
    return null;
  }

  static String? username(String? value) {
    final username = normalizeUsername(value);

    if (username.isEmpty) return 'Ingresa el nombre de usuario.';
    if (username.length < 4) {
      return 'El usuario debe tener al menos 4 caracteres.';
    }
    if (username.length > 20) {
      return 'El usuario no puede superar los 20 caracteres.';
    }
    if (!_username.hasMatch(username)) {
      return 'El usuario solo puede tener letras, números, punto y guion bajo.';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';

    if (password.isEmpty) return 'Ingresa la contraseña.';
    if (password.length < minPasswordLength) {
      return 'La contraseña debe tener al menos $minPasswordLength caracteres.';
    }
    if (password.length > maxPasswordLength) {
      return 'La contraseña no puede superar los $maxPasswordLength caracteres.';
    }
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(password)) {
      return 'La contraseña debe incluir al menos una letra.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'La contraseña debe incluir al menos un número.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirma la contraseña.';
    if (value != original) return 'Las contraseñas no coinciden.';
    return null;
  }

  /// Precio en pesos: solo números enteros, mayor a cero y con un máximo.
  static String? price(String? value) {
    final price = int.tryParse((value ?? '').trim());

    if (price == null) return 'Ingresa un precio válido.';
    if (price <= 0) return 'El precio debe ser mayor a cero.';
    if (price > maxPrice) return r'El precio no puede superar $5.000.000.';
    return null;
  }

  // ---------------------------------------------------------------- Gastos

  static const int maxExpense = 50000000;

  static String? expenseDescription(String? value) {
    final text = normalizeText(value);

    if (text.isEmpty) return 'Ingresa la descripción del gasto.';
    if (text.length < 3) {
      return 'La descripción debe tener al menos 3 caracteres.';
    }
    if (text.length > 80) {
      return 'La descripción no puede superar los 80 caracteres.';
    }
    return null;
  }

  static String? expenseAmount(String? value) {
    final amount = int.tryParse((value ?? '').trim());

    if (amount == null) return 'Ingresa el valor del gasto.';
    if (amount <= 0) return 'El valor debe ser mayor a cero.';
    if (amount > maxExpense) return r'El valor no puede superar $50.000.000.';
    return null;
  }
}
