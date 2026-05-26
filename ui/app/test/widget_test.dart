import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_app/main.dart';

void main() {
  testWidgets('Login screen shows SYNC branding and form', (tester) async {
    await tester.pumpWidget(const SyncApp());
    await tester.pumpAndSettle();

    expect(find.text('SYNC'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register Now'), findsOneWidget);
  });

  testWidgets('Login navigates to home dashboard', (tester) async {
    await tester.pumpWidget(const SyncApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Good Morning, Alex'), findsOneWidget);
    expect(find.text('My Roadmap'), findsOneWidget);
  });
}
