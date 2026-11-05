import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/photo_picker.dart';
import 'data/api_client.dart';
import 'screens/login/login_screen.dart';
import 'state/auth_controller.dart';

/// Widget raíz: configura el tema y muestra el login.
class AlingBalanceApp extends StatefulWidget {
  const AlingBalanceApp({
    super.key,
    this.auth,
    this.photoPicker = const PhotoPicker(),
  });

  /// Cámara / galería (se puede reemplazar en pruebas).
  final PhotoPicker photoPicker;

  /// Permite inyectar un controlador de sesión (útil en pruebas).
  final AuthController? auth;

  @override
  State<AlingBalanceApp> createState() => _AlingBalanceAppState();
}

class _AlingBalanceAppState extends State<AlingBalanceApp> {
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ?? AuthController(ApiClient());
  }

  @override
  void dispose() {
    if (widget.auth == null) _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlingBalance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: LoginScreen(auth: _auth, photoPicker: widget.photoPicker),
    );
  }
}
