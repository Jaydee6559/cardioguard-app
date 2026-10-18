import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_card.dart';

/// TEMPORARY tab content for Vitals, Alerts and Settings until those screens
/// are built. Delete this file once all three are done.
class ComingSoonTab extends StatelessWidget {
  final String kicker;
  final String title;
  final IconData icon;
  final bool showSignOut;

  const ComingSoonTab({
    super.key,
    required this.kicker,
    required this.title,
    required this.icon,
    this.showSignOut = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          ScreenHeader(kicker: kicker, title: title),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              children: [
                Icon(icon, size: 40, color: AppColors.textFaint),
                const SizedBox(height: 12),
                const Text('Coming next', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLabel)),
                const SizedBox(height: 4),
                const Text(
                  'This screen will be built in the next step.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (showSignOut) ...[
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.signIn, (_) => false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        ],
      ),
    );
  }
}
