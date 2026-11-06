import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/photo_picker.dart';
import '../../core/utils/snackbar.dart';
import '../../core/utils/validators.dart';
import '../../state/auth_controller.dart';
import '../../widgets/app_background.dart';
import '../../widgets/icon_badge.dart';
import '../dashboard/dashboard_screen.dart';
import '../../core/theme/app_decorations.dart';

/// Pantalla de inicio de sesión: valida los datos y los comprueba en el
/// servidor.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.auth,
    this.photoPicker = const PhotoPicker(),
  });

  final PhotoPicker photoPicker;

  final AuthController auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _signingIn = false;

  /// "Mantener la sesión iniciada" (marcado por defecto).
  bool _remember = true;

  @override
  void initState() {
    super.initState();

    // Si se llegó aquí porque la sesión expiró, se avisa una sola vez.
    final notice = widget.auth.takeSessionNotice();
    if (notice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showMessage(context, notice);
      });
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enterApp() async {
    if (_signingIn || !_formKey.currentState!.validate()) return;

    setState(() => _signingIn = true);
    final error = await widget.auth.login(
      _userController.text,
      _passwordController.text,
      remember: _remember,
    );
    if (!mounted) return;

    if (error != null) {
      setState(() => _signingIn = false);
      showMessage(context, error);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DashboardScreen(auth: widget.auth, photoPicker: widget.photoPicker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 980 : 430),
                  child: wide
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Expanded(child: _BrandPanel()),
                              const SizedBox(width: 24),
                              SizedBox(width: 430, child: _buildForm()),
                            ],
                          ),
                        )
                      : _buildForm(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: AppDecorations.panel(radius: 26),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: IconBadge(
                icon: Icons.tire_repair_rounded,
                brand: true,
                size: 68,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'AlingBalance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Gestión inteligente para tu taller',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 30),
            const Text(
              'Usuario',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _userController,
              enabled: !_signingIn,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Ingresa tu usuario',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) =>
                  Validators.required(value, 'Ingresa tu usuario.'),
            ),
            const SizedBox(height: 18),
            const Text(
              'Contraseña',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              enabled: !_signingIn,
              obscureText: _hidePassword,
              onFieldSubmitted: (_) => _enterApp(),
              decoration: InputDecoration(
                hintText: 'Ingresa tu contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _hidePassword = !_hidePassword);
                  },
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Ingresa tu contraseña.'
                  : null,
            ),
            if (widget.auth.canRememberSession) ...[
              const SizedBox(height: 8),
              // Fila simple (no ListTile): mide bien su alto dentro del
              // IntrinsicHeight de la pantalla ancha.
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _signingIn
                    ? null
                    : () => setState(() => _remember = !_remember),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _remember,
                        onChanged: _signingIn
                            ? null
                            : (value) =>
                                  setState(() => _remember = value ?? true),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mantener la sesión iniciada'),
                              SizedBox(height: 2),
                              Text(
                                'No pedirá la contraseña en este dispositivo '
                                'durante 30 días. Desmárcalo en equipos '
                                'compartidos.',
                                style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ] else
              const SizedBox(height: 26),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppDecorations.brandGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _signingIn ? null : _enterApp,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _signingIn
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Si no tienes usuario, solicítalo al administrador.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel de presentación (solo en pantallas anchas).
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  static const _features = [
    (
      Icons.car_repair_rounded,
      'Servicios',
      'Registra cada vehículo y su estado',
    ),
    (
      Icons.photo_camera_outlined,
      'Evidencia',
      'Fotos del carro, las máquinas y las fallas',
    ),
    (Icons.people_alt_outlined, 'Clientes', 'Varios vehículos por cliente'),
    (Icons.insights_rounded, 'Finanzas', 'Gastos y ganancias de cada mes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              AppColors.accent.withValues(alpha: 0.18),
              AppColors.panelHigh,
            ),
            Color.alphaBlend(
              AppColors.accentBlue.withValues(alpha: 0.12),
              AppColors.panel,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Tu taller de alineación\ny balanceo, en orden.',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Servicios, empleados, clientes y contabilidad en un solo lugar, '
            'compartidos entre todos los dispositivos.',
            style: TextStyle(color: AppColors.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 30),
          for (final (icon, title, detail) in _features)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  IconBadge(icon: icon, size: 42),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          detail,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
