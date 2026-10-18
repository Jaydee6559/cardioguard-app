import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cardioguard/main.dart';

void main() {
  testWidgets('App opens on Sign In', (tester) async {
    await tester.pumpWidget(const CardioGuardApp());

    expect(find.text('CardioGuard'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('Sign In shows errors when fields are empty', (tester) async {
    await tester.pumpWidget(const CardioGuardApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('Create one opens Create Account', (tester) async {
    await tester.pumpWidget(const CardioGuardApp());

    await tester.ensureVisible(find.text('Create one'));
    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();

    expect(find.text('Set up your caregiver account'), findsOneWidget);
  });

  testWidgets('Sign in opens the dashboard, Simulate Fall opens the fall check', (tester) async {
    await tester.pumpWidget(const CardioGuardApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'caregiver@cardioguard.app');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Roberto Santos'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);

    await tester.ensureVisible(find.text('Simulate Fall'));
    await tester.tap(find.text('Simulate Fall'));
    await tester.pumpAndSettle();
    expect(find.text('Possible Fall Detected'), findsOneWidget);

    // Answer the check so its countdown timer stops before the test ends.
    await tester.tap(find.text("I'M OK"));
    await tester.pumpAndSettle();
    expect(find.text('Roberto Santos'), findsOneWidget);
  });

  testWidgets('Vitals and Alerts tabs show their content', (tester) async {
    await tester.pumpWidget(const CardioGuardApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'caregiver@cardioguard.app');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vitals'));
    await tester.pumpAndSettle();
    expect(find.text('Vital Signs History'), findsOneWidget);
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    expect(find.text('Manual SOS'), findsOneWidget);

    // Filter to Info: only the post-fall response remains.
    await tester.tap(find.text('Info (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Post-fall Response'), findsOneWidget);
    expect(find.text('Manual SOS'), findsNothing);
  });
}
