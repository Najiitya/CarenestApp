import 'package:flutter/material.dart';

import 'core/app_theme.dart';

import 'pages/role_select_page.dart';
import 'pages/caregiver_dashboard_page.dart';
import 'pages/carereceiver_dashboard_page.dart';

void main() {
  runApp(const CareNestApp());
}

class CareNestApp extends StatelessWidget {
  const CareNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // ✅ Always start here
      home: const RoleSelectPage(),

      // ✅ Named routes for navigation after selection
      routes: {
        RoleSelectPage.routeName: (_) => const RoleSelectPage(),
        CaregiverDashboardPage.routeName: (_) => const CaregiverDashboardPage(),
        CareReceiverDashboardPage.routeName: (_) =>
            const CareReceiverDashboardPage(),
      },
    );
  }
}
