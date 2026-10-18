import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../utils/validators.dart';
import '../widgets/auth_widgets.dart';

/// Screen 01b — Create Account.
///
/// Saves the account on this phone (password stored as a hash), then
/// returns the email to Sign In, which fills it in.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  static const relationships = [
    'Daughter',
    'Son',
    'Spouse',
    'Grandchild',
    'Sibling',
    'Nurse / Caregiver',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _otherRelationship = TextEditingController(); // used when "Other" is picked
  String? _relationship;

  bool get _isOther => _relationship == 'Other';

  /// The relationship to save: the typed text when "Other" is chosen.
  String get relationshipValue => _isOther ? _otherRelationship.text.trim() : (_relationship ?? '');
  bool _submitting = false;
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = _showTerms;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _otherRelationship.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final error = await AppState.createAccount(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      relationship: relationshipValue,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop(_email.text.trim());
  }

  void _showTerms() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms & Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'CardioGuard is a student prototype for monitoring and alerts. It is not a medical device '
            'and does not replace professional medical care.\n\n'
            'Your account details, the wearer\'s readings and your emergency contacts are stored only on '
            'this phone. Nothing is sent to an online server.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Back link, pinned to the top-left like the prototype.
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Back to Sign In'),
                ),
              ),
            ),
            Expanded(
              child: CenteredScrollPage(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Set up your caregiver account',
                      style: TextStyle(fontSize: 15, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    AuthCard(
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LabeledField(
                                label: 'Full name',
                                controller: _name,
                                hint: 'e.g. Maria Santos',
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                validator: Validators.fullName,
                              ),
                              const SizedBox(height: 16),
                              LabeledField(
                                label: 'Email',
                                controller: _email,
                                hint: 'you@example.com',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                // Valid format, and not already registered on this phone.
                                validator: (v) =>
                                    Validators.email(v) ??
                                    (AppState.hasAccount(v ?? '') ? 'An account with this email already exists' : null),
                              ),
                              const SizedBox(height: 16),
                              PasswordField(
                                label: 'Password',
                                controller: _password,
                                hint: 'Create a password',
                                helperText: 'At least 8 characters',
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.newPassword],
                                validator: Validators.newPassword,
                              ),
                              const SizedBox(height: 16),
                              PasswordField(
                                label: 'Confirm password',
                                controller: _confirm,
                                hint: 'Type the password again',
                                textInputAction: TextInputAction.done,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Confirm your password';
                                  if (v != _password.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const FieldLabel('Relationship to wearer'),
                              DropdownButtonFormField<String>(
                                initialValue: _relationship,
                                isExpanded: true,
                                hint: const Text('Select relationship',
                                    style: TextStyle(color: AppColors.textFaint)),
                                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                borderRadius: BorderRadius.circular(12),
                                items: [
                                  for (final r in relationships) DropdownMenuItem(value: r, child: Text(r)),
                                ],
                                onChanged: (v) => setState(() => _relationship = v),
                                validator: (v) => v == null ? 'Select your relationship to the wearer' : null,
                              ),
                              // Extra text box, shown only when "Other" is selected.
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                alignment: Alignment.topCenter,
                                child: _isOther
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: TextFormField(
                                          controller: _otherRelationship,
                                          autofocus: true,
                                          textCapitalization: TextCapitalization.sentences,
                                          textInputAction: TextInputAction.done,
                                          decoration: const InputDecoration(
                                            hintText: 'Please specify (e.g. Neighbour, Friend)',
                                          ),
                                          validator: (v) => _isOther && (v == null || v.trim().isEmpty)
                                              ? 'Please type your relationship to the wearer'
                                              : null,
                                        ),
                                      )
                                    : const SizedBox(width: double.infinity),
                              ),
                              const SizedBox(height: 16),
                              _TermsCheckbox(onTermsTap: _termsTap),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _submitting ? null : _createAccount,
                                child: _submitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                      )
                                    : const Text('Create Account'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AuthFooterLink(
                      prompt: 'Already have an account?',
                      action: 'Sign In',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "I agree to the Terms & Privacy Policy" — must be ticked to continue.
/// Built as a FormField so it shows its error with the other fields.
class _TermsCheckbox extends StatelessWidget {
  final TapGestureRecognizer onTermsTap;
  const _TermsCheckbox({required this.onTermsTap});

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: false,
      validator: (v) => v == true ? null : 'Please agree to the Terms & Privacy Policy',
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: state.value ?? false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) => state.didChange(v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: const TextStyle(color: AppColors.textLabel, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Terms & Privacy Policy',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        recognizer: onTermsTap,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                state.errorText ?? '',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
