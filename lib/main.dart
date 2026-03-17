import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_theme.dart';

// main screens
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password_screen.dart';
// patient screens
import 'screens/patient/patient_register_page.dart';
import 'screens/patient/patient_profile_page.dart';
import 'screens/patient/carereceiver_dashboard_page.dart';
import 'screens/patient/patient_details.dart';
import 'screens/patient/request_caregiver.dart';
import 'screens/patient/patient_notification_page.dart';
import 'screens/patient/search_caregiver_page.dart';
import 'screens/patient/patient_review_page.dart';
import 'screens/caregiver/caregiver_job_page.dart';
// caregiver screens
import 'screens/caregiver/caregiver_register_page.dart';
import 'screens/caregiver/caregiver_profile_page.dart';
import 'screens/caregiver/caregiver_dashboard_page.dart';
import 'screens/caregiver/caregiver_details.dart';
import 'screens/caregiver/update_caregiver_status.dart';
import 'screens/caregiver/caregiver_notification_page.dart';
import 'screens/caregiver/schedule_page.dart';
// common screens
import 'pages/role_select_page.dart';

// Global Supabase client variable to use anywhere in app
final supabase = Supabase.instance.client;

Future<void> main() async {
  // Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize your Supabase database connection
  await Supabase.initialize(
    url: 'https://kpavgqkksmeskrvyhjuj.supabase.co',
    anonKey: 'sb_publishable__uM8woW2XUtC_RyaFCUMlA_J4Hm3-yC',
  );

  runApp(const CareNestApp());
}

class CareNestApp extends StatelessWidget {
  const CareNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // --- Initial Route ---
      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/reset_password': (context) => const ResetPasswordScreen(),
        '/role_select': (context) => const RoleSelectPage(),

        // --- Patient Routes ---
        '/patient_register': (context) => const RegisterPatientScreen(),
        '/patient_profile': (context) => const PatientProfilePage(),
        '/patient_dashboard': (context) => const CareReceiverDashboardPage(),
        '/patient_details': (context) => const PatientDetailsPage(),
        '/patient_request-caregiver': (context) => const RequestCarePage(),
        '/patient_notifications': (context) => const PatientNotificationsPage(),
        '/caregiver_search': (context) => const CaregiverSearchPage(),
        '/patient_review': (context) => const PatientReviewPage(),

        // --- Caregiver Routes ---
        '/caregiver_register': (context) => const RegisterCaregiverScreen(),
        '/caregiver_profile': (context) => const CaregiverProfilePage(),
        '/caregiver_dashboard': (context) => const CaregiverDashboardPage(),
        '/caregiver_details': (context) => const CaregiverDetailsPage(),
        '/caregiver_notifications': (context) => const CaregiverNotificationsPage(),
        '/caregiver_schedule': (context) => const SchedulePage(),
        '/caregiver_update-status': (context) => const UpdateCareStatusPage(),
        '/caregiver_job': (context) => const CaregiverJobRequestsPage()
      },
    );
  }
}
