import 'package:flutter/material.dart';

import '../models/alert_event.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import 'severity_badge.dart';

/// One item in the Alerts & Events list.
class EventCard extends StatelessWidget {
  final AlertEvent event;
  final VoidCallback? onTap;

  const EventCard(this.event, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SeverityDot(event.severity),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SeverityBadge(event.severity),
                ],
              ),
              const SizedBox(height: 6),
              Text(event.description, style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.35)),
              const SizedBox(height: 8),
              Text(Formatters.eventStamp(event.time), style: const TextStyle(color: AppColors.textFaint, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
