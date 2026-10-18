import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../models/emergency_contact.dart';
import '../services/contact_actions.dart';
import '../theme.dart';

/// Bottom sheet listing every emergency contact with Call and Text buttons.
/// [smsMessage] is pre-typed into the text message.
Future<void> showContactPicker(BuildContext context, {required String smsMessage}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ContactPicker(smsMessage: smsMessage),
  );
}

class _ContactPicker extends StatelessWidget {
  final String smsMessage;
  const _ContactPicker({required this.smsMessage});

  Future<void> _run(BuildContext context, Future<bool> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action();
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text("Couldn't open the phone app on this device.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = AppState.contacts.value;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const Text(
              'Contact someone',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Call, or send a text with the alert details already written.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            if (contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No emergency contacts yet. Add them in Settings → Emergency contacts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              for (final c in contacts)
                _PickerRow(
                  contact: c,
                  onCall: () => _run(context, () => ContactActions.call(c)),
                  onText: () => _run(context, () => ContactActions.text(c, smsMessage)),
                ),
          ],
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCall;
  final VoidCallback onText;
  const _PickerRow({required this.contact, required this.onCall, required this.onText});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    if (contact.primary) ...[
                      const SizedBox(width: 6),
                      const Text('· Primary', style: TextStyle(color: AppColors.primary, fontSize: 12.5)),
                    ],
                  ],
                ),
                Text(
                  '${contact.relationship} · ${contact.phone}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Text ${contact.name}',
            onPressed: onText,
            icon: const Icon(Icons.sms_outlined),
          ),
          const SizedBox(width: 4),
          IconButton.filled(
            tooltip: 'Call ${contact.name}',
            onPressed: onCall,
            style: IconButton.styleFrom(backgroundColor: AppColors.success),
            icon: const Icon(Icons.call),
          ),
        ],
      ),
    );
  }
}
