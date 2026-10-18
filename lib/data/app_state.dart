import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../models/alert_event.dart';
import '../models/emergency_contact.dart';
import 'mock_data.dart';

/// Everything the app saves on the phone, in one place.
///
/// Stored with shared_preferences (small key–value storage on the phone):
///  * accounts       – name, email, relationship and a hashed password
///  * remember me    – which account stays signed in after the app closes
///  * alert switches – the three toggles in Settings
///  * contacts       – the Emergency Contacts list
///  * events         – the Alerts & Events log (newest first, max 200)
///
/// Screens listen to the ValueNotifiers below, so they update by themselves
/// when something changes. Call [init] once in main() before runApp.
class AppState {
  AppState._();

  static late SharedPreferences _prefs;

  // Storage keys
  static const _kAccounts = 'accounts';
  static const _kRemembered = 'remembered_email';
  static const _kContacts = 'contacts';
  static const _kEvents = 'events';
  static const _kFallAlerts = 'alerts_fall';
  static const _kHeartAlerts = 'alerts_heart_rate';
  static const _kDisconnectAlerts = 'alerts_disconnect';

  static const maxEvents = 200;

  /// The signed-in caregiver, or null when signed out.
  static final account = ValueNotifier<Account?>(null);
  static final contacts = ValueNotifier<List<EmergencyContact>>([]);
  static final events = ValueNotifier<List<AlertEvent>>([]);

  static bool get isSignedIn => account.value != null;

  /// Loads everything saved on the phone. The first time the app runs, the
  /// sample contacts and events are saved so the screens aren't empty.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Contacts
    final savedContacts = _prefs.getString(_kContacts);
    if (savedContacts == null) {
      contacts.value = List.of(MockData.contacts);
      await _saveContacts();
    } else {
      contacts.value = _decodeList(savedContacts, EmergencyContact.fromJson);
    }

    // Events
    final savedEvents = _prefs.getString(_kEvents);
    if (savedEvents == null) {
      events.value = List.of(MockData.events);
      await _saveEvents();
    } else {
      events.value = _decodeList(savedEvents, AlertEvent.fromJson);
    }

    // Remember me: sign straight back in
    final remembered = _prefs.getString(_kRemembered);
    account.value = remembered == null ? null : _accountFor(remembered);
  }

  // ================================================================ Accounts

  static Map<String, dynamic> _accounts() {
    final raw = _prefs.getString(_kAccounts);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static String _key(String email) => email.trim().toLowerCase();

  static bool hasAccount(String email) => _accounts().containsKey(_key(email));

  static Account? _accountFor(String email) {
    final a = _accounts()[_key(email)];
    if (a is! Map<String, dynamic>) return null;
    return Account(
      name: a['name'] as String? ?? '',
      email: _key(email),
      relationship: a['relationship'] as String? ?? '',
    );
  }

  /// Passwords are never saved as typed: only a salted SHA-256 hash.
  static String _hash(String password, String salt) => sha256.convert(utf8.encode('$salt:$password')).toString();

  static String _newSalt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  /// Saves a new account. Returns an error message, or null on success.
  static Future<String?> createAccount({
    required String name,
    required String email,
    required String password,
    required String relationship,
  }) async {
    if (hasAccount(email)) return 'An account with this email already exists.';
    final salt = _newSalt();
    final all = _accounts();
    all[_key(email)] = {
      'name': name.trim(),
      'relationship': relationship.trim(),
      'salt': salt,
      'hash': _hash(password, salt),
    };
    await _prefs.setString(_kAccounts, jsonEncode(all));
    return null;
  }

  /// Checks the email and password. Returns an error message, or null when
  /// signed in. With [remember], the account stays signed in after restart.
  static Future<String?> signIn(String email, String password, {required bool remember}) async {
    final a = _accounts()[_key(email)];
    if (a is! Map<String, dynamic>) return 'No account found for this email. Tap "Create one" to register.';
    if (_hash(password, a['salt'] as String? ?? '') != a['hash']) return 'Incorrect password. Please try again.';

    account.value = _accountFor(email);
    if (remember) {
      await _prefs.setString(_kRemembered, _key(email));
    } else {
      await _prefs.remove(_kRemembered);
    }
    return null;
  }

  static Future<void> signOut() async {
    account.value = null;
    await _prefs.remove(_kRemembered);
  }

  // ========================================================= Alert switches

  static bool get fallAlerts => _prefs.getBool(_kFallAlerts) ?? true;
  static bool get heartRateAlerts => _prefs.getBool(_kHeartAlerts) ?? true;
  static bool get disconnectAlerts => _prefs.getBool(_kDisconnectAlerts) ?? false;

  static Future<void> setFallAlerts(bool v) => _prefs.setBool(_kFallAlerts, v);
  static Future<void> setHeartRateAlerts(bool v) => _prefs.setBool(_kHeartAlerts, v);
  static Future<void> setDisconnectAlerts(bool v) => _prefs.setBool(_kDisconnectAlerts, v);

  // =============================================================== Contacts

  static EmergencyContact? get primaryContact {
    final list = contacts.value;
    if (list.isEmpty) return null;
    return list.firstWhere((c) => c.primary, orElse: () => list.first);
  }

  /// Adds a contact, or replaces the one at [index]. Marking one as primary
  /// clears primary from the others. The first contact is always primary.
  static Future<void> saveContact(EmergencyContact contact, {int? index}) async {
    final list = List.of(contacts.value);
    if (index == null) {
      list.add(contact);
    } else {
      list[index] = contact;
    }
    if (contact.primary) {
      for (var i = 0; i < list.length; i++) {
        if (!identical(list[i], contact) && list[i].primary) list[i] = list[i].copyWith(primary: false);
      }
    }
    contacts.value = _ensurePrimary(list);
    await _saveContacts();
  }

  static Future<void> deleteContact(int index) async {
    final list = List.of(contacts.value)..removeAt(index);
    contacts.value = _ensurePrimary(list);
    await _saveContacts();
  }

  static List<EmergencyContact> _ensurePrimary(List<EmergencyContact> list) {
    if (list.isNotEmpty && !list.any((c) => c.primary)) {
      list[0] = list[0].copyWith(primary: true);
    }
    return list;
  }

  static Future<void> _saveContacts() =>
      _prefs.setString(_kContacts, jsonEncode(contacts.value.map((c) => c.toJson()).toList()));

  // ============================================================= Event log

  /// Adds an event to the top of Alerts & Events, stamped with the current time.
  static Future<void> logEvent(String title, String description, Severity severity) async {
    final list = [
      AlertEvent(title: title, description: description, severity: severity, time: DateTime.now()),
      ...events.value,
    ];
    events.value = list.length > maxEvents ? list.sublist(0, maxEvents) : list;
    await _saveEvents();
  }

  static Future<void> clearEvents() async {
    events.value = [];
    await _saveEvents();
  }

  static Future<void> _saveEvents() =>
      _prefs.setString(_kEvents, jsonEncode(events.value.map((e) => e.toJson()).toList()));

  // ================================================================ helpers

  static List<T> _decodeList<T>(String raw, T Function(Map<String, dynamic>) fromJson) {
    try {
      return (jsonDecode(raw) as List).whereType<Map<String, dynamic>>().map(fromJson).toList();
    } catch (_) {
      return []; // corrupted data: start empty rather than crash
    }
  }
}
