import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carenest_mobileapp/screens/caregiver/caregiver_details.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock shared_preferences
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/shared_preferences');

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return {};
    });

    // Init Supabase
    await Supabase.initialize(
      url: 'https://xyzcompany.supabase.co',
      anonKey: 'public-anon-key',
    );
  });

  /// ✅ TEST 1
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
}