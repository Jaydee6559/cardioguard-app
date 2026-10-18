import 'package:flutter/foundation.dart';

import '../models/emergency_contact.dart';
import 'mock_data.dart';

/// Data shared between screens while the app is running.
///
/// UI-only stage: everything lives in memory and resets when the app
/// restarts. Saving to the phone comes in the storage stage.
class AppState {
  AppState._();

  /// Emergency contacts. Settings shows the count, the Contacts screen edits
  /// them, and the Emergency Alert calls the primary one.
  static final contacts = ValueNotifier<List<EmergencyContact>>(List.of(MockData.contacts));

  static EmergencyContact? get primaryContact {
    final list = contacts.value;
    if (list.isEmpty) return null;
    return list.firstWhere((c) => c.primary, orElse: () => list.first);
  }

  /// Adds a contact, or replaces the one at [index]. Marking one as primary
  /// clears primary from the others. The first contact is always primary.
  static void saveContact(EmergencyContact contact, {int? index}) {
    final list = List.of(contacts.value);
    if (index == null) {
      list.add(contact);
    } else {
      list[index] = contact;
    }
    if (contact.primary) {
      for (var i = 0; i < list.length; i++) {
        if (list[i] != contact && list[i].primary) list[i] = list[i].copyWith(primary: false);
      }
    }
    contacts.value = _ensurePrimary(list);
  }

  static void deleteContact(int index) {
    final list = List.of(contacts.value)..removeAt(index);
    contacts.value = _ensurePrimary(list);
  }

  static List<EmergencyContact> _ensurePrimary(List<EmergencyContact> list) {
    if (list.isNotEmpty && !list.any((c) => c.primary)) {
      list[0] = list[0].copyWith(primary: true);
    }
    return list;
  }

  /// Put everything back to the sample data (used on Sign Out).
  static void reset() {
    contacts.value = List.of(MockData.contacts);
  }
}
