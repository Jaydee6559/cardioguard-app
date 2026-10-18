import 'package:flutter/material.dart';

import 'routes.dart';
import 'screens/create_account_screen.dart';
import 'screens/home_placeholder_screen.dart';
import 'screens/sign_in_screen.dart';
import 'theme.dart';

void main() {
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
      initialRoute: AppRoutes.signIn,
      routes: {
        AppRoutes.signIn: (_) => const SignInScreen(),
        AppRoutes.createAccount: (_) => const CreateAccountScreen(),
        AppRoutes.home: (_) => const HomePlaceholderScreen(),
      },
    );
  }
}
