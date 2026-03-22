import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Replace with your actual import paths
import '../lib/screens/patient/patient_register_page.dart';
import '../lib/screens/caregiver/caregiver_register_page.dart';

void main() {
  // 1. Fake Supabase initialization to prevent crashes
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://mock-url-for-testing.supabase.co',
      anonKey: 'mock-key-for-testing',
    );
  });

  // ==========================================
  // PATIENT REGISTRATION TESTS
  // ==========================================
  group('Patient Registration Screen Tests', () {

    Widget createPatientScreen() {
      return const MaterialApp(home: RegisterPatientScreen());
    }

    testWidgets('TC_PREG_02 & TC_PREG_03: Invalid email and short password show errors', (WidgetTester tester) async {
      await tester.pumpWidget(createPatientScreen());

      // Find the specific text fields based on their labels
      final emailField = find.widgetWithText(TextFormField, 'Email Address');
      final passwordField = find.widgetWithText(TextFormField, 'Create Password');
      final submitButton = find.text('Create Patient Account');

      // Enter invalid data
      await tester.enterText(emailField, 'invalidemail.com'); // Missing '@'
      await tester.enterText(passwordField, '12345'); // Only 5 characters

      // Tap submit
      await tester.tap(submitButton);
      await tester.pump();

      // Verify the exact error messages from your code appear
      expect(find.text('Invalid Email'), findsOneWidget);
      expect(find.text('Min 6 characters'), findsOneWidget);
    });
  });

  // ==========================================
  // CAREGIVER REGISTRATION TESTS
  // ==========================================
  group('Caregiver Registration Screen Tests', () {

    Widget createCaregiverScreen() {
      return const MaterialApp(home: RegisterCaregiverScreen());
    }

    testWidgets('TC_CREG_03: Empty fields prevent registration', (WidgetTester tester) async {
      await tester.pumpWidget(createCaregiverScreen());

      // Find the submit button and tap it without entering any text
      final submitButton = find.text('Create Caregiver Account');

      await tester.tap(submitButton);
      await tester.pump();

      // Ensure the loading indicator did NOT appear (meaning validation blocked it)
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('TC_CREG_02: Short password shows error', (WidgetTester tester) async {
      await tester.pumpWidget(createCaregiverScreen());

      // Find the password field for the caregiver screen
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      final submitButton = find.text('Create Caregiver Account');

      // Enter a password that is too short
      await tester.enterText(passwordField, '123');

      // Tap submit
      await tester.tap(submitButton);
      await tester.pump();

      // Verify the exact error message from your code appears
      expect(find.text('Min 6 characters'), findsOneWidget);
    });
  });
}