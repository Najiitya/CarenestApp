import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverNavigationBarMobile extends StatefulWidget {
  final int currentIndex;

  const CaregiverNavigationBarMobile({super.key, required this.currentIndex});

  @override
  State<CaregiverNavigationBarMobile> createState() =>
      _CaregiverNavigationBarMobileState();
}

class _CaregiverNavigationBarMobileState
    extends State<CaregiverNavigationBarMobile> {
  static const _teal = Color(0xFF0EA5A0);
  static const _tealPill = Color(0xFFE6F7F6);
  static const _grey = Color(0xFF64748B);

  int _unreadCount = 0;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _listenUnread();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenUnread() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    _subscription = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_auth_id', uid)
        .listen((data) {
          if (mounted) {
            final count = data.where((n) => n['is_read'] != true).length;
            setState(() => _unreadCount = count);
          }
        });
  }

  void _go(BuildContext context, int index) {
    const routes = [
      '/caregiver_dashboard',
      '/caregiver_job',
      '/caregiver_notifications',
      '/caregiver_profile',
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
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? _teal : _grey, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? _teal : _grey,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: widget.currentIndex,
        onDestinationSelected: (i) => _go(context, i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              backgroundColor: Colors.red,
              label: _unreadCount > 9
                  ? const Text(
                      '9+',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    )
                  : Text(
                      '$_unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
              child: const Icon(Icons.notifications_none_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: _unreadCount > 0,
              backgroundColor: Colors.red,
              label: _unreadCount > 9
                  ? const Text(
                      '9+',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    )
                  : Text(
                      '$_unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
