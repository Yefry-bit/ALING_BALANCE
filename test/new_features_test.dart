import 'dart:typed_data';

import 'package:aling_balance/app.dart';
import 'package:aling_balance/core/reports/monthly_report.dart';
import 'package:aling_balance/core/reports/report_excel.dart';
import 'package:aling_balance/core/reports/report_pdf.dart';
import 'package:aling_balance/core/reports/report_saver.dart';
import 'package:aling_balance/core/theme/app_theme.dart';
import 'package:aling_balance/data/api_client.dart';
import 'package:aling_balance/data/session_store.dart';
import 'package:aling_balance/data/workshop_repository.dart';
import 'package:aling_balance/models/app_user.dart';
import 'package:aling_balance/models/expense.dart';
import 'package:aling_balance/models/user_role.dart';
import 'package:aling_balance/screens/dashboard/dashboard_screen.dart';
import 'package:aling_balance/state/auth_controller.dart';
import 'package:aling_balance/state/workshop_controller.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

ApiClient _api(FakeApi fake) =>
    ApiClient(httpClient: fake.client, baseUrl: 'http://test');

/// Guarda los informes en memoria en vez de abrir "Guardar como".
class _MemorySaver extends ReportSaver {
  final saved = <(String, ReportFormat, Uint8List)>[];

  @override
  Future<bool> save({
    required String name,
    required Uint8List bytes,
    required ReportFormat format,
  }) async {
    saved.add((name, format, bytes));
    return true;
  }
}

void _wideScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 1100);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  // ------------------------------------------------------------------ Sesión

  group('sesión guardada', () {
    test('al recordar la sesión no se pide la contraseña otra vez', () async {
      final fake = FakeApi();
      final store = MemorySessionStore();

      final first = AuthController(_api(fake), sessionStore: store);
      expect(await first.login('admin', 'admin123', remember: true), isNull);
      expect(fake.lastRememberMe, isTrue);
      expect(store.session, isNotNull);

      // La app se vuelve a abrir.
      final second = AuthController(_api(fake), sessionStore: store);
      expect(await second.restoreSession(), isTrue);
      expect(second.currentUser?.username, 'admin');
      expect(second.api.token, isNotNull);

      second.logout();
      expect(store.session, isNull);
    });

    test('sin "mantener la sesión" no se guarda nada', () async {
      final fake = FakeApi();
      final store = MemorySessionStore();
      final auth = AuthController(_api(fake), sessionStore: store);

      await auth.login('admin', 'admin123', remember: false);

      expect(store.session, isNull);
      expect(fake.lastRememberMe, isFalse);
    });

    test('una sesión rechazada por el servidor se borra', () async {
      final fake = FakeApi();
      final store = MemorySessionStore();
      await AuthController(
        _api(fake),
        sessionStore: store,
      ).login('admin', 'admin123', remember: true);

      fake.rejectTokens = true;
      final auth = AuthController(_api(fake), sessionStore: store);

      expect(await auth.restoreSession(), isFalse);
      expect(auth.currentUser, isNull);
      expect(store.session, isNull);
    });

    test('una sesión vencida no se usa', () async {
      final fake = FakeApi();
      final store = MemorySessionStore(
        StoredSession(
          token: fake.tokenFor(1),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          user: const AppUser(
            id: 1,
            name: 'Administrador',
            username: 'admin',
            role: UserRole.admin,
          ),
        ),
      );
      final auth = AuthController(_api(fake), sessionStore: store);

      expect(await auth.restoreSession(), isFalse);
      expect(store.session, isNull);
      expect(fake.requests, isEmpty);
    });

    test('sin conexión se entra con los datos guardados', () async {
      final fake = FakeApi();
      final store = MemorySessionStore();
      await AuthController(
        _api(fake),
        sessionStore: store,
      ).login('admin', 'admin123', remember: true);

      fake.offline = true;
      final auth = AuthController(_api(fake), sessionStore: store);

      expect(await auth.restoreSession(), isTrue);
      expect(auth.currentUser?.name, 'Administrador');
    });

    testWidgets('con sesión guardada la app abre directo el panel', (
      tester,
    ) async {
      _wideScreen(tester);
      final fake = FakeApi();
      final store = MemorySessionStore();
      await tester.runAsync(
        () => AuthController(
          _api(fake),
          sessionStore: store,
        ).login('admin', 'admin123', remember: true),
      );

      await tester.pumpWidget(
        AlingBalanceApp(auth: AuthController(_api(fake), sessionStore: store)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsNothing);
      expect(find.text('Inicio'), findsWidgets);
    });

    testWidgets('el login ofrece "Mantener la sesión iniciada"', (
      tester,
    ) async {
      _wideScreen(tester);
      final fake = FakeApi();
      final store = MemorySessionStore();
      await tester.pumpWidget(
        AlingBalanceApp(auth: AuthController(_api(fake), sessionStore: store)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mantener la sesión iniciada'), findsOneWidget);

      // Se desmarca: no queda guardada.
      await tester.tap(find.text('Mantener la sesión iniciada'));
      await tester.enterText(find.byType(TextFormField).at(0), 'admin');
      await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(fake.lastRememberMe, isFalse);
      expect(store.session, isNull);
    });
  });

  // -------------------------------------------------- Contraseñas y roles

  group('contraseña y rol', () {
    test('cambiar la contraseña cierra las demás sesiones', () async {
      final fake = FakeApi();
      final store = MemorySessionStore();
      final auth = AuthController(_api(fake), sessionStore: store);
      await auth.login('admin', 'admin123', remember: true);
      final oldToken = auth.api.token;

      // Otro dispositivo con la sesión anterior.
      final otherDevice = _api(fake)..token = oldToken;

      expect(
        await auth.changePassword('mala', 'nueva12345'),
        'La contraseña actual no es correcta.',
      );
      expect(await auth.changePassword('admin123', 'nueva12345'), isNull);

      expect(auth.api.token, isNot(oldToken));
      expect(store.session?.token, auth.api.token);
      await expectLater(
        otherDevice.getObject('/api/auth/me'),
        throwsA(isA<ApiException>()),
      );
      expect(await auth.api.getObject('/api/auth/me'), isNotEmpty);

      final again = AuthController(_api(fake));
      expect(await again.login('admin', 'nueva12345'), isNull);
    });

    test('el administrador edita el rol y la contraseña de otro', () async {
      final fake = FakeApi()
        ..addUser(
          name: 'Luis Pérez',
          username: 'luis',
          password: 'clave1234',
          role: 'empleado',
        );
      final luis = AuthController(_api(fake));
      await luis.login('luis', 'clave1234');

      final admin = AuthController(_api(fake));
      await admin.login('admin', 'admin123');
      await admin.loadUsers();

      expect(
        await admin.updateUser(2, 'Luis Pérez Gómez', UserRole.admin),
        isNull,
      );
      expect(fake.users[1]['role'], 'administrador');
      expect(admin.users[1].name, 'Luis Pérez Gómez');

      // Su sesión anterior se cerró para que entre con el rol nuevo.
      await expectLater(
        luis.api.getObject('/api/auth/me'),
        throwsA(isA<ApiException>()),
      );

      expect(await admin.resetPassword(2, 'nueva12345'), isNull);
      expect(
        await AuthController(_api(fake)).login('luis', 'nueva12345'),
        isNull,
      );
    });

    test('no puede cambiar su propio rol ni quitar el último admin', () async {
      final fake = FakeApi();
      final admin = AuthController(_api(fake));
      await admin.login('admin', 'admin123');
      await admin.loadUsers();

      expect(
        await admin.updateUser(1, 'Administrador', UserRole.employee),
        contains('propio rol'),
      );
      expect(
        await admin.resetPassword(1, 'otra12345'),
        contains('Cambiar contraseña'),
      );
    });

    testWidgets('cambiar contraseña desde el menú de la cuenta', (
      tester,
    ) async {
      _wideScreen(tester);
      final fake = FakeApi();
      await tester.pumpWidget(
        AlingBalanceApp(auth: AuthController(_api(fake))),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'admin');
      await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Administrador · Administrador'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();

      final fields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(fields.at(0), 'admin123');
      await tester.enterText(fields.at(1), 'nueva12345');
      await tester.enterText(fields.at(2), 'nueva12345');
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Cambiar contraseña'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contraseña actualizada.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      // Sigue dentro con el token nuevo.
      expect(find.text('Iniciar sesión'), findsNothing);
    });
  });

  // ---------------------------------------------- Empleado y comisiones

  group('servicios y comisiones', () {
    late FakeApi fake;
    late WorkshopController controller;
    final now = DateTime.now();

    setUp(() async {
      fake = FakeApi()
        ..addEmployee(name: 'Ana', document: '1001')
        ..addEmployee(name: 'Beto', document: '1002')
        ..addService(plate: 'AAA-111', price: 30000, date: now, employeeId: 1)
        ..addService(plate: 'BBB-222', price: 20000, date: now, employeeId: 1)
        ..addService(plate: 'CCC-333', price: 50000, date: now, employeeId: 2);
      final api = _api(fake)..token = fake.tokenFor(1);
      controller = WorkshopController(
        repository: WorkshopRepository(api),
        includeFinances: true,
      );
      await controller.load();
    });

    test('reasignar el empleado de un servicio', () async {
      expect(await controller.assignEmployee(1, 2), isNull);

      final service = controller.services.firstWhere((s) => s.operation == 1);
      expect(service.employeeId, 2);
      expect(fake.services.first['employeeName'], 'Beto');

      final beto = controller
          .commissionsForMonth(now.year, now.month)
          .firstWhere((c) => c.employeeId == 2);
      expect(beto.amount, 15000 + 9000);
    });

    test('pagar, bloquear cambios y deshacer el pago', () async {
      var ana = controller
          .commissionsForMonth(now.year, now.month)
          .firstWhere((c) => c.employeeId == 1);
      expect(ana.amount, 9000 + 6000);
      expect(ana.pendingOperations, unorderedEquals([1, 2]));

      expect(await controller.payCommissions(1, now.year, now.month), isNull);

      ana = controller
          .commissionsForMonth(now.year, now.month)
          .firstWhere((c) => c.employeeId == 1);
      expect(ana.paidAmount, 15000);
      expect(ana.fullyPaid, isTrue);
      expect(fake.commissionPayments.single['amount'], 15000);
      expect(controller.paymentsIn(now.year, now.month), hasLength(1));

      // Ya pagado: no se reasigna ni se reabre.
      expect(await controller.assignEmployee(1, 2), contains('ya se pagó'));
      expect(await controller.toggleServiceStatus(1), contains('ya se pagó'));

      final payment = controller.commissionPayments.single;
      expect(await controller.undoCommissionPayment(payment.id), isNull);
      expect(controller.services.where((s) => s.commissionPaid), isEmpty);
      expect(
        fake.services.every((s) => s['commissionPaymentId'] == null),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------- Gastos

  group('gastos', () {
    late FakeApi fake;
    late WorkshopController controller;

    setUp(() async {
      fake = FakeApi()
        ..addExpense(description: 'Pesas', amount: 50000, date: '2026-11-02');
      final api = _api(fake)..token = fake.tokenFor(1);
      controller = WorkshopController(
        repository: WorkshopRepository(api),
        includeFinances: true,
      );
      await controller.load();
    });

    test('editar un gasto', () async {
      final error = await controller.updateExpense(
        1,
        NewExpenseData(
          description: 'Pesas de balanceo',
          category: 'Insumos y repuestos',
          amount: 65000,
          date: DateTime(2026, 11, 3),
        ),
      );

      expect(error, isNull);
      final expense = controller.expenses.single;
      expect(expense.amount, 65000);
      expect(expense.category, 'Insumos y repuestos');
      expect(expense.date, DateTime(2026, 11, 3));
    });

    test('gasto fijo: se registra, se pausa y se elimina', () async {
      fake.today = DateTime(2026, 11, 15);

      expect(
        await controller.addRecurringExpense(
          const RecurringExpenseData(
            description: 'Arriendo del local',
            category: 'Arriendo',
            amount: 1500000,
            dayOfMonth: 1,
          ),
        ),
        isNull,
      );

      expect(controller.recurringExpenses.single.dayOfMonth, 1);
      // El servidor registró el de este mes y la app lo descargó.
      final generated = controller.expenses.where((e) => e.isRecurring);
      expect(generated.single.amount, 1500000);
      expect(generated.single.date, DateTime(2026, 11, 1));

      final item = controller.recurringExpenses.single;
      expect(await controller.toggleRecurringExpense(item), isNull);
      expect(controller.recurringExpenses.single.active, isFalse);

      expect(await controller.deleteRecurringExpense(item.id), isNull);
      expect(controller.recurringExpenses, isEmpty);
      // El gasto ya registrado se conserva.
      expect(controller.expenses, hasLength(2));
    });
  });

  // ------------------------------------------------------------- Informes

  group('exportar el resumen mensual', () {
    late WorkshopController controller;

    setUp(() async {
      final fake = FakeApi()
        ..addEmployee(name: 'Ana Gómez', document: '1001')
        ..addService(
          plate: 'AAA-111',
          price: 30000,
          date: DateTime(2026, 11, 4, 10),
          employeeId: 1,
        )
        ..addService(
          plate: 'BBB-222',
          price: 20000,
          date: DateTime(2026, 11, 5, 10),
        )
        ..addExpense(
          description: 'Arriendo del local',
          amount: 1000000,
          date: '2026-11-01',
        );
      final api = _api(fake)..token = fake.tokenFor(1);
      controller = WorkshopController(
        repository: WorkshopRepository(api),
        includeFinances: true,
      );
      await controller.load();
    });

    test('el PDF se genera', () async {
      final report = MonthlyReport.fromController(controller, 2026, 11);
      final bytes = await buildMonthlyReportPdf(report);

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(2000));
      expect(report.fileName, 'AlingBalance_resumen_2026-11');
    });

    test('el Excel tiene una hoja por tema con valores numéricos', () {
      final report = MonthlyReport.fromController(controller, 2026, 11);
      final bytes = buildMonthlyReportExcel(report);
      final book = Excel.decodeBytes(bytes);

      expect(
        book.tables.keys,
        containsAll(['Resumen', 'Servicios', 'Gastos', 'Comisiones']),
      );
      expect(book.tables.keys, isNot(contains('Sheet1')));

      final resumen = book.tables['Resumen']!;
      final income = resumen.rows.firstWhere(
        (row) => row.first?.value.toString().startsWith('Ingresos') ?? false,
      );
      expect(income[1]?.value, IntCellValue(50000));

      final servicios = book.tables['Servicios']!;
      expect(servicios.maxRows, 3); // encabezado + 2 servicios
      expect(servicios.rows[1][8]?.value, IntCellValue(9000));

      final comisiones = book.tables['Comisiones']!;
      expect(comisiones.rows[1][0]?.value, TextCellValue('Ana Gómez'));
      expect(comisiones.rows[1][4]?.value, IntCellValue(9000));
    });
  });

  // ----------------------------------------------------- Pantallas (admin)

  group('pantallas de administración', () {
    Future<(FakeApi, _MemorySaver)> openDashboard(WidgetTester tester) async {
      _wideScreen(tester);
      final now = DateTime.now();
      final fake = FakeApi()
        ..addEmployee(name: 'Ana', document: '1001')
        ..addEmployee(name: 'Beto', document: '1002')
        ..addService(plate: 'AAA-111', price: 30000, date: now, employeeId: 1);
      final auth = AuthController(_api(fake));
      await tester.runAsync(() => auth.login('admin', 'admin123'));
      final saver = _MemorySaver();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: DashboardScreen(auth: auth, reportSaver: saver),
        ),
      );
      await tester.pumpAndSettle();
      return (fake, saver);
    }

    testWidgets('cambiar el empleado desde la tarjeta del servicio', (
      tester,
    ) async {
      final (fake, _) = await openDashboard(tester);
      await tester.tap(find.text('Servicios').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cambiar empleado'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beto').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(fake.services.single['employeeName'], 'Beto');
      expect(find.text('Empleado: Beto'), findsOneWidget);
    });

    testWidgets('pagar comisión y exportar desde Contabilidad', (tester) async {
      final (fake, saver) = await openDashboard(tester);
      await tester.tap(find.text('Contabilidad').first);
      await tester.pumpAndSettle();

      final pay = find.text('Pagar \$9.000');
      await tester.ensureVisible(pay);
      await tester.tap(pay);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar pago'));
      await tester.pumpAndSettle();

      expect(fake.commissionPayments.single['amount'], 9000);
      expect(find.text('Pagada'), findsOneWidget);

      await tester.ensureVisible(find.text('Exportar'));
      await tester.tap(find.text('Exportar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excel (.xlsx)'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(saver.saved.single.$2, ReportFormat.excel);
      expect(saver.saved.single.$1, startsWith('AlingBalance_resumen_'));
    });

    testWidgets('editar el rol de un usuario', (tester) async {
      final (fake, _) = await openDashboard(tester);
      fake.addUser(
        name: 'Luis Pérez',
        username: 'luis',
        password: 'clave1234',
        role: 'empleado',
      );
      await tester.tap(find.text('Usuarios').first);
      await tester.pumpAndSettle();
      // Recarga la lista con el usuario nuevo.
      await tester.tap(find.byTooltip('Actualizar datos'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Editar nombre y rol').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<UserRole>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Administrador').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('se cerrará la sesión'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar cambios'));
      await tester.pumpAndSettle();

      expect(fake.users.last['role'], 'administrador');
      // El aviso queda en cola detrás de "Datos actualizados." (4 s).
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Usuario actualizado.'), findsOneWidget);
    });
  });
}
