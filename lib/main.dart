import 'package:flutter/material.dart';

import 'core/role_storage.dart';
import 'core/user_role.dart';

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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _StartupGate(),
    );
  }
}

class _StartupGate extends StatelessWidget {
  const _StartupGate();

  // @override
  // Widget build(BuildContext context) {
  //   return FutureBuilder<UserRole?>(
  //     future: RoleStorage.getRole(),
  //     builder: (context, snapshot) {
  //       // Loading state
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Scaffold(
  //           body: Center(child: CircularProgressIndicator()),
  //         );
  //       }

  //       final role = snapshot.data;

  //       if (role == UserRole.caregiver) {
  //         return const CaregiverDashboardPage();
  //       }

  //       if (role == UserRole.careReceiver) {
  //         return const CareReceiverDashboardPage();
  //       }

  //       return const RoleSelectPage();
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RoleSelectPage(),
    );
  }
}
