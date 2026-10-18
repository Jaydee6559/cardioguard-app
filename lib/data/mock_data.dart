/// Sample values used while the app is UI-only.
///
/// Every screen reads its numbers from here. When the Arduino is connected,
/// these get replaced by live data and the screens stay the same.
class MockData {
  // The person wearing the device
  static const wearerName = 'Roberto Santos';
  static const wearerAge = 72;

  // Dashboard readings
  static const deviceConnected = true;
  static const heartRate = 72; // BPM
  static const spo2 = 98; // %
  static const movement = 'Stable';
  static const movementDetail = 'Resting';
  static const battery = 82; // %

  // Readings shown on the Emergency Alert screen
  static const alertHeartRate = 52; // BPM
  static const alertSpo2 = 91; // %
  static const alertMovement = 'Limited';

  // Primary emergency contact
  static const contactName = 'Maria Santos';
  static const contactRelationship = 'Daughter';
  static const contactPhone = '+63 917 555 0142';

  // Fall check
  static const fallCountdownSeconds = 15;
}
