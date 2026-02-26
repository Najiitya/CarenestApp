import 'package:flutter/material.dart';
import 'package:carenest_mobile/core/app_theme.dart';
import 'package:carenest_mobile/widgets/caregiver_navigationbar_mobile.dart';

class CaregiverNotificationsPage extends StatefulWidget {
  const CaregiverNotificationsPage({super.key});

  @override
  State<CaregiverNotificationsPage> createState() =>
      _CaregiverNotificationsPageState();
}

class _CaregiverNotificationsPageState
    extends State<CaregiverNotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Notifications', style: AppTheme.headingMedium),
      ),

      // ================= BODY =================
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          NotificationCard(
            title: 'New Visit Request',
            description: 'Mr. J. Perera requested a visit',
            date: '05 Feb 2026',
            time: '9:00 AM - 11:00 AM',
          ),
          NotificationCard(
            title: 'Visit Updated',
            description: 'Visit time changed for Mrs. Silva',
            date: '06 Feb 2026',
            time: '2:00 PM - 4:00 PM',
          ),
          NotificationCard(
            title: 'New Care Request',
            description: 'New patient assigned: Mr. Fernando',
            date: '07 Feb 2026',
            time: '10:00 AM',
          ),
        ],
      ),

      // ================= LEADER NAVIGATION BAR =================
      bottomNavigationBar: const CaregiverNavigationBarMobile(
        currentIndex: 1, // 1 = Notifications tab
      ),
    );
  }
}

// ================= NOTIFICATION CARD =================

class NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String time;

  const NotificationCard({
    super.key,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.softGreen,
                child: Icon(Icons.notifications, color: AppTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.headingMedium),
                    const SizedBox(height: 6),
                    Text(description, style: AppTheme.bodyText),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(date, style: AppTheme.bodyText),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(time, style: AppTheme.bodyText)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
