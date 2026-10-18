import 'package:flutter/material.dart';

import '../theme.dart';

/// Small grey kicker above a big title, e.g. "MONITORING / Roberto Santos".
/// An optional widget (a chip or button) can sit on the right.
class ScreenHeader extends StatelessWidget {
  final String kicker;
  final String title;
  final Widget? trailing;

  const ScreenHeader({super.key, required this.kicker, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker.toUpperCase(),
                style: const TextStyle(fontSize: 12.5, letterSpacing: 1.4, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
