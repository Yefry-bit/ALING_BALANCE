import 'package:flutter/widgets.dart';

import '../models/service_record.dart';

/// Acciones extra sobre los servicios que el panel ofrece según el rol.
///
/// Las tarjetas de servicio aparecen en varias secciones (Inicio, Servicios,
/// ficha del cliente); en vez de pasar cada acción por todas ellas, el panel
/// las publica aquí y cada [ServiceCard] las lee.
class ServiceActions extends InheritedWidget {
  const ServiceActions({
    super.key,
    required super.child,
    this.onChangeEmployee,
    this.onNotifyClient,
    this.canNotifyClient,
  });

  /// Cambiar el empleado que realiza el servicio (solo administradores).
  final ValueChanged<ServiceRecord>? onChangeEmployee;

  /// Avisar al cliente por WhatsApp que su vehículo está listo.
  final ValueChanged<ServiceRecord>? onNotifyClient;

  /// Si el servicio tiene un cliente con celular al que se puede avisar.
  final bool Function(ServiceRecord service)? canNotifyClient;

  static ServiceActions? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ServiceActions>();

  @override
  bool updateShouldNotify(ServiceActions oldWidget) =>
      oldWidget.onChangeEmployee != onChangeEmployee ||
      oldWidget.onNotifyClient != onNotifyClient ||
      oldWidget.canNotifyClient != canNotifyClient;
}
