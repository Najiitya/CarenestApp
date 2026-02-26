import 'package:flutter/material.dart';
import 'package:carenest_mobile/core/app_theme.dart';
import 'package:carenest_mobile/widgets/carereceiver_navigationbar_mobile.dart';

class CaregiverDetailsPage extends StatefulWidget {
  const CaregiverDetailsPage({super.key});

  @override
  State<CaregiverDetailsPage> createState() => _CaregiverDetailsPageState();
}

class _CaregiverDetailsPageState extends State<CaregiverDetailsPage> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Column(
        children: [
          // ================= HEADER =================
          Stack(
            children: [
              Image.asset(
                'assets/images/caregiver_header.jpg',
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 40,
                left: 16,
                child: _circleIcon(Icons.arrow_back, () {
                  Navigator.pop(context);
                }),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: _circleIcon(Icons.favorite_border, () {}),
              ),
            ],
          ),

          // ================= INFO CARD =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _infoCard(),
          ),

          // ================= TABS =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _tabs(),
          ),

          const SizedBox(height: 12),

          // ================= CONTENT =================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              child: Column(
                children: [
                  if (selectedTab == 0) ...[
                    _servicesCard(),
                    const SizedBox(height: 16),
                    _languagesCard(),
                    const SizedBox(height: 16),
                    _verificationCard(),
                  ],
                  if (selectedTab == 1)
                    _sectionCard('Experience', const [
                      '5+ years caregiving experience',
                      'Worked in hospital & home care',
                    ]),
                  if (selectedTab == 2)
                    _sectionCard('Reviews', const [
                      'Very kind and professional',
                      'Highly recommended caregiver',
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),

      // ================= BOOK BUTTON + CARE RECEIVER NAV =================
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // BOOK BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Book this caregiver',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ✅ CARE RECEIVER NAVIGATION BAR
            const CareReceiverNavigationBarMobile(
              currentIndex: 1, // Find Care selected
            ),
          ],
        ),
      ),
    );
  }

  // ================= INFO CARD =================

  Widget _infoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kumari Perera', style: AppTheme.headingLarge),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.verified, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 4),
                      Text('Verified caregiver', style: AppTheme.bodyText),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 10),
                Text('LKR 800 / hour', style: AppTheme.headingMedium),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= TABS =================

  Widget _tabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _tabItem('Overview', 0),
        _tabItem('Experience', 1),
        _tabItem('Reviews', 2),
      ],
    );
  }

  Widget _tabItem(String title, int index) {
    final bool active = selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: active ? AppTheme.headingMedium : AppTheme.bodyText,
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            width: 40,
            color: active ? AppTheme.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _servicesCard() => _sectionCard('Services', const [
    'Elderly care',
    'Post-operative support',
    'Medication management',
  ]);

  Widget _languagesCard() =>
      _sectionCard('Languages', const ['Sinhala', 'English', 'Tamil']);

  Widget _verificationCard() => _sectionCard('Verification', const [
    'Identity verified',
    'Police clearance report',
    'Medical documents',
  ]);

  Widget _sectionCard(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.headingMedium),
            const SizedBox(height: 12),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item, style: AppTheme.bodyText)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(icon, color: AppTheme.primary),
      ),
    );
  }
}
