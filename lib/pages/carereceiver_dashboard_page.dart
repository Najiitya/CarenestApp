import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CareReceiverDashboardPage extends StatefulWidget {
  const CareReceiverDashboardPage({super.key});

  static const routeName = '/carereceiver-dashboard';

  @override
  State<CareReceiverDashboardPage> createState() =>
      _CareReceiverDashboardPageState();
}

class _CareReceiverDashboardPageState extends State<CareReceiverDashboardPage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text('Hi, Mr. Perera', style: AppTheme.headingLarge),
                ),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.softGreen,
                  child: Icon(Icons.person, color: AppTheme.textGrey, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Current Caregiver card
            const _CurrentCaregiverCard(),

            const SizedBox(height: 18),

            Text(
              "Today's Care Status",
              style: AppTheme.headingMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 14),

            const _CareStatusTimeline(
              items: [
                _CareStatusItem(
                  state: _CareStatusState.done,
                  text: '9:00 AM: Morning Medication -\nCompleted',
                ),
                _CareStatusItem(
                  state: _CareStatusState.upcoming,
                  text: '2:00 PM: Physiotherapy Session -\nUpcoming',
                ),
              ],
            ),
          ],
        ),
      ),

      // Bottom nav
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.12))),
        ),
        child: NavigationBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          height: 70,
          indicatorColor: AppTheme.primary.withOpacity(0.12),
          selectedIndex: _navIndex,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppTheme.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: AppTheme.primary),
              label: 'Find Care',
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

class _CurrentCaregiverCard extends StatelessWidget {
  const _CurrentCaregiverCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E3C3A), Color(0xFF062C2B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Caregiver',
            style: AppTheme.headingMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.softGreen,
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: AppTheme.textGrey,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kumari Perera',
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Verified Caregiver',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFA9C2BE),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),

          // ✅ Let global theme style ElevatedButton (no styleFrom)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: Text('Chat now', style: AppTheme.buttonText),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CareStatusState { done, upcoming }

class _CareStatusItem {
  final _CareStatusState state;
  final String text;

  const _CareStatusItem({required this.state, required this.text});
}

class _CareStatusTimeline extends StatelessWidget {
  final List<_CareStatusItem> items;

  const _CareStatusTimeline({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left timeline column
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  _TimelineDot(state: item.state),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 62,
                      color: const Color(0xFFD9E6E8),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              ),
            ),

            // Right status card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: Colors.grey.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  item.text,
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final _CareStatusState state;

  const _TimelineDot({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDone = state == _CareStatusState.done;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDone ? AppTheme.primary : const Color(0xFFF2F6F7),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone ? AppTheme.primary : const Color(0xFFD9E6E8),
          width: 2,
        ),
      ),
      child: Icon(
        isDone ? Icons.check : Icons.access_time,
        color: isDone ? Colors.white : const Color(0xFF9AA8B2),
        size: 20,
      ),
    );
  }
}
