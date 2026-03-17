import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../core/locations.dart';
import '../../widgets/carereceiver_navigationbar_mobile.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _profile;

  // Edit controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Dropdown selections
  String? _selectedGender;
  String? _selectedBloodType;
  String? _selectedLocation;

  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];
  static const List<String> _bloodTypeOptions = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  // Web-safe image handling
  Uint8List? _imageBytes;
  String? _imageExtension;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = supabase.auth.currentUser!.id;

      final profile = await supabase
          .from('patient_profiles')
          .select()
          .eq('auth_id', uid)
          .single();

      if (mounted) {
        setState(() {
          _profile = profile;
          _populateControllers(profile);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateControllers(Map<String, dynamic> p) {
    _nameController.text = p['name'] ?? '';
    _phoneController.text = p['phone'] ?? '';
    _addressController.text = p['address'] ?? '';
    _dobController.text = p['date_of_birth'] ?? '';
    _heightController.text = p['height_cm']?.toString() ?? '';
    _weightController.text = p['weight_kg']?.toString() ?? '';
    _selectedGender = p['gender'];
    _selectedBloodType = p['blood_type'];
    _selectedLocation = p['location'];
  }

  // Calculate age from date of birth string (YYYY-MM-DD)
  int? _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  // Show bottom sheet to pick image from camera or gallery
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Change Profile Photo',
                style: AppTheme.headingMedium.copyWith(fontSize: 18)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: AppTheme.primary),
              ),
              title: const Text('Take a Photo'),
              subtitle: const Text('Use your camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: AppTheme.primary),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Pick from your photos'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imageBytes != null ||
                (_profile?['profile_image_url'] != null &&
                    _profile!['profile_image_url'].toString().isNotEmpty))
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppTheme.error),
                ),
                title: const Text('Remove Photo'),
                subtitle: const Text('Use default avatar'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageBytes = null;
                    _imageExtension = null;
                    _profile!['profile_image_url'] = '';
                  });
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageExtension = pickedFile.name.split('.').last;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error picking image: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // Date picker for DOB
  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = DateTime.tryParse(_dobController.text) ?? DateTime(2000, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final uid = supabase.auth.currentUser!.id;
      String? newImageUrl;

      // 1. Upload new image
      if (_imageBytes != null) {
        final extension = _imageExtension ?? 'jpg';
        final fileName = '$uid.$extension';

        await supabase.storage.from('avatars').uploadBinary(
          fileName,
          _imageBytes!,
          fileOptions: const FileOptions(upsert: true),
        );
        newImageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
        // Append cache-buster so the new image loads immediately
        newImageUrl = '$newImageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      // Calculate BMI
      double? height = double.tryParse(_heightController.text.trim());
      double? weight = double.tryParse(_weightController.text.trim());
      double? bmi;

      if (height != null && weight != null && height > 0) {
        double heightInMeters = height / 100;
        bmi = weight / (heightInMeters * heightInMeters);
      }

      // Calculate age from DOB
      final age = _calculateAge(_dobController.text.trim());

      // 2. Prepare database updates — ensure no empty strings for typed columns
      final dobText = _dobController.text.trim();
      final nameText = _nameController.text.trim();
      final phoneText = _phoneController.text.trim();
      final addressText = _addressController.text.trim();

      final updates = <String, dynamic>{
        'name': nameText.isEmpty ? null : nameText,
        'phone': phoneText.isEmpty ? null : phoneText,
        'address': addressText.isEmpty ? null : addressText,
        'date_of_birth': dobText.isEmpty ? null : dobText,
        'gender': _selectedGender,
        'blood_type': _selectedBloodType,
        'location': _selectedLocation,
        'height_cm': height,
        'weight_kg': weight,
        'bmi': bmi != null ? double.parse(bmi.toStringAsFixed(1)) : null,
        'age': age,
      };

      if (newImageUrl != null) {
        updates['profile_image_url'] = newImageUrl;
      }

      // Handle photo removal
      if (_imageBytes == null &&
          (_profile!['profile_image_url'] == null ||
              _profile!['profile_image_url'].toString().isEmpty)) {
        updates['profile_image_url'] = '';
      }

      // 3. Send update to Supabase
      await supabase
          .from('patient_profiles')
          .update(updates)
          .eq('auth_id', uid);

      if (mounted) {
        setState(() {
          _profile!['name'] = updates['name'];
          _profile!['phone'] = updates['phone'];
          _profile!['address'] = updates['address'];
          _profile!['date_of_birth'] = updates['date_of_birth'];
          _profile!['gender'] = updates['gender'];
          _profile!['blood_type'] = updates['blood_type'];
          _profile!['location'] = updates['location'];
          _profile!['height_cm'] = updates['height_cm'];
          _profile!['weight_kg'] = updates['weight_kg'];
          _profile!['age'] = updates['age'];
          if (bmi != null) _profile!['bmi'] = updates['bmi'];
          if (newImageUrl != null) {
            _profile!['profile_image_url'] = newImageUrl;
          }

          _isEditing = false;
          _isSaving = false;
          _imageBytes = null;
          _imageExtension = null;
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
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
        bottomNavigationBar:
            CareReceiverNavigationBarMobile(currentIndex: 3),
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
        bottomNavigationBar:
            const CareReceiverNavigationBarMobile(currentIndex: 3),
      );
    }

    final p = _profile!;
    final name = p['name'] ?? 'Patient';
    final patientCode = p['patient_code'] ?? '';
    final gender = p['gender'] ?? 'N/A';
    final bloodType = p['blood_type'] ?? 'N/A';
    final heightCm = p['height_cm']?.toString() ?? 'N/A';
    final weightKg = p['weight_kg']?.toString() ?? 'N/A';
    final bmi = p['bmi']?.toString() ?? 'N/A';
    final profileImageUrl = p['profile_image_url'];

    // Auto-calculate age from DOB for display
    final dob = _isEditing ? _dobController.text : (p['date_of_birth'] ?? '');
    final calculatedAge = _calculateAge(dob);
    final ageDisplay = calculatedAge != null ? '$calculatedAge' : (p['age']?.toString() ?? 'N/A');

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar:
          const CareReceiverNavigationBarMobile(currentIndex: 3),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
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
                      _populateControllers(p);
                      _imageBytes = null;
                      _imageExtension = null;
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
                    // Profile Picture
                    GestureDetector(
                      onTap: _isEditing ? _showImagePickerOptions : null,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 4),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.softGreen,
                              backgroundImage: _imageBytes != null
                                  ? MemoryImage(_imageBytes!)
                                      as ImageProvider
                                  : (profileImageUrl != null &&
                                          profileImageUrl
                                              .toString()
                                              .isNotEmpty
                                      ? NetworkImage(profileImageUrl)
                                      : null),
                              child: (_imageBytes == null &&
                                      (profileImageUrl == null ||
                                          profileImageUrl
                                              .toString()
                                              .isEmpty))
                                  ? Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'P',
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
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(name,
                        style: AppTheme.headingLarge
                            .copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    if (patientCode.isNotEmpty)
                      Text('Patient ID: #$patientCode',
                          style: AppTheme.bodyText.copyWith(
                              color: Colors.white.withOpacity(0.9))),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        _buildQuickStat(
                            Icons.calendar_today, '$ageDisplay years'),
                        _buildQuickStat(Icons.transgender, gender),
                        _buildQuickStat(Icons.bloodtype, bloodType),
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
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: Text(
                            _isSaving ? 'Saving...' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text('Personal Information',
                      style: AppTheme.headingMedium),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _isEditing
                        ? _buildEditRow(
                            Icons.person, 'Full Name', _nameController)
                        : _buildInfoRow(
                            Icons.person, 'Full Name', name),
                    _isEditing
                        ? _buildDatePickerRow(
                            Icons.cake, 'Date of Birth', _dobController)
                        : _buildInfoRow(Icons.cake, 'Date of Birth',
                            p['date_of_birth'] ?? 'N/A'),
                    _isEditing
                        ? _buildDropdownRow(
                            Icons.transgender,
                            'Gender',
                            _selectedGender,
                            _genderOptions,
                            (val) => setState(
                                () => _selectedGender = val),
                          )
                        : _buildInfoRow(
                            Icons.transgender, 'Gender', gender),
                    _isEditing
                        ? _buildEditRow(Icons.phone, 'Phone',
                            _phoneController,
                            isNumber: true)
                        : _buildInfoRow(
                            Icons.phone, 'Phone', p['phone'] ?? 'N/A'),
                    _buildInfoRow(
                        Icons.email, 'Email', p['email'] ?? 'N/A'),
                    _isEditing
                        ? _buildDropdownRow(
                            Icons.location_on,
                            'Location (District)',
                            _selectedLocation,
                            SriLankanLocations.districts,
                            (val) => setState(
                                () => _selectedLocation = val),
                          )
                        : _buildInfoRow(Icons.location_on, 'Location',
                            p['location'] ?? 'N/A'),
                    _isEditing
                        ? _buildEditRow(Icons.home, 'Address',
                            _addressController)
                        : _buildInfoRow(Icons.home, 'Address',
                            p['address'] ?? 'N/A'),
                  ]),
                  const SizedBox(height: 24),

                  Text('Medical Information',
                      style: AppTheme.headingMedium),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _isEditing
                        ? _buildDropdownRow(
                            Icons.bloodtype,
                            'Blood Type',
                            _selectedBloodType,
                            _bloodTypeOptions,
                            (val) => setState(
                                () => _selectedBloodType = val),
                          )
                        : _buildInfoRow(
                            Icons.bloodtype, 'Blood Type', bloodType),
                    _isEditing
                        ? _buildEditRow(Icons.height, 'Height (cm)',
                            _heightController,
                            isNumber: true)
                        : _buildInfoRow(
                            Icons.height, 'Height', '$heightCm cm'),
                    _isEditing
                        ? _buildEditRow(Icons.monitor_weight,
                            'Weight (kg)', _weightController,
                            isNumber: true)
                        : _buildInfoRow(Icons.monitor_weight, 'Weight',
                            '$weightKg kg'),
                    _buildInfoRow(Icons.favorite, 'BMI', bmi),
                    _buildInfoRow(Icons.calendar_today, 'Age',
                        ageDisplay == 'N/A' ? 'N/A' : '$ageDisplay years'),
                  ]),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout,
                          color: AppTheme.error),
                      label: const Text('Logout',
                          style: TextStyle(color: AppTheme.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildInfoCard(List<Widget> children) {
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
      child: Column(children: children),
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
      IconData icon, String label, TextEditingController controller,
      {bool isNumber = false}) {
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
                  keyboardType: isNumber
                      ? TextInputType.number
                      : TextInputType.text,
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
                      borderSide:
                          BorderSide(color: AppTheme.primary),
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

  // Date picker row - taps open a native date picker
  Widget _buildDatePickerRow(
      IconData icon, String label, TextEditingController controller) {
    return GestureDetector(
      onTap: _pickDateOfBirth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
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
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: AppTheme.primary.withOpacity(0.3)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            controller.text.isEmpty
                                ? 'Tap to select date'
                                : controller.text,
                            style: AppTheme.bodyText.copyWith(
                              color: controller.text.isEmpty
                                  ? AppTheme.textGrey
                                  : AppTheme.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.calendar_month,
                            color: AppTheme.primary, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dropdown row for gender and blood type selection
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
                DropdownButtonFormField<String>(
                  value: (currentValue != null &&
                          options.contains(currentValue))
                      ? currentValue
                      : null,
                  hint: Text('Select $label',
                      style: AppTheme.bodyText
                          .copyWith(color: AppTheme.textGrey)),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 4),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppTheme.primary),
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
}
