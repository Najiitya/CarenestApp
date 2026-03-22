import 'dart:typed_data'; // <--- CHANGED THIS: Replaced dart:io with dart:typed_data
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../core/locations.dart';
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
  bool _isSaving = false;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _reviews = [];

  // Edit controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aboutController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _experienceController = TextEditingController();
  final _patientsController = TextEditingController();

  // Dropdown selections
  String? _selectedServiceArea;
  String? _selectedGender;
  final _genderOptions = ['Male', 'Female', 'Other'];

  // ================= WEB-SAFE IMAGE HANDLING =================
  Uint8List? _imageBytes;
  String? _imageExtension;
  final ImagePicker _picker = ImagePicker();
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    _hourlyRateController.dispose();
    _experienceController.dispose();
    _patientsController.dispose();
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

          // Pre-fill controllers
          _nameController.text = profile['name'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _selectedServiceArea = profile['service_area'];
          _selectedGender = profile['gender'];
          _aboutController.text = profile['about'] ?? '';
          _hourlyRateController.text = profile['hourly_rate']?.toString() ?? '0';
          _experienceController.text = profile['experience_years']?.toString() ?? '0';
          _patientsController.text = profile['total_patients']?.toString() ?? '0';

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ================= UPDATED IMAGE PICKER =================
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Read as bytes so it works on Flutter Web!
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageExtension = pickedFile.name.split('.').last;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ================= UPDATED SAVE PROFILE =================
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final uid = supabase.auth.currentUser!.id;
      String? newImageUrl;

      // 1. Upload bytes instead of a File object
      if (_imageBytes != null) {
        final extension = _imageExtension ?? 'jpg';
        final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.$extension';

        // Use uploadBinary which is totally web safe!
        await supabase.storage.from('avatars').uploadBinary(fileName, _imageBytes!);
        newImageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      // 2. Prepare database updates
      final updates = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'service_area': _selectedServiceArea,
        'gender': _selectedGender,
        'about': _aboutController.text.trim(),
        'hourly_rate': double.tryParse(_hourlyRateController.text.trim()) ?? 0,
        'experience_years': int.tryParse(_experienceController.text.trim()) ?? 0,
        'total_patients': int.tryParse(_patientsController.text.trim()) ?? 0,
      };

      if (newImageUrl != null) {
        updates['profile_image_url'] = newImageUrl;
      }

      // 3. Update the database
      await supabase.from('caregiver_profiles').update(updates).eq('auth_id', uid);

      if (mounted) {
        setState(() {
          _profile!['name'] = updates['name'];
          _profile!['phone'] = updates['phone'];
          _profile!['service_area'] = updates['service_area'];
          _profile!['gender'] = updates['gender'];
          _profile!['about'] = updates['about'];
          _profile!['hourly_rate'] = updates['hourly_rate'];
          _profile!['experience_years'] = updates['experience_years'];
          _profile!['total_patients'] = updates['total_patients'];

          if (newImageUrl != null) {
            _profile!['profile_image_url'] = newImageUrl;
          }

          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
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
        bottomNavigationBar: CaregiverNavigationBarMobile(currentIndex: 3),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/caregiver_dashboard'),
          ),
        ),
        body: const Center(child: Text('Profile not found')),
        bottomNavigationBar: const CaregiverNavigationBarMobile(currentIndex: 3),
      );
    }

    final p = _profile!;
    final name = p['name'] ?? 'Caregiver';
    final verified = p['verified'] == true;
    final rating = double.tryParse(p['rating']?.toString() ?? '0') ?? 0;

    final experience = p['experience_years']?.toString() ?? '0';
    final totalPatients = p['total_patients']?.toString() ?? '0';
    final hourlyRate = p['hourly_rate']?.toString() ?? '0';

    final onTimeRate = double.tryParse(p['on_time_rate']?.toString() ?? '0') ?? 0;
    final completionRate = double.tryParse(p['completion_rate']?.toString() ?? '0') ?? 0;
    final satisfactionRating = double.tryParse(p['satisfaction_rating']?.toString() ?? '0') ?? 0;
    final responseTime = p['response_time'] ?? 'N/A';
    final about = p['about'] ?? '';
    final profileImageUrl = p['profile_image_url'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const CaregiverNavigationBarMobile(currentIndex: 3),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pushReplacementNamed(context, '/caregiver_dashboard'),
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
                      _selectedServiceArea = p['service_area'];
                      _selectedGender = p['gender'];
                      _aboutController.text = p['about'] ?? '';
                      _hourlyRateController.text = p['hourly_rate']?.toString() ?? '0';
                      _experienceController.text = p['experience_years']?.toString() ?? '0';
                      _patientsController.text = p['total_patients']?.toString() ?? '0';
                      _imageBytes = null;
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
                    GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.softGreen,
                              // UPDATED TO MEMORY IMAGE FOR WEB SUPPORT
                              backgroundImage: _imageBytes != null
                                  ? MemoryImage(_imageBytes!) as ImageProvider
                                  : (profileImageUrl != null && profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : null),
                              child: (_imageBytes == null && (profileImageUrl == null || profileImageUrl.isEmpty))
                                  ? Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              )
                                  : null,
                            ),
                          ),

                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            )
                          else if (verified)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: AppTheme.headingLarge.copyWith(color: Colors.white, fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    if (verified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('VERIFIED CAREGIVER', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                        _buildQuickStat(Icons.people, '$totalPatients Patients'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                            borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.primary),
                          ),
                        ),
                      ),
                    ),
                  )
                      : about.isNotEmpty
                      ? _buildCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(about, style: AppTheme.bodyText),
                    ),
                  )
                      : _buildCard(
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No bio added yet', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Personal Information', style: AppTheme.headingMedium),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Column(
                      children: [
                        _isEditing
                            ? _buildEditRow(Icons.person, 'Full Name', _nameController)
                            : _buildInfoRow(Icons.person, 'Full Name', name),

                        _isEditing
                            ? _buildDropdownRow(
                                Icons.wc,
                                'Gender',
                                _selectedGender,
                                _genderOptions,
                                (val) => setState(() => _selectedGender = val),
                              )
                            : _buildInfoRow(Icons.wc, 'Gender', p['gender'] ?? 'Not set'),

                        if (_isEditing) ...[
                          _buildEditRow(Icons.payments, 'Hourly Rate (LKR)', _hourlyRateController, isNumber: true),
                          _buildEditRow(Icons.work_history, 'Experience (Years)', _experienceController, isNumber: true),
                          _buildEditRow(Icons.people, 'Total Patients', _patientsController, isNumber: true),
                        ],

                        _buildInfoRow(Icons.badge, 'License Number', p['license_number'] ?? 'N/A'),

                        _isEditing
                            ? _buildEditRow(Icons.phone, 'Phone', _phoneController, isNumber: true)
                            : _buildInfoRow(Icons.phone, 'Phone', p['phone'] ?? 'N/A'),

                        _buildInfoRow(Icons.email, 'Email', p['email'] ?? 'N/A'),

                        _isEditing
                            ? _buildDropdownRow(
                                Icons.location_on,
                                'Service Area',
                                _selectedServiceArea,
                                SriLankanLocations.districts,
                                (val) => setState(() => _selectedServiceArea = val),
                              )
                            : _buildInfoRow(Icons.location_on, 'Service Area', p['service_area'] ?? 'N/A'),

                        _buildInfoRow(Icons.calendar_today, 'Joined', p['created_at']?.toString().split('T')[0] ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Performance Metrics', style: AppTheme.headingMedium),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildMetricRow('On-time Rate', '${onTimeRate.toInt()}%', onTimeRate / 100, Colors.green),
                          const SizedBox(height: 16),
                          _buildMetricRow('Completion Rate', '${completionRate.toInt()}%', completionRate / 100, AppTheme.primary),
                          const SizedBox(height: 16),
                          _buildMetricRow('Patient Satisfaction', '$satisfactionRating/5.0', satisfactionRating / 5, Colors.orange),
                          const SizedBox(height: 16),
                          _buildMetricRow('Response Time', responseTime, 0.95, Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

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
                      final reviewerName = r['patient_profiles']?['name'] ?? 'Patient';
                      final ratingVal = double.tryParse(r['rating']?.toString() ?? '0') ?? 0;
                      final comment = r['comment'] ?? '';
                      final date = r['created_at']?.toString().split('T')[0] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildReviewCard(reviewerName, ratingVal.round(), date, comment),
                      );
                    }),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: AppTheme.error),
                      label: const Text('Logout', style: TextStyle(color: AppTheme.error)),
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
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
            Text(label, style: AppTheme.bodyText.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, fontFamily: 'Poppins')),
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
        border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
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
                Text(label, style: AppTheme.bodyText.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: AppTheme.bodyText.copyWith(color: AppTheme.textDark, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditRow(IconData icon, String label, TextEditingController controller, {bool isNumber = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
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
                Text(label, style: AppTheme.bodyText.copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                  style: AppTheme.bodyText.copyWith(color: AppTheme.textDark, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
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

  Widget _buildDropdownRow(
    IconData icon,
    String label,
    String? currentValue,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
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
                Text(label, style: AppTheme.bodyText.copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: (currentValue != null && options.contains(currentValue))
                      ? currentValue
                      : null,
                  hint: Text('Select $label',
                      style: AppTheme.bodyText.copyWith(color: AppTheme.textGrey)),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                  items: options
                      .map((opt) => DropdownMenuItem(
                            value: opt,
                            child: Text(opt,
                                style: AppTheme.bodyText.copyWith(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w500)),
                          ))
                      .toList(),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.bodyText.copyWith(color: AppTheme.textDark, fontWeight: FontWeight.w500)),
            Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
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

  Widget _buildReviewCard(String name, int rating, String date, String review) {
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
                  child: Text(name.isNotEmpty ? name[0] : 'U', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTheme.bodyText.copyWith(color: AppTheme.textDark, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(date, style: AppTheme.bodyText.copyWith(fontSize: 12)),
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