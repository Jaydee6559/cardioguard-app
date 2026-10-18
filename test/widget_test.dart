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
}
