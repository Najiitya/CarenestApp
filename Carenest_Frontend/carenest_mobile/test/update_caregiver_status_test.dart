import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carenest_mobileapp/screens/caregiver/update_caregiver_status.dart';

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
  testWidgets('Update care status page builds and shows title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UpdateCareStatusPage(),
      ),
    );

    await tester.pump();

    expect(find.text('Complete Session'), findsOneWidget);
  });

  /// ✅ TEST 2
  testWidgets('Care Notes section is displayed',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UpdateCareStatusPage(),
      ),
    );

    await tester.pump();

    expect(find.text('Care Notes (Required)'), findsOneWidget);
  });

  /// ✅ TEST 3
  testWidgets('Payment confirmation checkbox is displayed',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UpdateCareStatusPage(),
      ),
    );

    await tester.pump();

    expect(find.byType(CheckboxListTile), findsOneWidget);
  });

  /// ✅ TEST 4
  testWidgets('Complete session button is displayed',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UpdateCareStatusPage(),
      ),
    );

    await tester.pump();

    expect(find.textContaining('Complete Session'), findsWidgets);
  });
}