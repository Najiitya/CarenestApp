import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../widgets/caregiver_navigationbar_mobile.dart';

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({super.key});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _patient;
  Map<String, dynamic>? _pendingBooking; // To store a pending request if it exists
  int? _patientId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && _patientId == null) {
      _patientId = int.tryParse(args.toString());
      if (_patientId != null) {
        _loadData();
      } else {
        setState(() => _isLoading = false);
      }
    } else if (args == null && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    try {
      // 1. Fetch the patient's medical profile
      final patientData = await supabase
          .from('patient_profiles')
          .select()
          .eq('id', _patientId!)
          .single();

      // 2. Find out who the currently logged-in caregiver is
      final uid = supabase.auth.currentUser!.id;
      final caregiverData = await supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('auth_id', uid)
          .single();
      final caregiverId = caregiverData['id'];

      // 3. Check if there is a 'Pending' booking between this patient and caregiver
      final bookingData = await supabase
          .from('bookings')
          .select()
          .eq('patient_id', _patientId!)
          .eq('caregiver_id', caregiverId)
          .eq('status', 'Pending')
          .maybeSingle(); // maybeSingle() won't throw an error if no pending booking is found

      if (mounted) {
        setState(() {
          _patient = patientData;
          _pendingBooking = bookingData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ================= ACCEPT BOOKING =================
  Future<void> _acceptBooking() async {
    if (_pendingBooking == null) return;
    try {
      await supabase
          .from('bookings')
          .update({'status': 'Accepted'})
          .eq('id', _pendingBooking!['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit Accepted!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Go back to the Jobs page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ================= DECLINE BOOKING =================
  Future<void> _declineBooking() async {
    if (_pendingBooking == null) return;
    try {
      await supabase
          .from('bookings')
          .update({'status': 'Cancelled'})
          .eq('id', _pendingBooking!['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit Declined'), backgroundColor: Colors.grey),
        );
        Navigator.pop(context); // Go back to the Jobs page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeclineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Decline Request?'),
        content: const Text('Are you sure you want to decline this visit request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _declineBooking();
            },
            child: const Text('Yes, Decline', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_patient == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(backgroundColor: AppTheme.primary, elevation: 0),
        body: const Center(child: Text("Patient profile not found.")),
      );
    }

    // Extracting data
    final name = _patient?['name'] ?? 'N/A';
    final initials = name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : 'P';
    final age = _patient?['age']?.toString() ?? 'N/A';
    final gender = _patient?['gender'] ?? 'N/A';
    final bloodType = _patient?['blood_type'] ?? 'N/A';
    final dob = _patient?['date_of_birth'] ?? 'N/A';
    final phone = _patient?['phone'] ?? 'N/A';
    final email = _patient?['email'] ?? 'N/A';
    final address = _patient?['address'] ?? 'N/A';
    final height = _patient?['height_cm']?.toString() ?? 'N/A';
    final weight = _patient?['weight_kg']?.toString() ?? 'N/A';
    final bmi = _patient?['bmi']?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.primary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppTheme.softGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: AppTheme.headingLarge.copyWith(color: Colors.white)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text('$age years', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 16),
                        const Icon(Icons.transgender, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(gender, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 16),
                        const Icon(Icons.bloodtype, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(bloodType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                  Text('Personal Information', style: AppTheme.headingMedium),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person, 'Full Name', name),
                        _buildDivider(),
                        _buildInfoRow(Icons.cake, 'Date of Birth', dob),
                        _buildDivider(),
                        _buildInfoRow(Icons.phone, 'Phone', phone),
                        _buildDivider(),
                        _buildInfoRow(Icons.email, 'Email', email),
                        _buildDivider(),
                        _buildInfoRow(Icons.location_on, 'Address', address),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Medical Information', style: AppTheme.headingMedium),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.water_drop, 'Blood Type', bloodType),
                        _buildDivider(),
                        _buildInfoRow(Icons.height, 'Height', height != 'N/A' ? '$height cm' : 'N/A'),
                        _buildDivider(),
                        _buildInfoRow(Icons.monitor_weight, 'Weight', weight != 'N/A' ? '$weight kg' : 'N/A'),
                        _buildDivider(),
                        _buildInfoRow(Icons.favorite, 'BMI', bmi),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // ================= BOTTOM ACTIONS & NAV BAR =================
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Only show Accept/Decline buttons if there is a pending booking!
          if (_pendingBooking != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _acceptBooking,
                      icon: const Icon(Icons.check),
                      label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.softGreen,
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showDeclineDialog,
                      icon: const Icon(Icons.close),
                      label: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // The bottom navigation bar
          const CaregiverNavigationBarMobile(currentIndex: 1), // Assuming they came from Jobs tab
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF7A8A96), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey.shade100, thickness: 1),
    );
  }
}