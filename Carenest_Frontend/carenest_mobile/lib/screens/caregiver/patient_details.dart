import 'package:flutter/material.dart';
import 'package:carenest_mobile/core/app_theme.dart';
import 'package:carenest_mobile/screens/caregiver/caregiver_notification_page.dart';

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({super.key});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  int _currentIndex = 1; // Jobs selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Column(
        children: [
          /// HEADER IMAGE
          Stack(
            children: [
              SizedBox(
                height: 260,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/patientimg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_back, color: AppTheme.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// HEADER CARD
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _patientHeaderCard(),
          ),

          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
              child: Column(
                children: [
                  _medicalInfoCard(),
                  const SizedBox(height: 16),
                  _careInstructionsCard(),
                  const SizedBox(height: 16),
                  _emergencyContactCard(),
                ],
              ),
            ),
          ),
        ],
      ),

      /// ACCEPT + DECLINE + NAVIGATION
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ACCEPT / DECLINE BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.check),
                      label: const Text("Accept Visit"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.softGreen,
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showDeclineDialog,
                      icon: const Icon(Icons.close),
                      label: const Text("Decline Visit"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error.withOpacity(0.1),
                        foregroundColor: AppTheme.error,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// CUSTOM NAV BAR
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.home_outlined, "Home", 0),
                  _navItem(Icons.work_outline, "Jobs", 1),
                  _navItem(Icons.chat_bubble_outline, "Messages", 2),
                  _navItem(Icons.person_outline, "Profile", 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// NAV ITEM
  Widget _navItem(IconData icon, String label, int index) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);

        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CaregiverNotificationsPage(),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.softGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive ? AppTheme.primary : AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppTheme.primary : AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// DECLINE POPUP
  void _showDeclineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Decline Request?", style: AppTheme.headingMedium),
        content: Text(
          "Are you sure you want to decline this visit request?",
          style: AppTheme.bodyText,
        ),
        actions: [
          /// GREEN HIGHLIGHT ON NO
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("No"),
          ),

          /// YES NORMAL
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // backend later
            },
            child: Text("Yes", style: TextStyle(color: AppTheme.textGrey)),
          ),
        ],
      ),
    );
  }

  /// HEADER CARD
  Widget _patientHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mr. J. Perera", style: AppTheme.headingLarge),
                      const SizedBox(height: 4),
                      Text("Age: 72", style: AppTheme.bodyText),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Chat"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text("05 Feb 2026", style: AppTheme.bodyText),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text("9:00 AM - 11:00 AM", style: AppTheme.bodyText),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _medicalInfoCard() => _infoCard(
    title: "Medical Information",
    items: const [
      _InfoItem(Icons.local_hospital, "Condition", "Post-surgery"),
      _InfoItem(Icons.directions_walk, "Mobility", "Low"),
      _InfoItem(Icons.monitor_heart, "Monitoring", "Blood pressure & vitals"),
    ],
  );

  Widget _careInstructionsCard() => _infoCard(
    title: "Care Instructions",
    items: const [
      _InfoItem(
        Icons.check_circle,
        "",
        "Needs assistance while walking",
        isCheck: true,
      ),
      _InfoItem(
        Icons.check_circle,
        "",
        "Medication twice a day",
        isCheck: true,
      ),
      _InfoItem(
        Icons.check_circle,
        "",
        "Physiotherapy required",
        isCheck: true,
      ),
    ],
  );

  Widget _emergencyContactCard() => _infoCard(
    title: "Emergency Contact",
    items: const [
      _InfoItem(Icons.person, "Name", "S. Perera (Son)"),
      _InfoItem(Icons.phone, "Phone", "077 555 8899"),
    ],
  );
}

/// MODEL
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final bool isCheck;

  const _InfoItem(this.icon, this.label, this.value, {this.isCheck = false});
}

Widget _infoCard({required String title, required List<_InfoItem> items}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headingMedium),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(item.icon, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label.isEmpty
                          ? item.value
                          : '${item.label}: ${item.value}',
                      style: AppTheme.bodyText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
