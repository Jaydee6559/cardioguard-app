import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../routes.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import 'emergency_alert_screen.dart';

/// Screen 09 — No Response Detected.
///
/// Shown when the fall countdown runs out. The alert is sent automatically
/// after a few seconds (the wearer may be unable to tap anything); the button
/// sends it straight away.
class NoResponseScreen extends StatefulWidget {
  const NoResponseScreen({super.key});

  @override
  State<NoResponseScreen> createState() => _NoResponseScreenState();
}

class _NoResponseScreenState extends State<NoResponseScreen> {
  static const _autoSendSeconds = 5;
  int _secondsLeft = _autoSendSeconds;
  Timer? _timer;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    AlarmService.start(); // keeps ringing from the fall check
    NotificationService.showEmergency(
      'No response from ${MockData.wearerName.split(' ').first}',
      'Sending an emergency alert now.',
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _send();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _send() {
    if (_sent) return;
    _sent = true;
    _timer?.cancel();
    Navigator.of(context).pushReplacementNamed(AppRoutes.emergencyAlert, arguments: EmergencyAlertArgs.noResponse);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.emergency,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergency.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Response Detected',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Emergency alert will be sent to the caregiver immediately.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15.5, color: AppColors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 260,
                    child: FilledButton(
                      onPressed: _send,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
                      child: const Text('Send Emergency Alert'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Sending automatically in ${_secondsLeft}s',
                    style: const TextStyle(color: AppColors.textFaint, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
