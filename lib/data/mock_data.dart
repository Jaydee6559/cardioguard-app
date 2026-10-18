import '../models/alert_event.dart';
import '../models/emergency_contact.dart';

/// Sample values used while the app is UI-only.
///
/// Every screen reads its numbers from here. When the Arduino is connected,
/// these get replaced by live data and the screens stay the same.
class MockData {
  // The signed-in caregiver
  static const caregiverName = 'Maria Santos';
  static const caregiverEmail = 'caregiver@cardioguard.app';
  static const caregiverRole = 'Daughter · Primary Caregiver';

  // The person wearing the device
  static const wearerName = 'Roberto Santos';
  static const wearerAge = 72;
  static const wearerCondition = 'Cardiac monitoring';

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

  // ---------------------------------------------------------------- Vitals
  // Normal ranges shown under the charts
  static const heartRateNormalLow = 60.0, heartRateNormalHigh = 100.0;
  static const spo2NormalLow = 95.0, spo2NormalHigh = 100.0;

  // Daily: one reading every 2 hours, 06:00–20:00 (x = hour)
  static const dailyHeartRate = [
    ChartPoint(6, 67), ChartPoint(8, 71), ChartPoint(10, 74), ChartPoint(12, 78),
    ChartPoint(14, 74), ChartPoint(16, 71), ChartPoint(18, 69), ChartPoint(20, 72),
  ];
  static const dailySpo2 = [
    ChartPoint(6, 97), ChartPoint(8, 98), ChartPoint(10, 98), ChartPoint(12, 97),
    ChartPoint(14, 96), ChartPoint(16, 97), ChartPoint(18, 98), ChartPoint(20, 98),
  ];

  // Weekly: daily averages for the last 7 days (x = 0 oldest … 6 today)
  static const weeklyHeartRate = [
    ChartPoint(0, 70), ChartPoint(1, 73), ChartPoint(2, 71), ChartPoint(3, 75),
    ChartPoint(4, 69), ChartPoint(5, 72), ChartPoint(6, 72),
  ];
  static const weeklySpo2 = [
    ChartPoint(0, 97), ChartPoint(1, 98), ChartPoint(2, 97), ChartPoint(3, 96),
    ChartPoint(4, 98), ChartPoint(5, 97), ChartPoint(6, 98),
  ];

  // ---------------------------------------------------------------- Alerts
  // Newest first, matching the prototype.
  static final events = <AlertEvent>[
    AlertEvent(
      title: 'Manual SOS',
      description: 'Manual SOS button triggered by wearer.',
      severity: Severity.emergency,
      time: DateTime(2026, 9, 14, 14, 22),
    ),
    AlertEvent(
      title: 'Abnormal Heart Rate',
      description: 'Heart rate dropped to 48 BPM — below normal range.',
      severity: Severity.warning,
      time: DateTime(2026, 9, 13, 9, 5),
    ),
    AlertEvent(
      title: 'Possible Fall Detected',
      description: 'Sudden impact detected by MPU6050.',
      severity: Severity.emergency,
      time: DateTime(2026, 9, 12, 16, 40),
    ),
    AlertEvent(
      title: 'Post-fall Response',
      description: "Wearer confirmed 'I'm OK' after fall detection.",
      severity: Severity.info,
      time: DateTime(2026, 9, 12, 16, 40),
    ),
    AlertEvent(
      title: 'Device Disconnected',
      description: 'Bluetooth connection lost for 4 minutes.',
      severity: Severity.warning,
      time: DateTime(2026, 9, 11, 8, 17),
    ),
    AlertEvent(
      title: 'No Response Detected',
      description: 'Wearer did not respond within 15 s after fall.',
      severity: Severity.emergency,
      time: DateTime(2026, 9, 10, 11, 55),
    ),
  ];

  // ---------------------------------------------------------- Contacts
  static const contacts = [
    EmergencyContact(name: 'Maria Santos', relationship: 'Daughter', phone: '+63 917 555 0142', primary: true),
    EmergencyContact(name: 'Dr. Reyes', relationship: 'Physician', phone: '+63 912 888 0234'),
  ];

  // ---------------------------------------------------------- Device & Sensors
  static const batteryHoursLeft = 14;
  static const sensors = [
    SensorInfo('Arduino Uno R3', 'Main Controller', 'Connected'),
    SensorInfo('HC-05 Bluetooth', 'Communication', 'Connected'),
    SensorInfo('MAX30102', 'Heart Rate & SpO₂', 'Working'),
    SensorInfo('MPU6050', 'Movement & Fall Detection', 'Working'),
    SensorInfo('Buzzer', 'Local Alert', 'Ready'),
  ];
}

/// One row on the Device & Sensors screen.
class SensorInfo {
  final String name;
  final String role;
  final String status; // Connected / Working / Ready / Error
  const SensorInfo(this.name, this.role, this.status);

  bool get ok => status != 'Error';
}
