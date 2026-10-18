import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'routes.dart';
import 'screens/contacts_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/device_screen.dart';
import 'screens/emergency_alert_screen.dart';
import 'screens/fall_detected_screen.dart';
import 'screens/home_shell.dart';
import 'screens/no_response_screen.dart';
import 'screens/sign_in_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.init(); // load saved accounts, contacts, settings and events
  runApp(const CardioGuardApp());
}

class CardioGuardApp extends StatelessWidget {
  const CardioGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardioGuard',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
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
        AppRoutes.fallDetected: (_) => const FallDetectedScreen(),
        AppRoutes.noResponse: (_) => const NoResponseScreen(),
        AppRoutes.emergencyAlert: (_) => const EmergencyAlertScreen(),
      },
    );
  }
}
