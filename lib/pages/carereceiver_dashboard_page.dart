import 'package:flutter/material.dart';

class CareReceiverDashboardPage extends StatefulWidget {
  const CareReceiverDashboardPage({super.key});

  static const routeName = '/carereceiver-dashboard';

  @override
  State<CareReceiverDashboardPage> createState() =>
      _CareReceiverDashboardPageState();
}

class _CareReceiverDashboardPageState extends State<CareReceiverDashboardPage> {
  int _navIndex = 0;

  // Colors tuned to your UI
  static const _bg = Color(0xFFF7FAFA);
  static const _cardBorder = Color(0xFFE7EEF0);
  static const _textDark = Color(0xFF0F172A);
  static const _textSoft = Color(0xFF7A8A96);
  static const _primary = Color(0xFF16A394);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          children: [
            // Header: Hi, Mr. Perera + avatar
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'Hi, Mr. Perera',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Replace with real patient image:
                // CircleAvatar(backgroundImage: AssetImage('assets/images/patient.png'))
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFE9F3F2),
                  child: Icon(Icons.person, color: _textSoft, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Current Caregiver dark card
            const _CurrentCaregiverCard(),

            const SizedBox(height: 18),

            const Text(
              "Today's Care Status",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _textDark,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _cardBorder)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          height: 70,
          indicatorColor: _primary.withOpacity(0.12),
          selectedIndex: _navIndex,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: _primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: _primary),
              label: 'Find Care',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: _primary),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: _primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentCaregiverCard extends StatelessWidget {
  static const _primary = Color(0xFF16A394);

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
          const Text(
            'Current Caregiver',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Replace with real caregiver photo:
              // CircleAvatar(radius: 38, backgroundImage: AssetImage('assets/images/caregiver.png'))
              const CircleAvatar(
                radius: 38,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFE9F3F2),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: Color(0xFF7A8A96),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kumari Perera',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Verified Caregiver',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFA9C2BE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Chat now',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
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

  static const _cardBorder = Color(0xFFE7EEF0);
  static const _textDark = Color(0xFF0F172A);
  static const _primary = Color(0xFF16A394);

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
                  color: Colors.white,
                  border: Border.all(color: _cardBorder),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
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

  static const _primary = Color(0xFF16A394);

  const _TimelineDot({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDone = state == _CareStatusState.done;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDone ? _primary : const Color(0xFFF2F6F7),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone ? _primary : const Color(0xFFD9E6E8),
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
