import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../widgets/screen_header.dart';
import '../widgets/vital_chart_card.dart';

enum VitalsRange { daily, weekly }

/// Screen 03 — Vital Signs History (Vitals tab).
///
/// Daily shows today's readings by hour; Weekly shows the last 7 days'
/// averages. UI only: data comes from [MockData].
class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  VitalsRange _range = VitalsRange.daily;

  bool get _daily => _range == VitalsRange.daily;

  /// Axis label for a point: "14:00" (Daily) or "Mon" (Weekly).
  String _xLabel(double x) {
    if (_daily) return Formatters.hour(x);
    final day = DateTime.now().subtract(Duration(days: 6 - x.round()));
    return Formatters.weekday(day);
  }

  String _caption(String normalRange) {
    final today = DateTime.now();
    if (_daily) return '${Formatters.date(today)} — Normal range: $normalRange';
    final start = today.subtract(const Duration(days: 6));
    return '${Formatters.shortDate(start)} – ${Formatters.shortDate(today)} (daily averages) — Normal: $normalRange';
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          ScreenHeader(
            kicker: 'Monitoring data',
            title: 'Vital Signs History',
            trailing: SegmentedButton<VitalsRange>(
              segments: const [
                ButtonSegment(value: VitalsRange.daily, label: Text('Daily')),
                ButtonSegment(value: VitalsRange.weekly, label: Text('Weekly')),
              ],
              selected: {_range},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _range = s.first),
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                selectedBackgroundColor: AppColors.surface,
                selectedForegroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.textMuted,
                backgroundColor: AppColors.segmentBg,
                side: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          VitalChartCard(
            label: 'Heart Rate',
            icon: Icons.favorite,
            color: const Color(0xFFEF4444),
            unit: 'BPM',
            points: _daily ? MockData.dailyHeartRate : MockData.weeklyHeartRate,
            minY: 50,
            maxY: 90,
            yInterval: 10,
            normalLow: MockData.heartRateNormalLow,
            normalHigh: MockData.heartRateNormalHigh,
            minX: _daily ? 6 : 0,
            maxX: _daily ? 20 : 6,
            xInterval: _daily ? 4 : 1,
            xLabel: _xLabel,
            caption: _caption('60–100 BPM'),
          ),
          const SizedBox(height: 14),
          VitalChartCard(
            label: 'SpO₂ Saturation',
            icon: Icons.water_drop,
            color: const Color(0xFF3B82F6),
            unit: '%',
            points: _daily ? MockData.dailySpo2 : MockData.weeklySpo2,
            minY: 90,
            maxY: 100,
            yInterval: 2,
            normalLow: MockData.spo2NormalLow,
            normalHigh: MockData.spo2NormalHigh,
            minX: _daily ? 6 : 0,
            maxX: _daily ? 20 : 6,
            xInterval: _daily ? 4 : 1,
            xLabel: _xLabel,
            caption: _caption('95–100%'),
          ),
          const SizedBox(height: 18),
          Text(
            'This is monitoring data only. Consult a physician for medical advice.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textFaint, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
