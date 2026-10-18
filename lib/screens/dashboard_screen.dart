import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/mock_data.dart';
import '../models/alert_event.dart';
import '../routes.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';
import '../widgets/vital_card.dart';
import 'emergency_alert_screen.dart';

/// Screen 02 — Monitoring Dashboard (Home tab).
///
/// UI only: readings come from [MockData]. Simulate Fall and Send SOS open
/// the emergency screens so the whole flow can be demonstrated.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _simulateFall(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.fallDetected);
  }

  Future<void> _sendSos(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.sos, color: AppColors.emergency, size: 32),
        title: const Text('Send SOS?'),
        content: const Text('This raises an emergency alert and notifies your emergency contacts.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emergency,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      AppState.logEvent('Manual SOS', 'SOS sent from the dashboard.', Severity.emergency);
      Navigator.of(context).pushNamed(AppRoutes.emergencyAlert, arguments: EmergencyAlertArgs.sos);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          ScreenHeader(
            kicker: 'Monitoring',
            title: MockData.wearerName,
            trailing: MockData.deviceConnected
                ? StatusPill(text: 'Connected', color: AppColors.success)
                : StatusPill(text: 'Disconnected', color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          const _OverallStatusCard(),
          const SizedBox(height: 14),
          _TileRow(
            left: VitalCard(
              label: 'Heart Rate',
              icon: Icons.favorite,
              iconColor: AppColors.emergency,
              iconTile: true,
              value: '${MockData.heartRate}',
              unit: 'BPM',
              status: 'Normal',
              statusColor: AppColors.success,
            ),
            right: VitalCard(
              label: 'SpO₂',
              icon: Icons.water_drop,
              iconColor: AppColors.primary,
              iconTile: true,
              value: '${MockData.spo2}',
              unit: '%',
              status: 'Normal',
              statusColor: AppColors.success,
            ),
          ),
          const SizedBox(height: 14),
          _TileRow(
            left: VitalCard(
              label: 'Movement',
              icon: Icons.monitor_heart_outlined,
              iconColor: AppColors.textMuted,
              value: MockData.movement,
              status: MockData.movementDetail,
            ),
            right: VitalCard(
              label: 'Battery',
              icon: Icons.battery_5_bar_outlined,
              iconColor: AppColors.textMuted,
              value: '${MockData.battery}%',
              progress: MockData.battery / 100,
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardLabel('Emergency', color: AppColors.emergency),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _simulateFall(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emergency,
                          side: BorderSide(color: AppColors.emergency.withValues(alpha: 0.3)),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Simulate Fall'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _sendSos(context),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
                        child: const Text('Send SOS'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "OVERALL STATUS / Normal / Last updated" card with the green shield.
class _OverallStatusCard extends StatelessWidget {
  const _OverallStatusCard();

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardLabel('Overall status'),
                const SizedBox(height: 6),
                Text(
                  'Normal',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.success),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last updated: ${Formatters.clock(DateTime.now())} today',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 13.5),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
            child: Icon(Icons.verified_user_outlined, color: AppColors.success, size: 28),
          ),
        ],
      ),
    );
  }
}

/// Two tiles side by side with equal height.
class _TileRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _TileRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 14),
          Expanded(child: right),
        ],
      ),
    );
  }
}
