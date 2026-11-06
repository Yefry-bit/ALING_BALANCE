import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/service_record.dart';
import 'formatters.dart';

/// Nombre con el que el taller firma los avisos a los clientes.
const String shopName = 'AlingBalance';

/// Número para WhatsApp (con indicativo de Colombia) a partir del teléfono
/// del cliente. Solo los celulares (10 dígitos que empiezan por 3) tienen
/// WhatsApp; para un fijo o un teléfono vacío devuelve `null`.
String? whatsappNumber(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('57')) {
    digits = digits.substring(2);
  }
  if (digits.length != 10 || !digits.startsWith('3')) return null;
  return '57$digits';
}

/// Mensaje de "su vehículo está listo".
String readyMessage({
  required String clientName,
  required ServiceRecord service,
  bool includePrice = true,
}) {
  final firstName = clientName.trim().split(RegExp(r'\s+')).first;
  final price = includePrice ? ' Valor: ${formatMoney(service.price)}.' : '';
  return 'Hola $firstName, le escribimos de $shopName. Su vehículo '
      '${service.vehicle} de placa ${service.plate} ya está listo '
      '(${service.service}).$price Puede pasar a recogerlo cuando quiera. '
      '¡Gracias por su confianza!';
}

/// Enlace que abre WhatsApp con el mensaje escrito (en el celular abre la
/// app; en el computador, WhatsApp Web o la app de escritorio).
///
/// Los espacios van como %20 (no "+"), que es lo que esperan WhatsApp y SMS.
Uri whatsappUri(String number, String message) =>
    Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');

/// Enlace que abre los mensajes de texto (SMS) con el mensaje escrito.
Uri smsUri(String number, String message) =>
    Uri.parse('sms:+$number?body=${Uri.encodeComponent(message)}');

/// Los SMS solo se pueden abrir desde un celular (no desde el navegador ni
/// desde Windows).
bool get canSendSms =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Abre enlaces externos (WhatsApp, SMS). Se puede reemplazar en pruebas.
class MessageLauncher {
  const MessageLauncher();

  /// Devuelve `false` si no se pudo abrir.
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
