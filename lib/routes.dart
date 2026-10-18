/// Route names in one place, so screens never type a path by hand.
class AppRoutes {
  static const signIn = '/';
  static const createAccount = '/create-account';
  static const home = '/home';

  // Opened from Settings
  static const contacts = '/contacts';
  static const device = '/device';

  // Emergency flow (screens 08–10)
  static const fallDetected = '/fall-detected';
  static const noResponse = '/no-response';
  static const emergencyAlert = '/emergency-alert';
}
