import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/mock_data.dart';
import '../models/account.dart';
import '../models/emergency_contact.dart';
import '../routes.dart';
import '../theme.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_card.dart';
import '../widgets/settings_rows.dart';

/// Screen 05 — Profile & Settings (Settings tab).
///
/// The profile shows the signed-in account. Alert switches and contacts are
/// saved on the phone. Wearer details are still sample data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Loaded from the phone; every change is saved straight away.
  bool _fallAlerts = AppState.fallAlerts;
  bool _heartRateAlerts = AppState.heartRateAlerts;
  bool _disconnectAlerts = AppState.disconnectAlerts;

  /// Turning off fall alerts is risky, so ask first.
  Future<void> _setFallAlerts(bool on) async {
    if (on) {
      setState(() => _fallAlerts = true);
      await AppState.setFallAlerts(true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 32),
        title: const Text('Turn off fall alerts?'),
        content: const Text(
          "You won't be alerted if the device detects a fall. The wearer's device will still sound its buzzer.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep on')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _fallAlerts = false);
      await AppState.setFallAlerts(false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will stop receiving alerts on this phone until you sign in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final navigator = Navigator.of(context);
      await AppState.signOut();
      navigator.pushNamedAndRemoveUntil(AppRoutes.signIn, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const ScreenHeader(kicker: 'Account', title: 'Profile & Settings'),
          const SizedBox(height: 18),

          // Caregiver profile (the signed-in account)
          ValueListenableBuilder<Account?>(
            valueListenable: AppState.account,
            builder: (context, account, _) => _ProfileCard(account),
          ),
          const SizedBox(height: 14),

          // Wearer information
          const SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardLabel('Wearer information'),
                SizedBox(height: 8),
                InfoRow('Name', MockData.wearerName),
                InfoRow('Age', '${MockData.wearerAge}'),
                InfoRow('Condition', MockData.wearerCondition),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Alert preferences
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardLabel('Alert preferences'),
                const SizedBox(height: 6),
                SwitchRow(label: 'Fall detection alerts', value: _fallAlerts, onChanged: _setFallAlerts),
                SwitchRow(
                  label: 'Abnormal heart rate',
                  value: _heartRateAlerts,
                  onChanged: (v) {
                    setState(() => _heartRateAlerts = v);
                    AppState.setHeartRateAlerts(v);
                  },
                ),
                SwitchRow(
                  label: 'Device disconnect',
                  subtitle: 'Notify me when the wearable loses Bluetooth',
                  value: _disconnectAlerts,
                  onChanged: (v) {
                    setState(() => _disconnectAlerts = v);
                    AppState.setDisconnectAlerts(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Links to the Contacts and Device pages
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Column(
              children: [
                ValueListenableBuilder<List<EmergencyContact>>(
                  valueListenable: AppState.contacts,
                  builder: (context, contacts, _) => NavRow(
                    icon: Icons.contact_phone_outlined,
                    label: 'Emergency contacts',
                    trailing: Text(
                      '${contacts.length} ${contacts.length == 1 ? 'contact' : 'contacts'}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                    ),
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.contacts),
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                NavRow(
                  icon: Icons.watch_outlined,
                  label: 'Device & sensors',
                  trailing: MockData.deviceConnected
                      ? const _ConnectedText()
                      : const Text('Offline', style: TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.device),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          OutlinedButton(
            onPressed: _signOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

/// Green "● Connected" text for the Device & sensors row.
class _ConnectedText extends StatelessWidget {
  const _ConnectedText();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        const Text(
          'Connected',
          style: TextStyle(color: AppColors.success, fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Avatar with initials, name, email and relationship.
class _ProfileCard extends StatelessWidget {
  final Account? account;
  const _ProfileCard(this.account);

  @override
  Widget build(BuildContext context) {
    final name = account?.name ?? MockData.caregiverName;
    final email = account?.email ?? MockData.caregiverEmail;
    final relationship = account?.relationship ?? '';
    final role = relationship.isEmpty ? 'Caregiver' : '$relationship · Caregiver';
    return SectionCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.infoBg,
            child: Text(
              account?.initials ?? 'MS',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(email, style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
                Text(role, style: const TextStyle(color: AppColors.textFaint, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
