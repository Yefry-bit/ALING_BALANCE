import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_section.dart';
import '../../core/reports/monthly_report.dart';
import '../../core/reports/report_excel.dart';
import '../../core/reports/report_pdf.dart';
import '../../core/reports/report_saver.dart';
import '../../core/utils/client_notifier.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/photo_picker.dart';
import '../../core/utils/snackbar.dart';
import '../../data/workshop_repository.dart';
import '../../models/app_user.dart';
import '../../models/client.dart';
import '../../models/commission_payment.dart';
import '../../models/employee.dart';
import '../../models/expense.dart';
import '../../models/service_record.dart';
import '../../models/service_status.dart';
import '../../state/auth_controller.dart';
import '../../state/workshop_controller.dart';
import '../../widgets/account_dialogs.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/assign_employee_dialog.dart';
import '../../widgets/client_form_dialog.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/employee_form_dialog.dart';
import '../../widgets/expense_form_dialog.dart';
import '../../widgets/finish_service_dialog.dart';
import '../../widgets/recurring_expense_form_dialog.dart';
import '../../widgets/service_actions.dart';
import '../../widgets/service_form_dialog.dart';
import '../../widgets/service_photos_dialog.dart';
import '../../widgets/user_form_dialog.dart';
import '../../widgets/vehicle_form_dialog.dart';
import '../login/login_screen.dart';
import 'sections/accounting_section.dart';
import 'sections/clients_section.dart';
import 'sections/employees_section.dart';
import 'sections/overview_section.dart';
import 'sections/services_section.dart';
import 'sections/users_section.dart';

/// Panel principal: arma el menú, la barra superior y la sección activa.
///
/// Muestra solo las secciones que el rol del usuario puede abrir. Esta
/// pantalla solo coordina; los datos viven en los controladores y cada
/// sección se dibuja en su propio archivo dentro de `sections/`.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.auth,
    this.controller,
    this.photoPicker = const PhotoPicker(),
    this.reportSaver = const ReportSaver(),
    this.messageLauncher = const MessageLauncher(),
  });

  /// Abre WhatsApp / SMS para avisar al cliente (se reemplaza en pruebas).
  final MessageLauncher messageLauncher;

  /// Cámara / galería (se puede reemplazar en pruebas).
  final PhotoPicker photoPicker;

  /// Guarda los informes exportados (se puede reemplazar en pruebas).
  final ReportSaver reportSaver;

  /// Controlador de sesión con el usuario ya autenticado.
  final AuthController auth;

  /// Permite inyectar un controlador del taller (útil en pruebas). Si es
  /// `null`, la pantalla crea y administra el suyo.
  final WorkshopController? controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _desktopBreakpoint = 850;

  late final WorkshopController _controller;
  late final bool _ownsController;
  AppSection _section = AppSection.inicio;
  bool _leaving = false;

  AppUser get _user => widget.auth.currentUser!;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        WorkshopController(
          repository: WorkshopRepository(widget.auth.api),
          includeFinances: _user.role.canViewFinances,
        );

    if (_ownsController) _controller.load();
    if (_user.role.canManageUsers) widget.auth.loadUsers();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- Acciones

  void _goTo(AppSection section) {
    // Defensa extra: un rol no puede abrir secciones que no le corresponden.
    if (!_user.role.canAccess(section)) return;
    setState(() => _section = section);
  }

  Future<void> _refresh() async {
    final error = await _controller.refresh();
    if (_user.role.canManageUsers) await widget.auth.loadUsers();

    if (!mounted) return;
    showMessage(context, error ?? 'Datos actualizados.');
  }

  /// Registra un servicio. Desde la ficha de un cliente llega [vehicle] y
  /// el formulario se abre con sus datos; en ese caso no se cambia de
  /// sección para seguir viendo al cliente.
  Future<void> _newService({Vehicle? vehicle}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ServiceFormDialog(
        canEditPrice: _user.role.canEditPrices,
        employees: _controller.employees.where((e) => e.active).toList(),
        vehicleForPlate: _controller.vehicleForPlate,
        clientForPlate: _controller.clientForPlate,
        initialVehicle: vehicle,
        onSubmit: _controller.addService,
      ),
    );

    if (saved != true || !mounted) return;

    if (vehicle == null) _goTo(AppSection.servicios);
    final operation = _controller.services.first.operation;
    showMessage(context, 'Servicio #$operation guardado correctamente.');
  }

  /// "Finalizar" abre el formulario de fotos de evidencia; "Reabrir" pide
  /// confirmación porque descuenta la comisión.
  Future<void> _toggleServiceStatus(ServiceRecord service) async {
    if (service.status == ServiceStatus.inProgress) {
      await _finishService(service);
      return;
    }

    final confirmed = await confirmAction(
      context,
      title: 'Reabrir servicio',
      message:
          'El servicio #${service.operation} volverá a "En proceso" y '
          'su comisión se descontará hasta que se termine de nuevo.',
      confirmLabel: 'Reabrir',
    );
    if (!confirmed || !mounted) return;

    final error = await _controller.toggleServiceStatus(service.operation);

    if (!mounted) return;
    showMessage(
      context,
      error ?? 'Servicio #${service.operation} reabierto: quedó En proceso.',
    );
  }

  Future<void> _finishService(ServiceRecord service) async {
    var uploaded = 0;

    final finished = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FinishServiceDialog(
        service: service,
        picker: widget.photoPicker,
        onFinish: (photos, onProgress) => _controller.finishService(
          service.operation,
          photos,
          onProgress: (done, total) {
            uploaded = done;
            onProgress(done, total);
          },
        ),
      ),
    );

    if (finished != true || !mounted) return;
    final text = uploaded == 0
        ? 'Servicio #${service.operation} terminado.'
        : 'Servicio #${service.operation} terminado con $uploaded foto(s).';

    showMessage(context, text);

    // Si hay a quién avisar (el contacto del servicio o el dueño de la placa),
    // WhatsApp se abre solo con el mensaje listo: solo falta tocar Enviar.
    if (!_canNotifyClient(service)) return;

    final opened = await _openWhatsApp(service);
    if (opened || !mounted) return;

    // No se pudo abrir (por ejemplo, el navegador bloqueó la ventana): queda
    // el botón para intentarlo de nuevo.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Avisar por WhatsApp',
            onPressed: () => _notifyClient(service),
          ),
        ),
      );
  }

  // ------------------------------------------------------- Avisar al cliente

  /// Celular (con indicativo) al que se avisa, si tiene WhatsApp: primero el
  /// contacto que se dio al registrar el servicio y, si no hay, el del dueño
  /// de la placa.
  String? _clientNumber(ServiceRecord service) {
    final own = whatsappNumber(service.contactPhone);
    if (own != null) return own;

    final client = _controller.clientForPlate(service.plate);
    return client == null ? null : whatsappNumber(client.phone);
  }

  /// Nombre de la persona a la que se avisa (puede ser vacío).
  String _clientName(ServiceRecord service) {
    final owner = _controller.clientForPlate(service.plate)?.name ?? '';
    if (whatsappNumber(service.contactPhone) == null) return owner;

    final own = service.contactName.trim();
    return own.isNotEmpty ? own : owner;
  }

  bool _canNotifyClient(ServiceRecord service) =>
      _clientNumber(service) != null;

  /// Abre WhatsApp directo con el aviso de "vehículo listo" ya escrito.
  /// Devuelve `false` si no hay celular o no se pudo abrir.
  Future<bool> _openWhatsApp(ServiceRecord service) {
    final number = _clientNumber(service);
    if (number == null) return Future.value(false);

    final message = readyMessage(
      clientName: _clientName(service),
      service: service,
    );
    return widget.messageLauncher.open(whatsappUri(number, message));
  }

  /// Abre WhatsApp (o SMS en el celular) con el aviso de "vehículo listo"
  /// ya escrito; el empleado solo toca Enviar.
  Future<void> _notifyClient(ServiceRecord service) async {
    final number = _clientNumber(service);
    if (number == null) {
      showMessage(
        context,
        'El servicio #${service.operation} no tiene un celular de contacto '
        'ni un cliente con celular registrado. Agrégalo en Clientes.',
      );
      return;
    }

    final name = _clientName(service);
    final message = readyMessage(clientName: name, service: service);
    var uri = whatsappUri(number, message);

    if (canSendSms) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.chat, color: AppColors.whatsapp),
                title: const Text('WhatsApp'),
                subtitle: Text(
                  name.isEmpty ? 'Avisar al cliente' : 'Avisar a $name',
                ),
                onTap: () => Navigator.pop(context, 'whatsapp'),
              ),
              ListTile(
                leading: const Icon(Icons.sms_outlined),
                title: const Text('Mensaje de texto (SMS)'),
                onTap: () => Navigator.pop(context, 'sms'),
              ),
            ],
          ),
        ),
      );
      if (choice == null || !mounted) return;
      if (choice == 'sms') uri = smsUri(number, plainText(message));
    }

    final opened = await widget.messageLauncher.open(uri);
    if (!opened && mounted) {
      showMessage(context, 'No se pudo abrir WhatsApp en este dispositivo.');
    }
  }

  Future<void> _openPhotos(ServiceRecord service) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ServicePhotosDialog(
        operation: service.operation,
        controller: _controller,
        currentUserId: _user.id,
        isAdmin: _user.role.canDeleteClients,
        picker: widget.photoPicker,
      ),
    );
  }

  Future<void> _newEmployee() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmployeeFormDialog(
        documentExists: _controller.documentExists,
        onSubmit: _controller.addEmployee,
      ),
    );

    if (saved != true || !mounted) return;
    showMessage(context, 'Empleado registrado correctamente.');
  }

  Future<void> _toggleEmployeeActive(Employee employee) async {
    if (employee.active) {
      final confirmed = await confirmAction(
        context,
        title: 'Desactivar empleado',
        message: '${employee.name} ya no podrá asignarse a nuevos servicios.',
        confirmLabel: 'Desactivar',
      );
      if (!confirmed || !mounted) return;
    }

    final error = await _controller.toggleEmployeeActive(employee.id);

    if (!mounted) return;
    showMessage(context, error ?? 'Empleado actualizado.');
  }

  // ---------------------------------------------------------------- Clientes

  Future<void> _newClient() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClientFormDialog(
        documentExists: (doc) => _controller.clientDocumentExists(doc),
        onSubmit: _controller.addClient,
      ),
    );

    if (saved != true || !mounted) return;
    showMessage(
      context,
      'Cliente registrado. Ábrelo para agregar sus vehículos.',
    );
  }

  Future<void> _editClient(Client client) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClientFormDialog(
        initial: client,
        documentExists: (doc) =>
            _controller.clientDocumentExists(doc, exceptId: client.id),
        onSubmit: (data) => _controller.updateClient(client.id, data),
      ),
    );

    if (saved != true || !mounted) return;
    showMessage(context, 'Cliente actualizado.');
  }

  Future<void> _deleteClient(Client client) async {
    final confirmed = await confirmAction(
      context,
      title: 'Eliminar cliente',
      message:
          'Se eliminarán ${client.name} y sus '
          '${client.vehicles.length} vehículo(s). Los servicios ya '
          'realizados se conservan en el historial y en la contabilidad.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !mounted) return;

    final error = await _controller.deleteClient(client.id);
    if (!mounted) return;
    showMessage(context, error ?? 'Cliente eliminado.');
  }

  Future<void> _addVehicle(Client client) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VehicleFormDialog(
        clientName: client.name,
        plateOwner: (plate) => _controller.clientForPlate(plate)?.name,
        onSubmit: (data) => _controller.addVehicle(client.id, data),
      ),
    );

    if (saved != true || !mounted) return;
    showMessage(context, 'Vehículo agregado a ${client.name}.');
  }

  Future<void> _removeVehicle(Client client, Vehicle vehicle) async {
    final confirmed = await confirmAction(
      context,
      title: 'Quitar vehículo',
      message:
          'La placa ${vehicle.plate} dejará de estar asociada a '
          '${client.name}. Sus servicios se conservan.',
      confirmLabel: 'Quitar',
    );
    if (!confirmed || !mounted) return;

    final error = await _controller.removeVehicle(client.id, vehicle.id);
    if (!mounted) return;
    showMessage(context, error ?? 'Vehículo ${vehicle.plate} quitado.');
  }

  // ------------------------------------------------------------------ Gastos

  Future<void> _newExpense(DateTime initialDate) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExpenseFormDialog(
        initialDate: initialDate,
        onSubmit: _controller.addExpense,
      ),
    );

    if (saved != true || !mounted) return;
    showMessage(context, 'Gasto registrado.');
  }

  Future<void> _editExpense(Expense expense) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExpenseFormDialog(
        initial: expense,
        onSubmit: (data) => _controller.updateExpense(expense.id, data),
      ),
    );

    if (saved != true || !mounted) return;
    showMessage(context, 'Gasto actualizado.');
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await confirmAction(
      context,
      title: 'Eliminar gasto',
      message:
          '¿Eliminar "${expense.description}" por '
          '${formatMoney(expense.amount)}?',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !mounted) return;

    final error = await _controller.deleteExpense(expense.id);
    if (!mounted) return;
    showMessage(context, error ?? 'Gasto eliminado.');
  }

  // ------------------------------------------------------------ Gastos fijos

  Future<void> _newRecurring() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          RecurringExpenseFormDialog(onSubmit: _controller.addRecurringExpense),
    );

    if (saved != true || !mounted) return;
    showMessage(context, 'Gasto fijo creado. Se registrará solo cada mes.');
  }

  Future<void> _editRecurring(RecurringExpense item) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecurringExpenseFormDialog(
        initial: item,
        onSubmit: (data) => _controller.updateRecurringExpense(item.id, data),
      ),
    );

    if (saved != true || !mounted) return;
    showMessage(context, 'Gasto fijo actualizado.');
  }

  Future<void> _toggleRecurring(RecurringExpense item) async {
    final error = await _controller.toggleRecurringExpense(item);
    if (!mounted) return;
    showMessage(
      context,
      error ??
          (item.active
              ? '"${item.description}" quedó en pausa.'
              : '"${item.description}" se volverá a registrar cada mes.'),
    );
  }

  Future<void> _deleteRecurring(RecurringExpense item) async {
    final confirmed = await confirmAction(
      context,
      title: 'Eliminar gasto fijo',
      message:
          '"${item.description}" dejará de registrarse cada mes. Los gastos '
          'que ya se registraron se conservan.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !mounted) return;

    final error = await _controller.deleteRecurringExpense(item.id);
    if (!mounted) return;
    showMessage(context, error ?? 'Gasto fijo eliminado.');
  }

  // -------------------------------------------------------------- Comisiones

  Future<void> _payCommissions(
    MonthlyCommission item,
    int year,
    int month,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: 'Pagar comisiones',
      message:
          '¿Registrar el pago de ${formatMoney(item.pendingAmount)} a '
          '${item.employeeName} por ${item.pendingOperations.length} '
          'servicio(s) de ${formatMonth(year, month)}?',
      confirmLabel: 'Registrar pago',
    );
    if (!confirmed || !mounted) return;

    final error = await _controller.payCommissions(
      item.employeeId,
      year,
      month,
    );
    if (!mounted) return;
    showMessage(
      context,
      error ?? 'Pago registrado: ${formatMoney(item.pendingAmount)}.',
    );
  }

  Future<void> _undoPayment(CommissionPayment payment) async {
    final confirmed = await confirmAction(
      context,
      title: 'Deshacer pago',
      message:
          'El pago de ${formatMoney(payment.amount)} a ${payment.employeeName} '
          'se eliminará y sus servicios volverán a quedar pendientes.',
      confirmLabel: 'Deshacer pago',
    );
    if (!confirmed || !mounted) return;

    final error = await _controller.undoCommissionPayment(payment.id);
    if (!mounted) return;
    showMessage(context, error ?? 'Pago deshecho.');
  }

  /// Cambia el empleado de un servicio (solo administradores).
  Future<void> _changeEmployee(ServiceRecord service) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AssignEmployeeDialog(
        service: service,
        employees: _controller.employees.where((e) => e.active).toList(),
        commission: _controller.commissionFor(service),
        onSubmit: (employeeId) =>
            _controller.assignEmployee(service.operation, employeeId),
      ),
    );

    if (saved != true || !mounted) return;
    showMessage(
      context,
      'Empleado del servicio #${service.operation} actualizado.',
    );
  }

  // ---------------------------------------------------------------- Informes

  Future<void> _export(int year, int month, ReportFormat format) async {
    final report = MonthlyReport.fromController(_controller, year, month);

    try {
      final bytes = switch (format) {
        ReportFormat.pdf => await buildMonthlyReportPdf(report),
        ReportFormat.excel => buildMonthlyReportExcel(report),
      };
      final saved = await widget.reportSaver.save(
        name: report.fileName,
        bytes: bytes,
        format: format,
      );
      if (!mounted || !saved) return;
      showMessage(
        context,
        'Resumen de ${report.monthName} exportado en ${format.label}.',
      );
    } catch (_) {
      if (!mounted) return;
      showMessage(
        context,
        'No se pudo exportar el resumen. Inténtalo de nuevo.',
      );
    }
  }

  // ---------------------------------------------------------------- Usuarios

  Future<void> _changePassword() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ChangePasswordDialog(onSubmit: widget.auth.changePassword),
    );

    if (saved != true || !mounted) return;
    showMessage(context, 'Contraseña actualizada.');
  }

  Future<void> _editUser(AppUser user) async {
    final isSelf = user.id == widget.auth.currentUser?.id;
    final lastAdmin = widget.auth.isLastActiveAdmin(user);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditUserDialog(
        user: user,
        canChangeRole: !isSelf && !lastAdmin,
        roleLockedReason: isSelf
            ? 'No puedes cambiar tu propio rol.'
            : 'Es el único administrador activo: debe quedar al menos uno.',
        onSubmit: (name, role) => widget.auth.updateUser(user.id, name, role),
      ),
    );

    if (saved != true || !mounted) return;
    showMessage(context, 'Usuario actualizado.');
  }

  Future<void> _resetPassword(AppUser user) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ResetPasswordDialog(
        user: user,
        onSubmit: (password) => widget.auth.resetPassword(user.id, password),
      ),
    );

    if (saved != true || !mounted) return;
    showMessage(context, 'Contraseña de ${user.name} actualizada.');
  }

  // ---------------------------------------------------------------- Usuarios

  Future<void> _newUser() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserFormDialog(
        usernameExists: widget.auth.usernameExists,
        onSubmit: widget.auth.createUser,
      ),
    );

    if (saved != true || !mounted) return;
    showMessage(context, 'Usuario creado correctamente.');
  }

  Future<void> _toggleUserActive(AppUser user) async {
    if (user.active) {
      final confirmed = await confirmAction(
        context,
        title: 'Desactivar usuario',
        message:
            '${user.name} no podrá iniciar sesión hasta que se vuelva '
            'a activar su cuenta.',
        confirmLabel: 'Desactivar',
      );
      if (!confirmed || !mounted) return;
    }

    final error = await widget.auth.toggleUserActive(user.id);

    if (!mounted) return;
    showMessage(context, error ?? 'Cuenta de ${user.name} actualizada.');
  }

  void _logout() {
    // Al cerrar la sesión, el build detecta que no hay usuario y abre el login.
    widget.auth.logout();
  }

  /// Abre el login una sola vez cuando la sesión termina (cierre manual o
  /// sesión expirada).
  void _goToLogin() {
    if (_leaving) return;
    _leaving = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              LoginScreen(auth: widget.auth, photoPicker: widget.photoPicker),
        ),
      );
    });
  }

  // ------------------------------------------------------------------ Vistas

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, widget.auth]),
      builder: (context, _) {
        final user = widget.auth.currentUser;

        if (user == null) {
          _goToLogin();
          return const Scaffold();
        }

        if (_controller.isLoading) {
          return const Scaffold(
            body: AppBackground(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          );
        }

        final sections = user.role.sections;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= _desktopBreakpoint;

            return Scaffold(
              bottomNavigationBar: isDesktop
                  ? null
                  : _buildNavigationBar(sections),
              body: AppBackground(
                child: Row(
                  children: [
                    if (isDesktop)
                      AppSidebar(
                        sections: sections,
                        selected: _section,
                        roleLabel: user.role.label,
                        userName: user.name,
                        onSelected: _goTo,
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          AppTopBar(
                            title: _section.title,
                            userName: user.name,
                            roleLabel: user.role.label,
                            onRefresh: _refresh,
                            onLogout: _logout,
                            onChangePassword: _changePassword,
                          ),
                          Expanded(
                            child: ServiceActions(
                              onChangeEmployee: user.role.canManageEmployees
                                  ? _changeEmployee
                                  : null,
                              onNotifyClient: _notifyClient,
                              canNotifyClient: _canNotifyClient,
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(isDesktop ? 30 : 18),
                                child: _buildSection(user, isDesktop),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavigationBar(List<AppSection> sections) {
    final selectedIndex = sections.indexOf(_section);

    return NavigationBar(
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) => _goTo(sections[index]),
      destinations: [
        for (final section in sections)
          NavigationDestination(icon: Icon(section.icon), label: section.title),
      ],
    );
  }

  Widget _buildSection(AppUser user, bool isDesktop) {
    switch (_section) {
      case AppSection.inicio:
        return OverviewSection(
          controller: _controller,
          role: user.role,
          isDesktop: isDesktop,
          onNewService: _newService,
          onNavigate: _goTo,
          onToggleStatus: _toggleServiceStatus,
          onPhotos: _openPhotos,
        );
      case AppSection.servicios:
        return ServicesSection(
          controller: _controller,
          onNewService: _newService,
          onToggleStatus: _toggleServiceStatus,
          onPhotos: _openPhotos,
        );
      case AppSection.clientes:
        return ClientsSection(
          controller: _controller,
          role: user.role,
          onNewClient: _newClient,
          onEditClient: _editClient,
          onDeleteClient: _deleteClient,
          onAddVehicle: _addVehicle,
          onRemoveVehicle: _removeVehicle,
          onNewService: (vehicle) => _newService(vehicle: vehicle),
          onToggleStatus: _toggleServiceStatus,
          onPhotos: _openPhotos,
        );
      case AppSection.empleados:
        return EmployeesSection(
          controller: _controller,
          onNewEmployee: _newEmployee,
          onToggleActive: _toggleEmployeeActive,
        );
      case AppSection.contabilidad:
        return AccountingSection(
          controller: _controller,
          isDesktop: isDesktop,
          onNewExpense: _newExpense,
          onDeleteExpense: _deleteExpense,
          onEditExpense: _editExpense,
          onNewRecurring: _newRecurring,
          onEditRecurring: _editRecurring,
          onToggleRecurring: _toggleRecurring,
          onDeleteRecurring: _deleteRecurring,
          onPayCommissions: _payCommissions,
          onUndoPayment: _undoPayment,
          onExport: _export,
        );
      case AppSection.usuarios:
        return UsersSection(
          auth: widget.auth,
          onNewUser: _newUser,
          onToggleActive: _toggleUserActive,
          onEdit: _editUser,
          onResetPassword: _resetPassword,
        );
    }
  }
}
