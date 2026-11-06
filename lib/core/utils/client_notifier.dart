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

/// Mensaje de "su vehículo está listo". Usa el formato de WhatsApp (*negrita*
/// y _cursiva_), emojis y secciones para que se vea como un comprobante.
String readyMessage({
  required String clientName,
  required ServiceRecord service,
  bool includePrice = true,
}) {
  final firstName = clientName.trim().split(RegExp(r'\s+')).first;
  final greeting = firstName.isEmpty ? 'Hola' : 'Hola *$firstName*';

  return [
    '✅ *¡Su vehículo está listo!* 🎉',
    '',
    '$greeting, le escribimos de *$shopName*.',
    '',
    '🚗 *Detalle del servicio*',
    '*Vehículo:* _${service.vehicle}_',
    '*Placa:* _${service.plate}_',
    '*Servicio:* _${service.service}_',
    if (includePrice) '*Valor:* _${formatMoney(service.price)}_',
    '',
    '📍 Puede pasar a recogerlo cuando quiera.',
    '🙏 _¡Gracias por su confianza!_',
  ].join('\n');
}

/// El mismo mensaje sin las marcas de formato de WhatsApp (`*` y `_`), para
/// los SMS, que no interpretan negritas ni cursivas.
String plainText(String message) => message.replaceAll(RegExp(r'[*_]'), '');

/// Si la app corre en el navegador o en un computador (no en un celular).
bool get isDesktopOrWeb =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.linux;

/// Enlace que abre WhatsApp con el mensaje escrito.
///
/// - En el celular usa `wa.me`, que abre la app de WhatsApp.
/// - En el navegador o el computador usa WhatsApp Web: el enlace `wa.me` puede
///   abrir la app de escritorio de Windows, que pierde los emojis del mensaje
///   (los muestra como "�"). WhatsApp Web los conserva.
///
/// Los espacios van como %20 (no "+"), que es lo que esperan WhatsApp y SMS.
Uri whatsappUri(String number, String message, {bool? desktop}) {
  final text = Uri.encodeComponent(message);
  return (desktop ?? isDesktopOrWeb)
      ? Uri.parse('https://web.whatsapp.com/send?phone=$number&text=$text')
      : Uri.parse('https://wa.me/$number?text=$text');
}

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
