import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/mock_data.dart';
import '../models/alert_event.dart';
import '../routes.dart';
import '../services/arduino_protocol.dart';
import '../services/ble_service.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';
import '../widgets/vital_card.dart';
import 'emergency_alert_screen.dart';

/// Screen 02 — Monitoring Dashboard (Home tab).
///
/// Sensor values and emergency state come from the shared Arduino BLE service.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _sendSos(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.sos, color: AppColors.emergency, size: 32),
        title: const Text('Send SOS?'),
        content: const Text(
          'This raises an emergency alert and notifies your emergency contacts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
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
      AppState.logEvent(
        'Caregiver SOS',
        'A caregiver raised an alert from CardioGuard.',
        Severity.emergency,
      );
      Navigator.of(context).pushNamed(
        AppRoutes.emergencyAlert,
        arguments: EmergencyAlertArgs.caregiverSOS,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final ble = BleService.instance;
    return AnimatedBuilder(
      animation: ble,
      builder: (context, _) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            ScreenHeader(
              kicker: 'Monitoring',
              title: MockData.wearerName,
              trailing: ble.isConnected
                  ? StatusPill(text: 'Connected', color: AppColors.success)
                  : StatusPill(
                      text: switch (ble.connectionStatus) {
                        BleConnectionStatus.scanning => 'Scanning',
                        BleConnectionStatus.connecting => 'Connecting',
                        _ => 'Disconnected',
                      },
                      color: AppColors.textMuted,
                    ),
            ),
            const SizedBox(height: 18),
            _OverallStatusCard(ble),
            const SizedBox(height: 14),
            _TileRow(
              left: VitalCard(
                label: 'Heart Rate',
                icon: Icons.favorite,
                iconColor: AppColors.emergency,
                iconTile: true,
                value: ble.heartRate?.toString() ?? '—',
                unit: 'BPM',
                status: ble.heartRate == null
                    ? 'Unavailable'
                    : ble.isReadingStale(ble.heartRateReceivedAt)
                    ? 'Stale'
                    : 'Live',
                statusColor: ble.heartRate == null
                    ? AppColors.textMuted
                    : ble.isReadingStale(ble.heartRateReceivedAt)
                    ? AppColors.warning
                    : AppColors.success,
              ),
              right: VitalCard(
                label: 'Acceleration',
                icon: Icons.speed,
                iconColor: AppColors.textMuted,
                iconTile: true,
                value: ble.accelerationG?.toStringAsFixed(2) ?? '—',
                unit: 'g',
                status: ble.accelerationG == null
                    ? 'Unavailable'
                    : ble.isReadingStale(ble.accelerationReceivedAt)
                    ? 'Stale'
                    : 'Live',
                statusColor: ble.accelerationG == null
                    ? AppColors.textMuted
                    : ble.isReadingStale(ble.accelerationReceivedAt)
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardLabel('Caregiver alert', color: AppColors.emergency),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _sendSos(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emergency,
                      ),
                      child: const Text('Send caregiver SOS'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "OVERALL STATUS / Normal / Last updated" card with the green shield.
class _OverallStatusCard extends StatelessWidget {
  const _OverallStatusCard(this.ble);

  final BleService ble;

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
                  _stateLabel,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: _stateColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ble.stateReceivedAt == null
                      ? 'No Arduino state received'
                      : 'Last reported: ${Formatters.clock(ble.stateReceivedAt!)}',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 13.5),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _stateColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: _stateColor,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  String get _stateLabel {
    final prefix = ble.isReadingStale(ble.stateReceivedAt)
        ? 'Last known: '
        : '';
    return switch (ble.wearableState) {
      WearableState.normal => '${prefix}Normal',
      WearableState.fallPending => '${prefix}Possible fall',
      WearableState.emergency => '${prefix}Emergency',
      null => ble.isConnected ? 'Awaiting device' : 'Unavailable',
    };
  }

  Color get _stateColor => switch (ble.wearableState) {
    WearableState.normal => AppColors.success,
    WearableState.fallPending => AppColors.warning,
    WearableState.emergency => AppColors.emergency,
    null => AppColors.textMuted,
  };
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
