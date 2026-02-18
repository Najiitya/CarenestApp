import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/role_storage.dart';
import '../core/user_role.dart';

import 'caregiver_dashboard_page.dart';
import 'carereceiver_dashboard_page.dart';

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  static const routeName = '/role-select';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
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
                      Image.asset(
                        'assets/images/logo_black.png',
                        height: 62,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) {
                          return const Icon(
                            Icons.favorite,
                            size: 54,
                            color: AppTheme.primary,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'CARENEST',
                        style: AppTheme.bodyText.copyWith(
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          fontSize: 14,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // Heading (two lines)
                Text(
                  'Welcome to CareNest!\nHow will you use the app?',
                  style: AppTheme.headingLarge.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: const Color.fromRGBO(0, 46, 46, 1),
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

                    // ✅ named route navigation
                    Navigator.pushReplacementNamed(
                      context,
                      CaregiverDashboardPage.routeName,
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

                    // ✅ named route navigation
                    Navigator.pushReplacementNamed(
                      context,
                      CareReceiverDashboardPage.routeName,
                    );
                  },
                ),

                const SizedBox(height: 26),

                // Bottom "Already have an account? Log in"
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 15,
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log in',
                          style: AppTheme.bodyText.copyWith(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                            fontSize: 15,
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
            colors: [AppTheme.primaryDark, Color(0xFF0B4F4B)],
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
            // Icon bubble
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
                    style: AppTheme.headingMedium.copyWith(
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
                    style: AppTheme.bodyText.copyWith(
                      color: Colors.white.withOpacity(0.78),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.85)),
          ],
        ),
      ),
    );
  }
}
