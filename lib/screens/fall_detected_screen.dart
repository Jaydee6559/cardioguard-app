import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/mock_data.dart';
import '../models/alert_event.dart';
import '../routes.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/contact_picker_sheet.dart';
import 'emergency_alert_screen.dart';

/// Screen 08 — Possible Fall Detected (caregiver's view).
///
/// The WEARER answers on the device (buzzer + acknowledge button). The
/// caregiver sees the countdown: "Waiting for Roberto to respond… 9s".
/// If Roberto doesn't respond in time, No Response opens. The caregiver can
/// also raise the alert straight away or contact someone.
///
/// Alarm sound + vibration and a phone notification start here and keep
/// going until someone responds. Back is blocked so it can't be dismissed.
class FallDetectedScreen extends StatefulWidget {
  const FallDetectedScreen({super.key});

  @override
  State<FallDetectedScreen> createState() => _FallDetectedScreenState();
}

class _FallDetectedScreenState extends State<FallDetectedScreen> {
  static const _total = MockData.fallCountdownSeconds;
  static final _firstName = MockData.wearerName.split(' ').first;

  int _secondsLeft = _total;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AppState.logEvent('Possible Fall Detected', 'Fall check started (simulated from the dashboard).', Severity.emergency);
    AlarmService.start();
    NotificationService.showEmergency(
      'Possible fall detected',
      'Waiting for $_firstName to respond on the device. Open CardioGuard.',
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_secondsLeft <= 1) {
      _timer?.cancel();
      AppState.logEvent('No Response Detected', 'Wearer did not respond within $_total s after fall.', Severity.emergency);
      // Alarm keeps ringing into No Response and Emergency Alert.
      Navigator.of(context).pushReplacementNamed(AppRoutes.noResponse);
      return;
    }
    setState(() => _secondsLeft--);
  }

  /// DEMO ONLY: pretends Roberto pressed the acknowledge button on his
  /// device. Replaced by the real button press once the Arduino is connected.
  void _wearerIsOk() {
    _timer?.cancel();
    AlarmService.stop();
    NotificationService.clear();
    AppState.logEvent('Post-fall Response', "Wearer confirmed 'I'm OK' after fall detection.", Severity.info);
    final messenger = ScaffoldMessenger.of(context); // grab before leaving the page
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text("$_firstName pressed I'M OK on the device. The event was recorded.")),
    );
  }

  /// Caregiver doesn't want to wait: raise the emergency now.
  void _raiseAlertNow() {
    _timer?.cancel();
    AppState.logEvent('Alert Raised by Caregiver', 'Caregiver escalated the fall check before the countdown ended.', Severity.emergency);
    Navigator.of(context).pushReplacementNamed(AppRoutes.emergencyAlert, arguments: EmergencyAlertArgs.caregiverRaised);
  }

  void _contactSomeone() {
    showContactPicker(
      context,
      smsMessage: 'CardioGuard: a possible fall was detected for ${MockData.wearerName}. '
          'Waiting for him to respond. Please check on him if you can.',
    );
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final progress = _secondsLeft / _total;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          // Fills the screen on normal phones, scrolls on small ones.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: AppColors.warning.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 24),
                Text(
                  'Possible Fall Detected',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Text(
                  "$_firstName's device detected a sudden impact.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.5, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 28),

                // Waiting card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Waiting for $_firstName to respond…',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLabel),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_secondsLeft}s',
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: progress),
                          duration: const Duration(milliseconds: 900),
                          builder: (context, value, _) => LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            color: AppColors.warning,
                            backgroundColor: AppColors.warningTrack,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$_firstName can press the button on his device to say he\'s OK. '
                        'If there is no answer, an emergency alert is raised automatically.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Caregiver actions
                FilledButton.icon(
                  onPressed: _raiseAlertNow,
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('Raise Alert Now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emergency,
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _contactSomeone,
                  icon: const Icon(Icons.contact_phone_outlined),
                  label: const Text('Call or Text a Contact'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 6),
                // Demo-only: stands in for the wearer's acknowledge button.
                TextButton(
                  onPressed: _wearerIsOk,
                  style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                  child: Text("Demo: $_firstName pressed I'M OK"),
                ),
              ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
