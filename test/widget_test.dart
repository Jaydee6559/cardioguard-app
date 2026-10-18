import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardioguard/data/app_state.dart';
import 'package:cardioguard/main.dart';

const testEmail = 'caregiver@cardioguard.app';
const testPassword = 'password123';

/// Fills in Sign In and taps the button.
Future<void> signIn(WidgetTester tester, {String password = testPassword}) async {
  await tester.enterText(find.byType(TextFormField).at(0), testEmail);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
  await tester.pumpAndSettle();
}

void main() {
  // Every test starts with empty phone storage and one saved account.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.init();
    await AppState.createAccount(
      name: 'Maria Santos',
      email: testEmail,
      password: testPassword,
      relationship: 'Daughter',
    );
  });

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

  testWidgets('Wrong password is rejected', (tester) async {
    await tester.pumpWidget(const CardioGuardApp());
    await signIn(tester, password: 'wrongpass1');

    expect(find.text('Incorrect password. Please try again.'), findsOneWidget);
    expect(find.text('Roberto Santos'), findsNothing);
  });

  testWidgets('Create one opens Create Account', (tester) async {
    await tester.pumpWidget(const CardioGuardApp());

    await tester.ensureVisible(find.text('Create one'));
    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();

    expect(find.text('Set up your caregiver account'), findsOneWidget);
  });

  testWidgets('Sign in opens the dashboard; I\'M OK is logged in Alerts', (tester) async {
    await tester.pumpWidget(const CardioGuardApp());
    await signIn(tester);

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

    // The newest event is the post-fall response.
    expect(AppState.events.value.first.title, 'Post-fall Response');
  });

  testWidgets('Vitals and Alerts tabs show their content', (tester) async {
    await tester.pumpWidget(const CardioGuardApp());
    await signIn(tester);

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

  testWidgets('Settings shows the account and opens Contacts and Device', (tester) async {
    await tester.pumpWidget(const CardioGuardApp());
    await signIn(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Profile & Settings'), findsOneWidget);
    expect(find.text(testEmail), findsOneWidget);
    expect(find.text('2 contacts'), findsOneWidget);

    await tester.ensureVisible(find.text('Emergency contacts'));
    await tester.tap(find.text('Emergency contacts'));
    await tester.pumpAndSettle();
    expect(find.text('Dr. Reyes'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Device & sensors'));
    await tester.tap(find.text('Device & sensors'));
    await tester.pumpAndSettle();
    expect(find.text('MPU6050'), findsOneWidget);
  });

  test('Remember me keeps the account signed in after a restart', () async {
    await AppState.signIn(testEmail, testPassword, remember: true);
    await AppState.init(); // simulate closing and reopening the app
    expect(AppState.isSignedIn, isTrue);

    await AppState.signIn(testEmail, testPassword, remember: false);
    await AppState.init();
    expect(AppState.isSignedIn, isFalse);
  });

  test('Contacts and events survive a restart', () async {
    await AppState.deleteContact(1); // remove Dr. Reyes
    await AppState.logEvent('Test event', 'Saved to the phone', AppState.events.value.first.severity);
    await AppState.init();

    expect(AppState.contacts.value.length, 1);
    expect(AppState.events.value.first.title, 'Test event');
  });
}
