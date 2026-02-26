import 'package:flutter/material.dart';

class CaregiverNavigationBarMobile extends StatelessWidget {
  final int currentIndex;

  const CaregiverNavigationBarMobile({super.key, required this.currentIndex});

  static const _teal = Color(0xFF0EA5A0);
  static const _tealPill = Color(0xFFE6F7F6);
  static const _grey = Color(0xFF64748B);

  void _go(BuildContext context, int index) {
    const routes = [
      '/caregiver/dashboard', // Home
      '/caregiver/notifications', // Notifications
      '/caregiver/profile', // Profile
    ];

    final target = routes[index];
    final current = ModalRoute.of(context)?.settings.name;

    if (current == target) return;
    Navigator.pushReplacementNamed(context, target);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 72,
        indicatorColor: _tealPill,
        iconTheme: MaterialStateProperty.resolveWith<IconThemeData>((states) {
          final selected = states.contains(MaterialState.selected);
          return IconThemeData(color: selected ? _teal : _grey, size: 24);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>((states) {
          final selected = states.contains(MaterialState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? _teal : _grey,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _go(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}