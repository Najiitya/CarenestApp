import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/role_storage.dart';
import '../core/user_role.dart';
import 'caregiver_dashboard_page.dart';
import 'carereceiver_dashboard_page.dart';

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  static const routeName = '/';

  // Tune these to your brand
  static const Color _bg = Color(0xFFF7FAFA);
  static const Color _primary = Color(0xFF16A394);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textSoft = Color(0xFF7A8A96);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              children: [
                const SizedBox(height: 8),

                // Logo
                Center(
                  child: Column(
                    children: [
                      // Replace with your real logo asset path:
                      // Example: assets/images/carenest_logo.png
                      Image.asset(
                        'assets/images/logo_black.png',
                        height: 62,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) {
                          // If logo isn't added yet, show a neat fallback
                          return const Icon(
                            Icons.favorite,
                            size: 54,
                            color: _primary,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'CARENEST',
                        style: TextStyle(
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // Heading (two lines like the UI)
                const Text(
                  'Welcome to CareNest!\nHow will you use the app?',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                    height: 1.12,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 28),

                // Option 1: Caregiver
                _RoleCard(
                  icon: Icons.medical_services_outlined,
                  title: 'Caregiver',
                  subtitle: 'Find work and manage visits',
                  onTap: () async {
                    await RoleStorage.saveRole(UserRole.caregiver);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CaregiverDashboardPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Option 2: Care Receiver
                _RoleCard(
                  icon: Icons.elderly_outlined,
                  title: 'Care Receiver/Patient',
                  subtitle: 'Book care and track your health',
                  onTap: () async {
                    await RoleStorage.saveRole(UserRole.careReceiver);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CareReceiverDashboardPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 26),

                // Bottom "Already have an account? Log in"
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        color: _textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log in',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w900,
                            color: _textDark,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // TODO: navigate to login page
                            },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const Color _primary = Color(0xFF16A394);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        height: 110,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E6D68), // teal
              Color(0xFF0B4F4B), // deep teal
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon bubble (to mimic illustration area)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: Icon(icon, size: 34, color: Colors.white),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // subtle chevron (optional)
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.85)),
          ],
        ),
      ),
    );
  }
}
