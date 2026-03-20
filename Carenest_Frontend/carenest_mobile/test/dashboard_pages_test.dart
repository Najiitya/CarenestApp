import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:carenest_mobileapp/screens/caregiver/caregiver_dashboard_page.dart';
import 'package:carenest_mobileapp/screens/patient/carereceiver_dashboard_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
  });

  testWidgets('Caregiver dashboard loads correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CaregiverDashboardPage()));

    await tester.pumpAndSettle();

    expect(find.byType(CaregiverDashboardPage), findsOneWidget);
  });

  testWidgets('Patient dashboard loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CareReceiverDashboardPage()),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CareReceiverDashboardPage), findsOneWidget);
  });
}
