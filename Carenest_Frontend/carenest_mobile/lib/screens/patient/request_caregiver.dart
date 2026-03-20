import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../core/locations.dart';
import '../../widgets/carereceiver_navigationbar_mobile.dart';

class RequestCarePage extends StatefulWidget {
  const RequestCarePage({Key? key}) : super(key: key);

  @override
  State<RequestCarePage> createState() => _RequestCarePageState();
}

class _RequestCarePageState extends State<RequestCarePage> {
  final supabase = Supabase.instance.client;

  String? serviceType;
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool _isSubmitting = false;
  int? _caregiverId;
  String? _selectedLocation;

  // Caregiver info for payment calculation
  double _hourlyRate = 0;
  String _caregiverName = '';

  final TextEditingController notesController = TextEditingController();

  final List<String> serviceTypes = ['Home Visit', 'Hospital'];

  @override
  void initState() {
    super.initState();
    _loadPatientLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && _caregiverId == null) {
      _caregiverId = args as int;
      _loadCaregiverInfo();
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientLocation() async {
    try {
      final uid = supabase.auth.currentUser!.id;
      final patient = await supabase
          .from('patient_profiles')
          .select('location')
          .eq('auth_id', uid)
          .single();
      if (mounted && patient['location'] != null) {
        setState(() {
          _selectedLocation = patient['location'];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCaregiverInfo() async {
    try {
      final caregiver = await supabase
          .from('caregiver_profiles')
          .select('name, hourly_rate')
          .eq('id', _caregiverId!)
          .single();

      if (mounted) {
        setState(() {
          _caregiverName = caregiver['name'] ?? 'Caregiver';
          _hourlyRate = double.tryParse(
                  caregiver['hourly_rate']?.toString() ?? '0') ??
              0;
        });
      }
    } catch (_) {}
  }

  /// Calculate estimated payment from start/end time and hourly rate
  double get _estimatedPayment {
    if (startTime == null || endTime == null || _hourlyRate == 0) return 0;
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    final diffMinutes = endMinutes - startMinutes;
    if (diffMinutes <= 0) return 0;
    final hours = diffMinutes / 60.0;
    return hours * _hourlyRate;
  }

  double get _estimatedHours {
    if (startTime == null || endTime == null) return 0;
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    final diffMinutes = endMinutes - startMinutes;
    if (diffMinutes <= 0) return 0;
    return diffMinutes / 60.0;
  }

  Future<void> pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> pickStartTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => startTime = time);
    }
  }

  Future<void> pickEndTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => endTime = time);
    }
  }

  Widget buildDateTimeField({
    required String label,
    required String value,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      style: AppTheme.bodyText.copyWith(color: AppTheme.textDark),
      decoration: InputDecoration(
        hintText: value.isEmpty ? 'Select' : value,
        suffixIcon:
            icon != null ? Icon(icon, color: AppTheme.primary) : null,
      ),
      controller: TextEditingController(text: value),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> submitRequest() async {
    if (serviceType == null ||
        selectedDate == null ||
        startTime == null ||
        endTime == null ||
        _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_estimatedHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = supabase.auth.currentUser!.id;

      final patientProfile = await supabase
          .from('patient_profiles')
          .select('id')
          .eq('auth_id', uid)
          .single();

      final patientId = patientProfile['id'];
      final dateStr = selectedDate!.toIso8601String().split('T')[0];
      final bookingId =
          'BK-${DateTime.now().millisecondsSinceEpoch}';

      await supabase.from('bookings').insert({
        'id': bookingId,
        'patient_id': patientId,
        'caregiver_id': _caregiverId,
        'service_type': serviceType,
        'status': 'Pending',
        'date': dateStr,
        'start_time': _formatTimeOfDay(startTime!),
        'end_time': _formatTimeOfDay(endTime!),
        'time_slot':
            '${startTime!.format(context)} - ${endTime!.format(context)}',
        'location': _selectedLocation,
        'description': notesController.text.trim(),
      });

      // Send notification to caregiver
      final caregiver = await supabase
          .from('caregiver_profiles')
          .select('auth_id')
          .eq('id', _caregiverId!)
          .single();

      final now = DateTime.now();
      await supabase.from('notifications').insert({
        'user_auth_id': caregiver['auth_id'],
        'title': 'New Care Request',
        'description':
            'You have a new $serviceType request for $dateStr in $_selectedLocation.',
        'type': 'booking',
        'related_booking': bookingId,
        'date':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Care request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(title, style: AppTheme.headingMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final payment = _estimatedPayment;
    final hours = _estimatedHours;

    if (payment <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E3C3A), Color(0xFF062C2B)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'PAYMENT ESTIMATE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Caregiver name
          if (_caregiverName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.white54),
                  const SizedBox(width: 8),
                  Text(
                    _caregiverName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          // Breakdown
          _paymentRow('Hourly Rate', 'LKR ${_hourlyRate.toInt()}'),
          const SizedBox(height: 8),
          _paymentRow('Duration', '${hours.toStringAsFixed(1)} hours'),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'LKR ${payment.toInt()}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0EA5A0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Payment to be made directly to the caregiver',
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.white54)),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: true,
        title: Text('Request Care',
            style: AppTheme.headingMedium.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Service Type
            buildCard(
              icon: Icons.medical_services,
              title: 'Service Type',
              child: DropdownButtonFormField<String>(
                value: serviceType,
                hint: const Text('Select service type'),
                items: serviceTypes
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => serviceType = v),
                decoration:
                    const InputDecoration(hintText: 'Select status'),
              ),
            ),
            const SizedBox(height: 16),

            // Date
            buildCard(
              icon: Icons.calendar_today,
              title: 'Select Date',
              child: buildDateTimeField(
                label: 'Select Date',
                value: selectedDate == null
                    ? 'Select Date'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                icon: Icons.calendar_today,
                onTap: pickDate,
              ),
            ),
            const SizedBox(height: 16),

            // Time
            buildCard(
              icon: Icons.access_time,
              title: 'Select Time',
              child: Row(
                children: [
                  Expanded(
                    child: buildDateTimeField(
                      label: 'Start Time',
                      value: startTime == null
                          ? ''
                          : startTime!.format(context),
                      onTap: pickStartTime,
                      icon: Icons.access_time,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildDateTimeField(
                      label: 'End Time',
                      value: endTime == null
                          ? ''
                          : endTime!.format(context),
                      onTap: pickEndTime,
                      icon: Icons.access_time,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location
            buildCard(
              icon: Icons.location_on,
              title: 'Location',
              child: DropdownButtonFormField<String>(
                value: _selectedLocation,
                hint: const Text('Select location'),
                items: SriLankanLocations.districts
                    .map((loc) => DropdownMenuItem(
                          value: loc,
                          child: Text(loc),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedLocation = v),
                decoration:
                    const InputDecoration(hintText: 'Select location'),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            buildCard(
              icon: Icons.note_alt,
              title: 'Additional Notes',
              child: TextFormField(
                controller: notesController,
                maxLines: 5,
                decoration: const InputDecoration(
                    hintText: 'Enter additional notes'),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Estimate (shows when times are selected)
            _buildPaymentSummary(),

            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                onPressed: _isSubmitting ? null : submitRequest,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _estimatedPayment > 0
                            ? 'Request (LKR ${_estimatedPayment.toInt()})'
                            : 'Request',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar:
          const CareReceiverNavigationBarMobile(currentIndex: 1),
    );
  }
}
