import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/photo_picker.dart';
import 'data/api_client.dart';
import 'data/session_store.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login/login_screen.dart';
import 'state/auth_controller.dart';
import 'widgets/app_background.dart';

/// Widget raíz: configura el tema y abre el panel si hay una sesión guardada
/// en el dispositivo; si no, el login.
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

  /// Recuperación de la sesión guardada; `null` si no hay dónde guardarla.
  Future<bool>? _restoring;

  @override
  void initState() {
    super.initState();
    _auth =
        widget.auth ??
        AuthController(ApiClient(), sessionStore: const SecureSessionStore());
    if (_auth.canRememberSession) _restoring = _auth.restoreSession();
  }

  @override
  void dispose() {
    if (widget.auth == null) _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restoring = _restoring;

    return MaterialApp(
      title: 'AlingBalance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: restoring == null
          ? _login()
          : FutureBuilder<bool>(
              future: restoring,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _OpeningScreen();
                }
                return snapshot.data == true
                    ? DashboardScreen(
                        auth: _auth,
                        photoPicker: widget.photoPicker,
                      )
                    : _login();
              },
            ),
    );
  }

  Widget _login() => LoginScreen(auth: _auth, photoPicker: widget.photoPicker);
}

/// Pantalla breve mientras se revisa la sesión guardada.
class _OpeningScreen extends StatelessWidget {
  const _OpeningScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppBackground(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
    );
  }
}
