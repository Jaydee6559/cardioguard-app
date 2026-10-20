import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_state.dart';
import 'routes.dart';
import 'screens/contacts_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/device_screen.dart';
import 'screens/emergency_alert_screen.dart';
import 'screens/home_shell.dart';
import 'screens/sign_in_screen.dart';
import 'services/ble_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.init(); // load saved accounts, contacts, settings and events
  await NotificationService.init(); // emergency notifications
  await BleService.instance.initialize();
  runApp(const CardioGuardApp());
}

class CardioGuardApp extends StatelessWidget {
  const CardioGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds when the Appearance setting changes (System / Light / Dark).
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'CardioGuard',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(AppPalette.light),
        darkTheme: buildAppTheme(AppPalette.dark),
        themeMode: mode,
        // Status-bar icons: dark on light screens, light on dark screens.
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: child ?? const SizedBox.shrink(),
          );
        },
        // First screen: the dashboard if "Remember me" kept someone signed in,
        // otherwise Sign In.
        onGenerateInitialRoutes: (_) => [
          AppState.isSignedIn
              ? MaterialPageRoute<void>(
                  settings: const RouteSettings(name: AppRoutes.home),
                  builder: (_) => const HomeShell(),
                )
              : MaterialPageRoute<void>(
                  settings: const RouteSettings(name: AppRoutes.signIn),
                  builder: (_) => const SignInScreen(),
                ),
        ],
        routes: {
          AppRoutes.signIn: (_) => const SignInScreen(),
          AppRoutes.createAccount: (_) => const CreateAccountScreen(),
          AppRoutes.home: (_) => const HomeShell(),
          AppRoutes.contacts: (_) => const ContactsScreen(),
          AppRoutes.device: (_) => const DeviceScreen(),
          AppRoutes.emergencyAlert: (_) => const EmergencyAlertScreen(),
        },
      ),
    );
  }
}
