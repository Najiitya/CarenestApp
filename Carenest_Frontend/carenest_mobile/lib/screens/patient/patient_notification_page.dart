import 'package:flutter/material.dart';
import 'package:carenest_mobile/core/app_theme.dart';
import 'package:carenest_mobile/widgets/carereceiver_navigationbar_mobile.dart';

class PatientNotificationsPage extends StatefulWidget {
  const PatientNotificationsPage({super.key});

  @override
  State<PatientNotificationsPage> createState() =>
      _PatientNotificationsPageState();
}

class _PatientNotificationsPageState extends State<PatientNotificationsPage> {
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: const [
          PatientNotificationCard(
            title: 'Caregiver Accepted',
            description: 'Kumari Perera accepted your visit request.',
            date: '05 Feb 2026',
            time: '9:00 AM - 11:00 AM',
          ),
          PatientNotificationCard(
            title: 'Visit Reminder',
            description: 'Your caregiver will arrive soon.',
            date: '06 Feb 2026',
            time: '2:00 PM - 4:00 PM',
          ),
          PatientNotificationCard(
            title: 'Caregiver Assigned',
            description: 'A new caregiver has been assigned to you.',
            date: '07 Feb 2026',
            time: '10:00 AM',
          ),
        ],
      ),

      // ✅ CARE RECEIVER NAVIGATION BAR
      bottomNavigationBar: const SafeArea(
        child: CareReceiverNavigationBarMobile(
          currentIndex: 2, // Notifications selected
        ),
      ),
    );
  }
}

// ================= PATIENT NOTIFICATION CARD =================

class PatientNotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String time;

  const PatientNotificationCard({
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
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.softGreen,
                child: Icon(Icons.notifications, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.headingMedium),
                    const SizedBox(height: 6),
                    Text(description, style: AppTheme.bodyText),
                    const SizedBox(height: 12),
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
