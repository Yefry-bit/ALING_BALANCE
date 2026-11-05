import 'package:flutter/material.dart';

/// Muestra un mensaje corto en la parte inferior de la pantalla.
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
