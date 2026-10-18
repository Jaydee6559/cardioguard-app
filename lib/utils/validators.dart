/// Form checks shared by Sign In and Create Account.
/// Each returns an error message, or null when the value is fine.
class Validators {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your full name';
    if (v.length < 2) return 'Name is too short';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Sign In: just needs something typed.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    return null;
  }

  /// Create Account: at least 8 characters.
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Create a password';
    if (value.length < 8) return 'Use at least 8 characters';
    return null;
  }
}
