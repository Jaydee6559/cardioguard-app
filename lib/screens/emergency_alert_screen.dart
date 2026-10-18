import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/mock_data.dart';
import '../routes.dart';
import '../theme.dart';
import '../utils/formatters.dart';

/// Why the Emergency Alert was raised. Passed as the route's arguments.
class EmergencyAlertArgs {
  final String title;
  final String detail;
  const EmergencyAlertArgs(this.title, this.detail);

  static const noResponse = EmergencyAlertArgs(
    'Possible fall detected',
    'No response received within 15 seconds. Immediate attention may be required.',
  );
  static const helpRequested = EmergencyAlertArgs(
    'Help requested after a fall',
    'The wearer tapped NEED HELP during the fall check.',
  );
  static const sos = EmergencyAlertArgs(
    'SOS button pressed',
    'The wearer asked for help. Immediate attention may be required.',
  );
}

/// Screen 10 — Emergency Alert (full red screen).
///
/// Can only be left with Acknowledge Alert, so it is never dismissed by
/// accident.
class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  final DateTime _raisedAt = DateTime.now();

  EmergencyAlertArgs get _args {
    final a = ModalRoute.of(context)?.settings.arguments;
    return a is EmergencyAlertArgs ? a : EmergencyAlertArgs.noResponse;
  }

  Future<void> _callContact() async {
    final uri = Uri(scheme: 'tel', path: MockData.contactPhone.replaceAll(' ', ''));
    bool opened;
    try {
      opened = await launchUrl(uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone dialer.')),
      );
    }
  }

  void _acknowledge() {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.home));
    messenger.showSnackBar(const SnackBar(content: Text('Alert acknowledged.')));
  }

  void _viewDetails() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Event details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _DetailRow('Event', _args.title),
              _DetailRow('What happened', _args.detail),
              _DetailRow('Time', Formatters.alertStamp(_raisedAt)),
              const _DetailRow('Wearer', '${MockData.wearerName}, age ${MockData.wearerAge}'),
              const _DetailRow(
                'Readings',
                '${MockData.alertHeartRate} BPM · SpO₂ ${MockData.alertSpo2}% · ${MockData.alertMovement} movement',
              ),
              const _DetailRow('Primary contact', '${MockData.contactName} (${MockData.contactRelationship})'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light, // white status-bar icons on red
        child: Scaffold(
          backgroundColor: AppColors.emergency,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Formatters.alertStamp(_raisedAt),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, letterSpacing: 0.8),
                                ),
                                const Text(
                                  'Emergency Alert',
                                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _RedCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(args.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              args.detail,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14.5, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _RedCard(
                        label: 'Wearer',
                        child: _NameLine(MockData.wearerName, 'Patient · Age ${MockData.wearerAge}'),
                      ),
                      const SizedBox(height: 12),
                      const _RedCard(
                        label: 'Current readings',
                        child: Row(
                          children: [
                            Expanded(child: _Reading('${MockData.alertHeartRate}', 'BPM', 'Heart Rate')),
                            Expanded(child: _Reading('${MockData.alertSpo2}', '%', 'SpO₂')),
                            Expanded(child: _Reading('—', MockData.alertMovement, 'Movement')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _RedCard(
                        label: 'Primary contact',
                        child: _NameLine(
                          '${MockData.contactName} · ${MockData.contactRelationship}',
                          MockData.contactPhone,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions stay pinned at the bottom.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    children: [
                      FilledButton.icon(
                        onPressed: _callContact,
                        icon: const Icon(Icons.call),
                        label: const Text('Call Emergency Contact'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _acknowledge,
                        style: FilledButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.18)),
                        child: const Text('Acknowledge Alert'),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _viewDetails,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('View Event Details'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slightly lighter red card on the red background.
class _RedCard extends StatelessWidget {
  final String? label;
  final Widget child;
  const _RedCard({this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!.toUpperCase(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5, letterSpacing: 1.1),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

/// Bold name line + smaller line underneath.
class _NameLine extends StatelessWidget {
  final String name;
  final String sub;
  const _NameLine(this.name, this.sub);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
      ],
    );
  }
}

/// One reading in the "Current readings" card.
class _Reading extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  const _Reading(this.value, this.unit, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
        Text(unit, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
      ],
    );
  }
}

/// Label + value row in the Event details sheet.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
        ],
      ),
    );
  }
}
