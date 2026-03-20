import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';
import 'caregiver/caregiver_verification_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Keep the splash visible for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      // No active session, go to login
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Session exists — determine role by checking profile tables
    final uid = session.user.id;

    try {
      // Check admin
      final adminCheck = await supabase
          .from('admins')
          .select('id')
          .eq('auth_id', uid)
          .maybeSingle();

      if (adminCheck != null && mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Check caregiver
      final caregiverCheck = await supabase
          .from('caregiver_profiles')
          .select('id, verified')
          .eq('auth_id', uid)
          .maybeSingle();

      if (caregiverCheck != null && mounted) {
        final isVerified = caregiverCheck['verified'] == true;
        final caregiverId = caregiverCheck['id'] as int;

        if (isVerified) {
          Navigator.pushReplacementNamed(context, '/caregiver_dashboard');
        } else {
          // Check if there's an existing application
          final existingApp = await supabase
              .from('caregiver_applications')
              .select('status')
              .eq('caregiver_id', caregiverId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          final appStatus = existingApp?['status'] as String?;

          // If application is already approved, go straight to dashboard
          if (appStatus == 'Approved' && mounted) {
            Navigator.pushReplacementNamed(context, '/caregiver_dashboard');
          } else if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CaregiverVerificationPage(
                  caregiverId: caregiverId,
                  applicationStatus: appStatus,
                ),
              ),
            );
          }
        }
        return;
      }

      // Check patient
      final patientCheck = await supabase
          .from('patient_profiles')
          .select('id')
          .eq('auth_id', uid)
          .maybeSingle();

      if (patientCheck != null && mounted) {
        Navigator.pushReplacementNamed(context, '/patient_dashboard');
        return;
      }

      // Session exists but no profile found — go to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      // On any error, fall back to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset('../assets/images/logo_white.png', height: 100, errorBuilder: (context, error, stack) {
              return const Icon(Icons.favorite, size: 80, color: AppTheme.surface);
            }),

            const SizedBox(height: 24),

            // App Name
            Image(image: const AssetImage('../assets/images/typo_white.png'), height: 28, errorBuilder: (context, error, stack) {
              return const Text(
                'CARENEST',
                style: TextStyle(
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.surface,
                  fontSize: 18,
                ),
              );
            }),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Care that feels closer to home',
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.surface.withOpacity(0.9),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 60),

            // Loading Spinner
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.surface),
            ),
          ],
        ),
      ),
    );
  }
}
