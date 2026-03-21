import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carenest_mobileapp/screens/patient/patient_details.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock shared_preferences (required for Supabase)
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/shared_preferences');

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return {};
    });

    // Initialize Supabase with dummy values
    await Supabase.initialize(
      url: 'https://xyzcompany.supabase.co',
      anonKey: 'public-anon-key',
    );
  });

  /// ✅ TEST 1 — Build test
  testWidgets('Patient page builds without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PatientDetailsPage(),
      ),
    );

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  /// ✅ TEST 2 — Scaffold exists
  testWidgets('Scaffold is present on patient page',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PatientDetailsPage(),
      ),
    );

    await tester.pump();

    expect(find.byType(Scaffold), findsWidgets);
  });

  /// ✅ TEST 3 — Text widgets exist
  testWidgets('Patient page contains text widgets',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PatientDetailsPage(),
      ),
    );

    await tester.pump();

    expect(find.byType(Text), findsWidgets);
  });

  /// ✅ TEST 4 — AppBar exists
  testWidgets('Patient page has an AppBar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PatientDetailsPage(),
      ),
    );

    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);
  });
}