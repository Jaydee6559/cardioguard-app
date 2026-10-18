import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../routes.dart';
import '../theme.dart';
import '../utils/validators.dart';
import '../widgets/auth_widgets.dart';

/// Screen 01 — Sign In.
///
/// Checks the email and password against the accounts saved on this phone.
/// "Remember me" keeps the caregiver signed in after the app is closed.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = false;
  bool _submitting = false;
  String? _error; // "Incorrect password" etc., shown above the button

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await AppState.signIn(_email.text, _password.text, remember: _rememberMe);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  Future<void> _openCreateAccount() async {
    // Create Account returns the new email when it succeeds.
    // (Routes from the routes table can't be typed, so check the result here.)
    final result = await Navigator.of(context).pushNamed(AppRoutes.createAccount);
    if (!mounted || result is! String) return;
    final email = result;
    _email.text = email;
    _password.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created. Sign in to continue.')),
    );
  }

  void _forgotPassword() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: const Text(
          'Accounts are saved only on this phone, so there is no email reset yet. '
          'If you forgot your password, create a new account with a different email.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CenteredScrollPage(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 64),
              const SizedBox(height: 20),
              const Text(
                'CardioGuard',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Caregiver Monitoring Dashboard',
                style: TextStyle(fontSize: 15, color: AppColors.textMuted),
              ),
              const SizedBox(height: 28),
              AuthCard(
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LabeledField(
                          label: 'Email',
                          controller: _email,
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        PasswordField(
                          label: 'Password',
                          controller: _password,
                          hint: 'Enter your password',
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          validator: Validators.password,
                          onFieldSubmitted: (_) => _signIn(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              child: const Text('Remember me', style: TextStyle(color: AppColors.textLabel)),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _forgotPassword,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Forgot Password?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_error != null) ...[
                          _ErrorBox(_error!),
                          const SizedBox(height: 12),
                        ],
                        FilledButton(
                          onPressed: _submitting ? null : _signIn,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('Sign In'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AuthFooterLink(
                prompt: "Don't have an account?",
                action: 'Create one',
                onTap: _openCreateAccount,
              ),
              const SizedBox(height: 16),
              const MedicalDisclaimer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Red message box for sign-in errors ("Incorrect password").
class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.danger, fontSize: 13.5))),
        ],
      ),
    );
  }
}
