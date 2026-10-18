import 'package:flutter/material.dart';

import '../models/alert_event.dart';
import '../theme.dart';

/// Colour and label for each severity, used by the dot, badge and filters.
extension SeverityStyle on Severity {
  Color get color => switch (this) {
        Severity.emergency => AppColors.emergency,
        Severity.warning => AppColors.warning,
        Severity.info => AppColors.success,
      };

  /// Darker text colour so amber stays readable on its light badge.
  Color get textColor => switch (this) {
        Severity.emergency => const Color(0xFFB91C1C),
        Severity.warning => const Color(0xFFB45309),
        Severity.info => const Color(0xFF15803D),
      };

  String get label => switch (this) {
        Severity.emergency => 'Emergency',
        Severity.warning => 'Warning',
        Severity.info => 'Info',
      };
}

/// Rounded "Emergency / Warning / Info" pill.
class SeverityBadge extends StatelessWidget {
  final Severity severity;
  const SeverityBadge(this.severity, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: severity.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: severity.color.withValues(alpha: 0.3)),
      ),
      child: Text(severity.label, style: TextStyle(color: severity.textColor, fontSize: 12.5)),
    );
  }
}

/// Small coloured dot shown before an event title.
class SeverityDot extends StatelessWidget {
  final Severity severity;
  const SeverityDot(this.severity, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: severity.color, shape: BoxShape.circle),
    );
  }
}
