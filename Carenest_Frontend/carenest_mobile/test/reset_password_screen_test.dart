import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/screens/reset_password_screen.dart';

void main() {
  // 1. Fake Supabase initialization to prevent crashes during isolated tests
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://mock-url-for-testing.supabase.co',
      anonKey: 'mock-key-for-testing',
    );
  });

  group('Reset Password Screen - Validation Tests', () {

    Widget createResetPasswordScreen() {
      return const MaterialApp(
        home: ResetPasswordScreen(),
      );
    }

    testWidgets('TC_RST_01 Empty email shows validation error', (WidgetTester tester) async {
      await tester.pumpWidget(createResetPasswordScreen());

      // Find the submit button and tap it without entering an email
      final sendButton = find.text('Send Reset Link');
      await tester.tap(sendButton);
      await tester.pump(); // Trigger the frame to show the validation error

      // Verify the exact error message from your code appears
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('TC_RST_02 Missing @ symbol shows invalid format error', (WidgetTester tester) async {
      await tester.pumpWidget(createResetPasswordScreen());

      // Find the email text field
      final emailField = find.byType(TextFormField);

      // Enter an invalid email (no @ symbol)
      await tester.enterText(emailField, 'nethwan.yahoo.com');

      // Tap the submit button
      final sendButton = find.text('Send Reset Link');
      await tester.tap(sendButton);
      await tester.pump();

      // Verify the exact error message from your code appears
      expect(find.text('Invalid email address'), findsOneWidget);
    });
  });
}