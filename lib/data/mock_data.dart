import '../models/emergency_contact.dart';

/// Sample account, wearer and contact details retained for the existing UI.
class MockData {
  // The signed-in caregiver
  static const caregiverName = 'Maria Santos';
  static const caregiverEmail = 'caregiver@cardioguard.app';
  static const caregiverRole = 'Daughter · Primary Caregiver';

  // The person wearing the device
  static const wearerName = 'Roberto Santos';
  static const wearerAge = 72;
  static const wearerCondition = 'Cardiac monitoring';

  // Primary emergency contact
  static const contactName = 'Maria Santos';
  static const contactRelationship = 'Daughter';
  static const contactPhone = '+63 917 555 0142';

  // ---------------------------------------------------------- Contacts
  static const contacts = [
    EmergencyContact(
      name: 'Maria Santos',
      relationship: 'Daughter',
      phone: '+63 917 555 0142',
      primary: true,
    ),
    EmergencyContact(
      name: 'Dr. Reyes',
      relationship: 'Physician',
      phone: '+63 912 888 0234',
    ),
  ];
}
