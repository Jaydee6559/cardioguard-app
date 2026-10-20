import 'package:flutter/material.dart';

import '../services/ble_service.dart';
import '../services/arduino_protocol.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_card.dart';

class VitalsScreen extends StatelessWidget {
  const VitalsScreen({super.key});

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
            const ScreenHeader(
              kicker: 'Monitoring data',
              title: 'Live Sensor Readings',
            ),
            const SizedBox(height: 18),
            _ReadingCard(
              title: 'Heart Rate',
              value: ble.heartRate == null
                  ? 'Unavailable'
                  : '${ble.heartRate} BPM',
              receivedAt: ble.heartRateReceivedAt,
              connected: ble.isConnected,
              icon: Icons.favorite,
            ),
            const SizedBox(height: 12),
            _ReadingCard(
              title: 'Acceleration',
              value: ble.accelerationG == null
                  ? 'Unavailable'
                  : '${ble.accelerationG!.toStringAsFixed(2)} g',
              receivedAt: ble.accelerationReceivedAt,
              connected: ble.isConnected,
              icon: Icons.speed,
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CardLabel('Arduino state'),
                  const SizedBox(height: 6),
                  Text(
                    switch (ble.wearableState) {
                      WearableState.normal => 'Normal',
                      WearableState.fallPending =>
                        'Possible fall · waiting for Arduino outcome',
                      WearableState.emergency => 'Emergency',
                      null => 'Unavailable',
                    },
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: switch (ble.wearableState) {
                        WearableState.normal => AppColors.success,
                        WearableState.fallPending => AppColors.warning,
                        WearableState.emergency => AppColors.emergency,
                        null => AppColors.textMuted,
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ble.isConnected
                        ? 'State is reported by the Arduino.'
                        : 'Disconnected · state may be stale.',
                    style: TextStyle(color: AppColors.textFaint, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Only readings received from the connected Arduino are shown. Historical charts and SpO₂ are not provided by this device protocol.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textFaint, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.title,
    required this.value,
    required this.receivedAt,
    required this.connected,
    required this.icon,
  });

  final String title;
  final String value;
  final DateTime? receivedAt;
  final bool connected;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final stale =
        receivedAt != null &&
        (!connected ||
            DateTime.now().difference(receivedAt!) >
                const Duration(seconds: 30));
    return SectionCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardLabel(title),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  receivedAt == null
                      ? 'No reading received'
                      : 'Received ${Formatters.date(receivedAt!)} at ${Formatters.clock(receivedAt!)}'
                            '${stale ? ' · stale while disconnected' : ' · live connection'}',
                  style: TextStyle(
                    color: stale ? AppColors.warning : AppColors.textFaint,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
