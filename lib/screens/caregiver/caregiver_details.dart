import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../widgets/carereceiver_navigationbar_mobile.dart';

class CaregiverDetailsPage extends StatefulWidget {
  const CaregiverDetailsPage({super.key});

  @override
  State<CaregiverDetailsPage> createState() => _CaregiverDetailsPageState();
}

class _CaregiverDetailsPageState extends State<CaregiverDetailsPage> {
  final supabase = Supabase.instance.client;
  int selectedTab = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _caregiver;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && _caregiver == null) {
      _loadCaregiver(args as int);
    } else if (args == null && _caregiver == null) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCaregiver(int caregiverId) async {
    try {
      final data = await supabase
          .from('caregiver_profiles')
          .select()
          .eq('id', caregiverId)
          .single();

      // Load reviews for this caregiver
      final reviews = await supabase
          .from('reviews')
          .select('*, patient_profiles(name)')
          .eq('caregiver_id', caregiverId)
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _caregiver = data;
          _reviews = List<Map<String, dynamic>>.from(reviews);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_caregiver == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Caregiver not found')),
      );
    }

    final name = _caregiver!['name'] ?? 'Caregiver';
    final hourlyRate = _caregiver!['hourly_rate']?.toString() ?? '0';
    final verified = _caregiver!['verified'] == true;
    final about = _caregiver!['about'] ?? '';
    final experience = _caregiver!['experience_years']?.toString() ?? '0';
    final serviceArea = _caregiver!['service_area'] ?? '';
    final caregiverId = _caregiver!['id'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header with gradient instead of image
          Stack(
            children: [
              Container(
                height: 260,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (verified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('VERIFIED',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: _circleIcon(Icons.arrow_back, () {
                  Navigator.pop(context);
                }),
              ),
            ],
          ),

          // Info card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTheme.headingLarge),
                          const SizedBox(height: 6),
                          if (verified)
                            Row(
                              children: [
                                Icon(Icons.verified,
                                    color: AppTheme.primary, size: 16),
                                const SizedBox(width: 4),
                                Text('Verified caregiver',
                                    style: AppTheme.bodyText),
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
                        Text('LKR $hourlyRate / hour',
                            style: AppTheme.headingMedium),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat_bubble_outline,
                              size: 16),
                          label: const Text('Chat'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _tabs(),
          ),
          const SizedBox(height: 12),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              child: Column(
                children: [
                  if (selectedTab == 0) ...[
                    if (about.isNotEmpty)
                      _sectionCard('About', [about]),
                    const SizedBox(height: 16),
                    _sectionCard('Details', [
                      'Service area: $serviceArea',
                      'Experience: $experience years',
                    ]),
                    const SizedBox(height: 16),
                    if (verified)
                      _sectionCard('Verification', [
                        'Identity verified',
                        'Background check completed',
                      ]),
                  ],
                  if (selectedTab == 1)
                    _sectionCard('Experience', [
                      '$experience years caregiving experience',
                      if (serviceArea.isNotEmpty)
                        'Serving $serviceArea area',
                    ]),
                  if (selectedTab == 2)
                    _reviews.isEmpty
                        ? Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text('No reviews yet',
                                    style: AppTheme.bodyText),
                              ),
                            ),
                          )
                        : Column(
                            children: _reviews.map((r) {
                              final reviewerName =
                                  r['patient_profiles']?['name'] ??
                                      'Patient';
                              final rating = double.tryParse(
                                      r['rating']?.toString() ?? '0') ??
                                  0;
                              final comment = r['comment'] ?? '';
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(reviewerName,
                                                style: AppTheme
                                                    .headingMedium
                                                    .copyWith(
                                                        fontSize: 14)),
                                            const Spacer(),
                                            ...List.generate(
                                              5,
                                              (i) => Icon(
                                                i < rating.round()
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (comment.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(comment,
                                              style: AppTheme.bodyText),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Book button + nav bar
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/patient_request-caregiver',
                      arguments: caregiverId,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Book this caregiver',
                      style: TextStyle(fontSize: 15)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const CareReceiverNavigationBarMobile(currentIndex: 1),
          ],
        ),
      ),
    );
  }

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
          Text(title,
              style: active ? AppTheme.headingMedium : AppTheme.bodyText),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle,
                        color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item, style: AppTheme.bodyText)),
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
