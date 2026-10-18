/// How serious an event is. Drives the dot and badge colour.
enum Severity { emergency, warning, info }

/// One entry in Alerts & Events.
class AlertEvent {
  final String title;
  final String description;
  final Severity severity;
  final DateTime time;

  const AlertEvent({
    required this.title,
    required this.description,
    required this.severity,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'severity': severity.name,
        'time': time.millisecondsSinceEpoch,
      };

  static AlertEvent fromJson(Map<String, dynamic> j) => AlertEvent(
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        severity: Severity.values.asNameMap()[j['severity']] ?? Severity.info,
        time: DateTime.fromMillisecondsSinceEpoch(j['time'] as int? ?? 0),
      );
}

/// One point on a Vitals chart.
class ChartPoint {
  final double x; // hour of day (Daily) or day index 0–6 (Weekly)
  final double y; // BPM or %
  const ChartPoint(this.x, this.y);
}
