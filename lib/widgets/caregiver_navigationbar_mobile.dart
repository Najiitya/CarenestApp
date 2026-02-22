import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Reusable scaffold + bottom navigation for CAREGIVER role (mobile).
/// Other devs should wrap their caregiver pages with this widget.
class CaregiverNavigationBarMobile extends StatelessWidget {
  final Widget child;

  /// Active tab index (0..3)
  final int currentIndex;
  final bool enableNavigation;

  const CaregiverNavigationBarMobile({
    super.key,
    required this.child,
    required this.currentIndex,
    this.enableNavigation = true,
  });

  static const int homeIndex = 0;
  static const int jobsIndex = 1;
  static const int messagesIndex = 2;
  static const int profileIndex = 3;

  // TODO: Replace these with your real route names when pages exist.
  static const String homeRoute = '/caregiver-dashboard';
  static const String jobsRoute = '/caregiver-jobs';
  static const String messagesRoute = '/caregiver-messages';
  static const String profileRoute = '/caregiver-profile';

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (!enableNavigation) return; // 👈 ADD THIS LINE

    final route = switch (index) {
      homeIndex => homeRoute,
      jobsIndex => jobsRoute,
      messagesIndex => messagesRoute,
      profileIndex => profileRoute,
      _ => homeRoute,
    };

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.12))),
        ),
        child: NavigationBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          height: 70,
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => _go(context, i),
          indicatorColor: AppTheme.primary.withOpacity(0.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppTheme.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt, color: AppTheme.primary),
              label: 'Jobs',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: AppTheme.primary),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
