import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_state.dart';
import '../models/emergency_contact.dart';
import '../theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/screen_header.dart';
import '../widgets/settings_rows.dart';

/// Screen 06 — Emergency Contacts (opened from Settings).
///
/// Add, edit, delete and choose the primary contact. Kept in memory
/// ([AppState.contacts]) until storage is added.
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  Future<void> _openForm(BuildContext context, {EmergencyContact? existing, int? index}) async {
    final isFirst = AppState.contacts.value.isEmpty;
    final result = await showModalBottomSheet<EmergencyContact>(
      context: context,
      isScrollControlled: true, // lets the sheet move up with the keyboard
      showDragHandle: true,
      builder: (_) => ContactForm(existing: existing, forcePrimary: isFirst),
    );
    if (result == null) return;
    AppState.saveContact(result, index: index);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existing == null ? '${result.name} added.' : '${result.name} updated.')),
      );
    }
  }

  Future<void> _delete(BuildContext context, EmergencyContact contact, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${contact.name}?'),
        content: Text(
          contact.primary
              ? 'This is your primary contact. The next contact in the list will become primary.'
              : 'They will no longer be contacted in an emergency.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) AppState.deleteContact(index);
  }

  Future<void> _call(BuildContext context, EmergencyContact c) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: c.phone.replaceAll(' ', '')));
    } catch (_) {
      // No dialer available; handled below.
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the phone dialer.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SubpageAppBar(
        action: FilledButton.icon(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 16)),
        ),
      ),
      body: ValueListenableBuilder<List<EmergencyContact>>(
        valueListenable: AppState.contacts,
        builder: (context, contacts, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const ScreenHeader(kicker: 'Management', title: 'Emergency Contacts'),
            const SizedBox(height: 6),
            const Text(
              'The primary contact is shown first on the Emergency Alert screen.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            if (contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.contact_phone_outlined, size: 40, color: AppColors.textFaint),
                    SizedBox(height: 10),
                    Text('No contacts yet', style: TextStyle(color: AppColors.textLabel, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Add at least one person to call in an emergency.',
                        textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              )
            else
              for (var i = 0; i < contacts.length; i++) ...[
                _ContactCard(
                  contact: contacts[i],
                  onCall: () => _call(context, contacts[i]),
                  onEdit: () => _openForm(context, existing: contacts[i], index: i),
                  onDelete: () => _delete(context, contacts[i], i),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactCard({required this.contact, required this.onCall, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  contact.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              if (contact.primary) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: const Text('Primary', style: TextStyle(color: AppColors.primary, fontSize: 12.5)),
                ),
              ],
              const Spacer(),
              IconButton(
                tooltip: 'Call',
                onPressed: onCall,
                icon: const Icon(Icons.call_outlined, color: AppColors.success),
              ),
            ],
          ),
          Text(contact.relationship, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            contact.phone,
            style: const TextStyle(color: AppColors.textLabel, fontSize: 15, letterSpacing: 0.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onEdit, child: const Text('Edit')),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet form to add or edit a contact. Returns the contact on Save.
class ContactForm extends StatefulWidget {
  final EmergencyContact? existing;
  final bool forcePrimary; // the very first contact is always primary

  const ContactForm({super.key, this.existing, this.forcePrimary = false});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _relationship = TextEditingController(text: widget.existing?.relationship);
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '+63 ');
  late bool _primary = widget.forcePrimary || (widget.existing?.primary ?? false);

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Enter a phone number';
    if (digits.length < 10 || digits.length > 13) return 'Enter a valid phone number';
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      EmergencyContact(
        name: _name.text.trim(),
        relationship: _relationship.text.trim(),
        phone: _phone.text.trim(),
        primary: _primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Push the form above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Add contact' : 'Edit contact',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Name',
                controller: _name,
                hint: 'e.g. Dr. Reyes',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: 'Relationship',
                controller: _relationship,
                hint: 'e.g. Son, Physician, Neighbour',
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the relationship' : null,
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: 'Phone number',
                controller: _phone,
                hint: '+63 917 555 0142',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: _validatePhone,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 8),
              SwitchRow(
                label: 'Primary contact',
                subtitle: widget.forcePrimary ? 'Your first contact is always primary' : 'Called first in an emergency',
                value: _primary,
                onChanged: widget.forcePrimary ? (_) {} : (v) => setState(() => _primary = v),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
