import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme.dart';
import '../widgets/auth_widgets.dart';

/// TEMPORARY page shown after signing in, until the real dashboard
/// (Home shell + bottom navigation) is built. Delete it then.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 56),
                const SizedBox(height: 16),
                const Text(
                  "You're signed in",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The monitoring dashboard is the next screen to build.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.signIn, (_) => false),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
