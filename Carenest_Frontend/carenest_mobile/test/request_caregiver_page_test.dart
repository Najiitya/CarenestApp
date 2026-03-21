import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carenest_mobileapp/screens/patient/request_caregiver.dart';

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
  testWidgets('Request care page builds and shows title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RequestCarePage(),
      ),
    );

    await tester.pump();

    expect(find.text('Request Care'), findsOneWidget);
  });

  /// ✅ TEST 2
  testWidgets('Service Type section is displayed',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RequestCarePage(),
      ),
    );

    await tester.pump();

    expect(find.text('Service Type'), findsOneWidget);
  });

  /// ✅ TEST 3
  testWidgets('Request button is displayed',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RequestCarePage(),
      ),
    );

    await tester.pump();

    expect(find.text('Request'), findsOneWidget);
  });
}