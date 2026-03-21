import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carenest_mobileapp/screens/patient/patient_details.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/shared_preferences');

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return {};
    });

    await Supabase.initialize(
      url: 'https://xyzcompany.supabase.co',
      anonKey: 'public-anon-key',
    );
  });

  /// ✅ TEST 1
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

  /// ✅ TEST 2
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

  /// ✅ TEST 3
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
}