import 'package:flutter/material.dart';

import '../theme.dart';

/// White rounded card used for every block on the dashboard and settings.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: child,
    );
  }
}

/// Small uppercase grey label inside a card, e.g. "OVERALL STATUS".
class CardLabel extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const CardLabel(this.text, {super.key, this.color = AppColors.textMuted, this.icon});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 12.5, letterSpacing: 1.1, color: color, fontWeight: FontWeight.w500),
    );
    if (icon == null) return label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Flexible(child: label)],
    );
  }
}
