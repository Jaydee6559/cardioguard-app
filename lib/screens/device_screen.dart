import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_card.dart';
import '../widgets/settings_rows.dart';

/// Screen 07 — Device & Sensors (opened from Settings).
///
/// Health check of the wearable's parts. UI only: values come from
/// [MockData]; Test buzzer and Reconnect will talk to the Arduino later.
class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  void _notYet(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what will work once the wearable is connected.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final battery = MockData.battery;
    return Scaffold(
      appBar: const SubpageAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const ScreenHeader(kicker: 'Status', title: 'Device & Sensors'),
          const SizedBox(height: 18),

          // Battery
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(child: CardLabel('Battery level')),
                    Icon(Icons.battery_5_bar_outlined, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$battery',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 4),
                    const Text('%', style: TextStyle(fontSize: 16, color: AppColors.textFaint)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: battery / 100,
                    minHeight: 9,
                    color: battery > 20 ? AppColors.success : AppColors.emergency,
                    backgroundColor: const Color(0xFFEFF2F6),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Est. ${MockData.batteryHoursLeft} hours remaining',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 13.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // One row per part
          for (final s in MockData.sensors) ...[
            _SensorRow(s),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),

          // Last sync
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardLabel('Last synchronized'),
                const SizedBox(height: 6),
                Text(
                  'Today, ${Formatters.clock(DateTime.now())}',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(Formatters.date(DateTime.now()), style: const TextStyle(color: AppColors.textFaint, fontSize: 13.5)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Actions (wired to the Arduino later)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _notYet(context, 'Test buzzer'),
                  icon: const Icon(Icons.volume_up_outlined),
                  label: const Text('Test buzzer'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _notYet(context, 'Reconnect'),
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Reconnect'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Arduino Uno R3 / Main Controller ........ ● Connected"
class _SensorRow extends StatelessWidget {
  final SensorInfo sensor;
  const _SensorRow(this.sensor);

  @override
  Widget build(BuildContext context) {
    final color = sensor.ok ? AppColors.success : AppColors.emergency;
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensor.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(sensor.role, style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
              ],
            ),
          ),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(sensor.status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
