import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CaregiverDashboardPage extends StatefulWidget {
  const CaregiverDashboardPage({super.key});

  static const routeName = '/caregiver-dashboard';

  @override
  State<CaregiverDashboardPage> createState() => _CaregiverDashboardPageState();
}

class _CaregiverDashboardPageState extends State<CaregiverDashboardPage> {
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
                  child: Text('Hi, Caregiver', style: AppTheme.headingLarge),
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

            // Stat cards row
            Row(
              children: const [
                Expanded(
                  child: _StatCard(
                    title: "Today's visits",
                    value: '2',
                    valueColor: AppTheme.textDark,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    title: 'This month',
                    value: 'LKR 7,500',
                    valueColor: AppTheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Next Visit dark card
            const _NextVisitCard(),

            const SizedBox(height: 18),

            Text('Available jobs near you', style: AppTheme.headingMedium),

            const SizedBox(height: 12),

            const _JobCard(
              tag: 'HOSPITAL STAY',
              price: 'LKR 3,000',
              time: 'Tomorrow, 08:00 AM',
            ),

            const SizedBox(height: 12),

            const _JobCard(
              tag: 'HOME VISIT',
              price: 'LKR 2,200',
              time: 'Sat, 10:30 AM',
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
          selectedIndex: _navIndex,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.bodyText.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textGrey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextVisitCard extends StatelessWidget {
  const _NextVisitCard();

  static const _textSoftOnDark = Color(0xFFA9C2BE);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200, // keep your overflow fix
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
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top: 28,
            child: Icon(
              Icons.access_time_rounded,
              size: 92,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXT VISIT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: AppTheme.primary.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'JP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mr. J. Perera',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Today, 2:30 PM',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textSoftOnDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: _textSoftOnDark,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Colombo 05',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textSoftOnDark,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ✅ Let global theme style the button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('Start visit', style: AppTheme.buttonText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String tag;
  final String price;
  final String time;

  const _JobCard({required this.tag, required this.price, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag pill (kept as-is)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFD5E6FF)),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2A6BCB),
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            price,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: AppTheme.textGrey),
              const SizedBox(width: 6),
              Text(
                time,
                style: AppTheme.bodyText.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ✅ Let global theme style the outlined button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: Text(
                'View details',
                style: AppTheme.buttonText.copyWith(color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
