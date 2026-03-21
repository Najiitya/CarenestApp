import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carenest_mobileapp/screens/caregiver/caregiver_details.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock shared_preferences (required for Supabase)
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/shared_preferences');

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return {};
    });

    // Initialize Supabase (dummy values)
    await Supabase.initialize(
      url: 'https://xyzcompany.supabase.co',
      anonKey: 'public-anon-key',
    );
  });

  /// ✅ TEST 1 — Build test
  testWidgets('Caregiver page builds without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverDetailsPage(),
      ),
    );

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  /// ✅ TEST 2 — Not found message
  testWidgets('Shows "Caregiver not found" when no data',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverDetailsPage(),
      ),
    );

    await tester.pump();

    expect(find.text('Caregiver not found'), findsOneWidget);
  });

  /// ✅ TEST 3 — Back button exists
  testWidgets('Back button is present on caregiver page',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverDetailsPage(),
      ),
    );

    await tester.pump();

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  /// ✅ TEST 4 — AppBar exists
  testWidgets('Caregiver page has an AppBar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverDetailsPage(),
      ),
    );

    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);
  });
}