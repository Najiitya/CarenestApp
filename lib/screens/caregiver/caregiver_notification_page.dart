import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../widgets/caregiver_navigationbar_mobile.dart';

class CaregiverNotificationsPage extends StatefulWidget {
  const CaregiverNotificationsPage({super.key});

  @override
  State<CaregiverNotificationsPage> createState() =>
      _CaregiverNotificationsPageState();
}

class _CaregiverNotificationsPageState
    extends State<CaregiverNotificationsPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _listenForNewNotifications();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final uid = supabase.auth.currentUser!.id;

      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_auth_id', uid)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    }
  }

  void _listenForNewNotifications() {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    _subscription = supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_auth_id', uid)
        .order('created_at', ascending: false)
        .listen((data) {
          if (mounted) {
            setState(() {
              _notifications = List<Map<String, dynamic>>.from(data);
              _isLoading = false;
            });
          }
        });
  }

  Future<void> _markAsRead(int notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> _clearAllNotifications() async {
    final uid = supabase.auth.currentUser!.id;
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_auth_id', uid);
  }

  void _onNotificationTap(Map<String, dynamic> n) {
    // Mark as read first
    if (n['is_read'] != true) {
      _markAsRead(n['id']);
    }

    final type = n['type'] as String?;

    switch (type) {
      case 'booking':
        // New booking request → go to job requests page
        Navigator.pushReplacementNamed(context, '/caregiver_job');
        break;
      case 'review':
        // New review → go to profile to see updated ratings
        Navigator.pushReplacementNamed(context, '/caregiver_profile');
        break;
      default:
        break;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'booking':
        return Icons.calendar_today;
      case 'review':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'booking':
        return AppTheme.primary;
      case 'review':
        return Colors.amber;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((n) => n['is_read'] != true)
        .length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Notifications', style: AppTheme.headingMedium),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _clearAllNotifications,
              child: Text(
                'Mark all read',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: AppTheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  final isRead = n['is_read'] == true;
                  return GestureDetector(
                    onTap: () => _onNotificationTap(n),
                    child: _buildNotificationCard(n, isRead),
                  );
                },
              ),
            ),
      bottomNavigationBar: const CaregiverNavigationBarMobile(currentIndex: 2),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n, bool isRead) {
    final type = n['type'] as String?;
    final isClickable = type == 'booking' || type == 'review';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? AppTheme.surface : AppTheme.softGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getNotificationColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getNotificationIcon(type),
                color: _getNotificationColor(type),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n['title'] ?? 'Notification',
                          style: AppTheme.headingMedium.copyWith(fontSize: 14),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(n['description'] ?? '', style: AppTheme.bodyText),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppTheme.textGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        n['date']?.toString() ?? '',
                        style: AppTheme.bodyText.copyWith(fontSize: 12),
                      ),
                      if ((n['time'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.textGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          n['time'].toString().length >= 5
                              ? n['time'].toString().substring(0, 5)
                              : n['time'].toString(),
                          style: AppTheme.bodyText.copyWith(fontSize: 12),
                        ),
                      ],
                      const Spacer(),
                      if (isClickable)
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppTheme.textGrey,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: AppTheme.bodyText.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll be notified about new requests and reviews',
            style: AppTheme.bodyText.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
