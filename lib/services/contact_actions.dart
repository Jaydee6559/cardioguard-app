import 'package:url_launcher/url_launcher.dart';

import '../data/app_state.dart';
import '../models/alert_event.dart';
import '../models/emergency_contact.dart';

/// Opens the phone's dialer or messaging app for a contact, and records it
/// in Alerts & Events. Returns false when the phone couldn't open the app.
class ContactActions {
  ContactActions._();

  static String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

  static Future<bool> call(EmergencyContact c) async {
    final ok = await _open(Uri(scheme: 'tel', path: _digits(c.phone)));
    if (ok) {
      await AppState.logEvent('Emergency Contact Called', 'Called ${c.name} (${c.phone}).', Severity.info);
    }
    return ok;
  }

  /// Opens the messaging app with [message] already typed in.
  static Future<bool> text(EmergencyContact c, String message) async {
    // Built by hand: Uri(queryParameters:) would turn spaces into "+".
    final ok = await _open(Uri.parse('sms:${_digits(c.phone)}?body=${Uri.encodeComponent(message)}'));
    if (ok) {
      await AppState.logEvent('Emergency Contact Texted', 'Sent an SMS to ${c.name} (${c.phone}).', Severity.info);
    }
    return ok;
  }

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}
