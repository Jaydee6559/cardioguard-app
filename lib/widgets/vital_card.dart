import 'package:flutter/material.dart';

import '../theme.dart';
import 'section_card.dart';

/// One reading tile on the dashboard: Heart Rate, SpO2, Movement, Battery.
///
/// Two layouts:
///  * with [iconTile]   – big coloured icon box on top (Heart Rate, SpO2)
///  * without           – small icon beside the label (Movement, Battery)
class VitalCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String? unit;
  final String? status; // e.g. "Normal", "Resting"
  final Color statusColor;
  final double? progress; // 0..1, draws a bar (battery)
  final bool iconTile;

  const VitalCard({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    this.unit,
    this.status,
    this.statusColor = AppColors.textMuted,
    this.progress,
    this.iconTile = false,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (iconTile) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 14),
            CardLabel(label),
          ] else
            CardLabel(label, icon: icon),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: iconTile ? 32 : 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(unit!, style: const TextStyle(fontSize: 14, color: AppColors.textFaint)),
              ],
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0).toDouble(),
                minHeight: 7,
                color: progress! > 0.2 ? AppColors.success : AppColors.emergency,
                backgroundColor: const Color(0xFFEFF2F6),
              ),
            ),
          ],
          if (status != null) ...[
            const SizedBox(height: 6),
            Text(status!, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13.5)),
          ],
        ],
      ),
    );
  }
}
