import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
// 1. ADDED THE IMPORT HERE
import '../../widgets/caregiver_navigationbar_mobile.dart';

class CaregiverProfilePage extends StatefulWidget {
  const CaregiverProfilePage({super.key});

  @override
  State<CaregiverProfilePage> createState() => _CaregiverProfilePageState();
}

class _CaregiverProfilePageState extends State<CaregiverProfilePage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isEditing = false;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _reviews = [];

  // Edit controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _serviceAreaController = TextEditingController();
  final _aboutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _serviceAreaController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = supabase.auth.currentUser!.id;

      final profile = await supabase
          .from('caregiver_profiles')
          .select()
          .eq('auth_id', uid)
          .single();

      final caregiverId = profile['id'];

      // Load reviews
      final reviews = await supabase
          .from('reviews')
          .select('*, patient_profiles(name)')
          .eq('caregiver_id', caregiverId)
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _profile = profile;
          _reviews = List<Map<String, dynamic>>.from(reviews);
          _nameController.text = profile['name'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _serviceAreaController.text = profile['service_area'] ?? '';
          _aboutController.text = profile['about'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      final uid = supabase.auth.currentUser!.id;

      await supabase.from('caregiver_profiles').update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'service_area': _serviceAreaController.text.trim(),
        'about': _aboutController.text.trim(),
      }).eq('auth_id', uid);

      if (mounted) {
        setState(() {
          _profile!['name'] = _nameController.text.trim();
          _profile!['phone'] = _phoneController.text.trim();
          _profile!['service_area'] = _serviceAreaController.text.trim();
          _profile!['about'] = _aboutController.text.trim();
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        // 2. ADDED NAV BAR HERE
        bottomNavigationBar: CaregiverNavigationBarMobile(currentIndex: 2),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Profile not found')),
        // 3. ADDED NAV BAR HERE
        bottomNavigationBar: const CaregiverNavigationBarMobile(currentIndex: 2),
      );
    }

    final p = _profile!;
    final name = p['name'] ?? 'Caregiver';
    final verified = p['verified'] == true;
    final rating = double.tryParse(p['rating']?.toString() ?? '0') ?? 0;
    final experience = p['experience_years']?.toString() ?? '0';
    final totalPatients = p['total_patients']?.toString() ?? '0';
    final onTimeRate =
        double.tryParse(p['on_time_rate']?.toString() ?? '0') ?? 0;
    final completionRate =
        double.tryParse(p['completion_rate']?.toString() ?? '0') ?? 0;
    final satisfactionRating =
        double.tryParse(p['satisfaction_rating']?.toString() ?? '0') ?? 0;
    final responseTime = p['response_time'] ?? 'N/A';
    final about = p['about'] ?? '';
    final hourlyRate = p['hourly_rate']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: AppTheme.background,
      // 4. ADDED NAV BAR TO THE MAIN UI HERE
      bottomNavigationBar: const CaregiverNavigationBarMobile(currentIndex: 2),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if (_isEditing) {
                      // Cancel editing - restore values
                      _nameController.text = p['name'] ?? '';
                      _phoneController.text = p['phone'] ?? '';
                      _serviceAreaController.text = p['service_area'] ?? '';
                      _aboutController.text = p['about'] ?? '';
                    }
                    _isEditing = !_isEditing;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _handleLogout,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                    const SizedBox(height: 60),
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.softGreen,
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        if (verified)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: AppTheme.headingLarge
                          .copyWith(color: Colors.white, fontSize: 22),
                    ),
                    const SizedBox(height: 4),
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
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('VERIFIED CAREGIVER',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        _buildQuickStat(Icons.star, '$rating'),
                        _buildQuickStat(Icons.work, '$experience Years'),
                        _buildQuickStat(
                            Icons.people, '$totalPatients Patients'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Edit mode save button
                  if (_isEditing) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                            'Hourly Rate',
                            'LKR $hourlyRate',
                            Icons.account_balance_wallet,
                            AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Experience', '$experience yrs',
                            Icons.work_history, Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About
                  Text('About Me', style: AppTheme.headingMedium),
                  const SizedBox(height: 12),
                  _isEditing
                      ? _buildCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _aboutController,
                        maxLines: 4,
                        style: AppTheme.bodyText.copyWith(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Tell patients about yourself...',
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                AppTheme.primary.withOpacity(0.3)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide:
                            BorderSide(color: AppTheme.primary),
                          ),
                        ),
                      ),
                    ),
                  )
                      : about.isNotEmpty
                      ? _buildCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child:
                      Text(about, style: AppTheme.bodyText),
                    ),
                  )
                      : _buildCard(
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No bio added yet',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Information
                  Text('Personal Information', style: AppTheme.headingMedium),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Column(
                      children: [
                        _isEditing
                            ? _buildEditRow(
                            Icons.person, 'Full Name', _nameController)
                            : _buildInfoRow(Icons.person, 'Full Name', name),
                        _buildInfoRow(Icons.badge, 'License Number',
                            p['license_number'] ?? 'N/A'),
                        _isEditing
                            ? _buildEditRow(
                            Icons.phone, 'Phone', _phoneController)
                            : _buildInfoRow(
                            Icons.phone, 'Phone', p['phone'] ?? 'N/A'),
                        _buildInfoRow(
                            Icons.email, 'Email', p['email'] ?? 'N/A'),
                        _isEditing
                            ? _buildEditRow(Icons.location_on, 'Service Area',
                            _serviceAreaController)
                            : _buildInfoRow(Icons.location_on, 'Service Area',
                            p['service_area'] ?? 'N/A'),
                        _buildInfoRow(
                            Icons.calendar_today,
                            'Joined',
                            p['created_at']?.toString().split('T')[0] ??
                                'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Performance Metrics
                  Text('Performance Metrics', style: AppTheme.headingMedium),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildMetricRow('On-time Rate',
                              '${onTimeRate.toInt()}%', onTimeRate / 100, Colors.green),
                          const SizedBox(height: 16),
                          _buildMetricRow(
                              'Completion Rate',
                              '${completionRate.toInt()}%',
                              completionRate / 100,
                              AppTheme.primary),
                          const SizedBox(height: 16),
                          _buildMetricRow(
                              'Patient Satisfaction',
                              '$satisfactionRating/5.0',
                              satisfactionRating / 5,
                              Colors.orange),
                          const SizedBox(height: 16),
                          _buildMetricRow('Response Time', responseTime,
                              0.95, Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reviews
                  Text('Patient Reviews', style: AppTheme.headingMedium),
                  const SizedBox(height: 12),
                  if (_reviews.isEmpty)
                    _buildCard(
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No reviews yet')),
                      ),
                    )
                  else
                    ..._reviews.map((r) {
                      final reviewerName =
                          r['patient_profiles']?['name'] ?? 'Patient';
                      final ratingVal =
                          double.tryParse(r['rating']?.toString() ?? '0') ??
                              0;
                      final comment = r['comment'] ?? '';
                      final date =
                          r['created_at']?.toString().split('T')[0] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildReviewCard(
                            reviewerName, ratingVal.round(), date, comment),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: AppTheme.error),
                      label: const Text('Logout',
                          style: TextStyle(color: AppTheme.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────

  Widget _buildQuickStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: AppTheme.bodyText.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border:
        Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTheme.bodyText.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTheme.bodyText.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditRow(
      IconData icon, String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border:
        Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTheme.bodyText.copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  style: AppTheme.bodyText.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 8),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
      String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textDark, fontWeight: FontWeight.w500)),
            Text(value,
                style: TextStyle(
                    fontSize: 14, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[100],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(
      String name, int rating, String date, String review) {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.softGreen,
                  child: Text(name[0],
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: AppTheme.bodyText.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(date,
                          style:
                          AppTheme.bodyText.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                      5,
                          (i) => Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      )),
                ),
              ],
            ),
            if (review.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(review, style: AppTheme.bodyText),
            ],
          ],
        ),
      ),
    );
  }
}