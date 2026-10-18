import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../routes.dart';
import '../theme.dart';
import 'emergency_alert_screen.dart';

/// Screen 08 — Possible Fall Detected.
///
/// Counts down from 15 s. The wearer can answer I'M OK (cancel) or
/// NEED HELP (escalate now). If the timer runs out, No Response opens.
/// The Back button is blocked so the check can't be dismissed by accident.
class FallDetectedScreen extends StatefulWidget {
  const FallDetectedScreen({super.key});

  @override
  State<FallDetectedScreen> createState() => _FallDetectedScreenState();
}

class _FallDetectedScreenState extends State<FallDetectedScreen> {
  static const _total = MockData.fallCountdownSeconds;
  int _secondsLeft = _total;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
      Navigator.of(context).pushReplacementNamed(AppRoutes.noResponse);
      return;
    }
    setState(() => _secondsLeft--);
  }

  void _imOk() {
    _timer?.cancel();
    final messenger = ScaffoldMessenger.of(context); // grab before leaving the page
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text("Glad you're OK. The event was recorded.")),
    );
  }

  void _needHelp() {
    _timer?.cancel();
    Navigator.of(context).pushReplacementNamed(AppRoutes.emergencyAlert, arguments: EmergencyAlertArgs.helpRequested);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                const Text(
                  'Possible Fall Detected',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                const Text(
                  'The device detected a sudden impact. Please confirm your condition.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.5, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 32),
                const Text(
                  'RESPONDING IN',
                  style: TextStyle(fontSize: 13, letterSpacing: 1.4, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_secondsLeft}s',
                  style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: _secondsLeft / _total),
                      duration: const Duration(milliseconds: 900),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        color: AppColors.warning,
                        backgroundColor: const Color(0xFFFDE68A),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                _BigButton(label: "I'M OK", color: AppColors.success, onPressed: _imOk),
                const SizedBox(height: 14),
                _BigButton(label: 'NEED HELP', color: AppColors.emergency, onPressed: _needHelp),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Extra-large button: easy to hit for someone who may be shaken or on the floor.
class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _BigButton({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size.fromHeight(64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
      child: Text(label),
    );
  }
}
