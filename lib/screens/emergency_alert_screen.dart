import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_state.dart';
import '../data/mock_data.dart';
import '../models/alert_event.dart';
import '../models/emergency_contact.dart';
import '../routes.dart';
import '../services/alarm_service.dart';
import '../services/contact_actions.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../widgets/contact_picker_sheet.dart';

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
  static const caregiverRaised = EmergencyAlertArgs(
    'Possible fall detected',
    'The caregiver raised the alert during the fall check. Immediate attention may be required.',
  );
  static const sos = EmergencyAlertArgs(
    'SOS button pressed',
    'The wearer asked for help. Immediate attention may be required.',
  );
}

/// Screen 10 — Emergency Alert (full red screen).
///
/// Alarm sound + vibration and a phone notification keep going until the
/// caregiver taps Acknowledge Alert (the sound can be muted). Back is
/// blocked, so the screen is never dismissed by accident.
class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  final DateTime _raisedAt = DateTime.now();
  bool _started = false;
  bool _muted = AlarmService.isMuted;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return; // run once; the route arguments are ready here
    _started = true;
    AlarmService.start(); // already ringing if we came from the fall check
    NotificationService.showEmergency(
      'EMERGENCY: ${MockData.wearerName.split(' ').first} needs help',
      _args.detail,
    );
  }

  EmergencyAlertArgs get _args {
    final a = ModalRoute.of(context)?.settings.arguments;
    return a is EmergencyAlertArgs ? a : EmergencyAlertArgs.noResponse;
  }

  // Primary contact from the Contacts screen (falls back to sample data).
  String get _contactName => AppState.primaryContact?.name ?? MockData.contactName;
  String get _contactRelationship => AppState.primaryContact?.relationship ?? MockData.contactRelationship;
  String get _contactPhone => AppState.primaryContact?.phone ?? MockData.contactPhone;

  /// Pre-written text for SMS messages to contacts.
  String get _smsMessage =>
      'EMERGENCY from CardioGuard: ${_args.title} for ${MockData.wearerName} at ${Formatters.clock(_raisedAt)}. '
      '${_args.detail} Please check on him or call 911.';

  Future<void> _run(Future<bool> Function(EmergencyContact c) action) async {
    final primary = AppState.primaryContact;
    if (primary == null) {
      _otherContacts(); // no contacts saved: the sheet explains how to add them
      return;
    }
    final ok = await action(primary);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the phone app on this device.")),
      );
    }
  }

  void _callPrimary() => _run(ContactActions.call);
  void _textPrimary() => _run((c) => ContactActions.text(c, _smsMessage));
  void _otherContacts() => showContactPicker(context, smsMessage: _smsMessage);

  Future<void> _toggleMute() async {
    if (_muted) {
      await AlarmService.unmute();
    } else {
      await AlarmService.mute();
    }
    if (mounted) setState(() => _muted = AlarmService.isMuted);
  }

  void _acknowledge() {
    AlarmService.stop();
    NotificationService.clear();
    AppState.logEvent('Alert Acknowledged', 'Caregiver acknowledged: ${_args.title.toLowerCase()}.', Severity.info);
    final messenger = ScaffoldMessenger.of(context);
    // Back to the dashboard (it is the first page when "Remember me" opened it).
    Navigator.of(context).popUntil((r) => r.settings.name == AppRoutes.home || r.isFirst);
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
              _DetailRow('Primary contact', '$_contactName ($_contactRelationship)'),
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
                          IconButton(
                            tooltip: _muted ? 'Turn alarm sound on' : 'Mute alarm sound',
                            onPressed: _toggleMute,
                            icon: Icon(
                              _muted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                              color: Colors.white,
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
                      _RedCard(
                        label: 'Primary contact',
                        child: _NameLine('$_contactName · $_contactRelationship', _contactPhone),
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
                        onPressed: _callPrimary,
                        icon: const Icon(Icons.call),
                        label: Text('Call $_contactName'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _OutlineWhiteButton(
                              icon: Icons.sms_outlined,
                              label: 'Text $_contactName'.length > 18 ? 'Send Text' : 'Text $_contactName',
                              onPressed: _textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _OutlineWhiteButton(
                              icon: Icons.contacts_outlined,
                              label: 'Other Contacts',
                              onPressed: _otherContacts,
                            ),
                          ),
                        ],
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

/// White-outlined button on the red background.
class _OutlineWhiteButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _OutlineWhiteButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
