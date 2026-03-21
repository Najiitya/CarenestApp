import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carenest_mobileapp/screens/patient/patient_notification_page.dart';

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
  testWidgets('Notifications page builds and shows title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PatientNotificationsPage(),
      ),
    );

    await tester.pump();

    expect(find.text('Notifications'), findsWidgets);
  });

  /// ✅ TEST 2
  testWidgets('Shows empty state when no notifications',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PatientNotificationsPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
  });

  /// ✅ TEST 3
  testWidgets('Empty state shows notification icon',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PatientNotificationsPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  /// ✅ TEST 4
  testWidgets('Notifications page has an AppBar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PatientNotificationsPage(),
      ),
    );

    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);
  });
}