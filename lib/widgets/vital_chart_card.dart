import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/alert_event.dart';
import '../theme.dart';
import 'section_card.dart';

/// A Vitals card: label + latest value on top, a line chart, then a caption.
///
/// The normal range is shaded green behind the line, so readings outside it
/// stand out without reading the axis.
class VitalChartCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String unit;
  final List<ChartPoint> points;
  final double minY;
  final double maxY;
  final double yInterval;
  final double normalLow;
  final double normalHigh;
  final double minX;
  final double maxX;
  final double xInterval;
  final String Function(double x) xLabel;
  final String caption;

  const VitalChartCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.unit,
    required this.points,
    required this.minY,
    required this.maxY,
    required this.yInterval,
    required this.normalLow,
    required this.normalHigh,
    required this.minX,
    required this.maxX,
    required this.xInterval,
    required this.xLabel,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final values = points.map((p) => p.y).toList();
    final latest = values.isEmpty ? null : values.last;
    final low = values.isEmpty ? 0.0 : values.reduce(math.min);
    final high = values.isEmpty ? 0.0 : values.reduce(math.max);
    final avg = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardLabel(label),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          latest == null ? '—' : latest.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 4),
                        Text(unit, style: const TextStyle(fontSize: 14, color: AppColors.textFaint)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(icon, color: color, size: 26),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: points.isEmpty
                ? const Center(child: Text('No readings yet', style: TextStyle(color: AppColors.textFaint)))
                : LineChart(_chartData()),
          ),
          const SizedBox(height: 12),
          if (values.isNotEmpty)
            Row(
              children: [
                _Stat('Min', low, unit),
                _Stat('Avg', avg, unit),
                _Stat('Max', high, unit),
              ],
            ),
          const SizedBox(height: 10),
          Text(caption, style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
        ],
      ),
    );
  }

  LineChartData _chartData() {
    const axisStyle = TextStyle(color: AppColors.textFaint, fontSize: 11);
    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      clipData: const FlClipData.all(),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: yInterval,
        verticalInterval: xInterval,
        getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFEDF0F4), strokeWidth: 1),
        getDrawingVerticalLine: (_) => const FlLine(color: Color(0xFFF3F5F8), strokeWidth: 1, dashArray: [4, 4]),
      ),
      rangeAnnotations: RangeAnnotations(
        horizontalRangeAnnotations: [
          HorizontalRangeAnnotation(
            y1: normalLow.clamp(minY, maxY).toDouble(),
            y2: normalHigh.clamp(minY, maxY).toDouble(),
            color: AppColors.success.withValues(alpha: 0.07),
          ),
        ],
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: yInterval,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(value.toStringAsFixed(0), style: axisStyle, textAlign: TextAlign.right),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: xInterval,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(xLabel(value), style: axisStyle),
            ),
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.textPrimary,
          getTooltipItems: (spots) => [
            for (final s in spots)
              LineTooltipItem(
                '${xLabel(s.x)}\n${s.y.toStringAsFixed(0)} $unit',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
              ),
          ],
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [for (final p in points) FlSpot(p.x, p.y)],
          isCurved: true,
          preventCurveOverShooting: true,
          color: color,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
        ),
      ],
    );
  }
}

/// "Min 67 BPM" style figure under the chart.
class _Stat extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  const _Stat(this.label, this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
          Text(
            '${value.toStringAsFixed(0)} $unit',
            style: const TextStyle(color: AppColors.textLabel, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
