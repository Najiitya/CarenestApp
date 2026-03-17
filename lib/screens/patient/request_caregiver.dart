import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import 'package:carenest_mobileapp/widgets/carereceiver_navigationbar_mobile.dart';

class RequestCarePage extends StatefulWidget {
  const RequestCarePage({Key? key}) : super(key: key);

  @override
  State<RequestCarePage> createState() => _RequestCarePageState();
}

class _RequestCarePageState extends State<RequestCarePage> {
  String? serviceType;
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool _isSubmitting = false;
  int? _caregiverId;

  final TextEditingController locationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final List<String> serviceTypes = ['Home care', 'Hospital Care'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && _caregiverId == null) {
      _caregiverId = args as int;
    }
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
        suffixIcon: icon != null ? Icon(icon, color: AppTheme.primary) : null,
      ),
      controller: TextEditingController(text: value),
    );
  }

  void submitRequest() async {
    if (serviceType == null ||
        selectedDate == null ||
        startTime == null ||
        endTime == null ||
        locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_caregiverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No caregiver selected. Please go back and select a caregiver.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser!.id;

      // Get patient ID
      final patient = await supabase
          .from('patient_profiles')
          .select('id')
          .eq('auth_id', uid)
          .single();
      final patientId = patient['id'];

      final dateStr = '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
      final startStr = '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}:00';
      final endStr = '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}:00';
      final timeSlot = '${startTime!.format(context)} - ${endTime!.format(context)}';

      // Create booking
      await supabase.from('bookings').insert({
        'patient_id': patientId,
        'caregiver_id': _caregiverId,
        'date': dateStr,
        'start_time': startStr,
        'end_time': endStr,
        'time_slot': timeSlot,
        'service_type': serviceType,
        'location': locationController.text,
        'description': notesController.text,
        'status': 'Pending',
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
        'description': 'You have a new $serviceType request for $dateStr',
        'type': 'booking',
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Care request submitted!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Request Care',
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildCard(
              icon: Icons.medical_services,
              title: 'Service Type',
              child: DropdownButtonFormField<String>(
                value: serviceType,
                hint: const Text('Select service type'),
                items: serviceTypes
                    .map((service) => DropdownMenuItem(value: service, child: Text(service)))
                    .toList(),
                onChanged: (value) => setState(() => serviceType = value),
                decoration: const InputDecoration(hintText: 'Select status'),
              ),
            ),
            const SizedBox(height: 16),

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

            buildCard(
              icon: Icons.access_time,
              title: 'Select Time',
              child: Row(
                children: [
                  Expanded(
                    child: buildDateTimeField(
                      label: 'Start Time',
                      value: startTime == null ? '' : startTime!.format(context),
                      onTap: pickStartTime,
                      icon: Icons.access_time,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildDateTimeField(
                      label: 'End Time',
                      value: endTime == null ? '' : endTime!.format(context),
                      onTap: pickEndTime,
                      icon: Icons.access_time,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            buildCard(
              icon: Icons.location_on,
              title: 'Location',
              child: TextFormField(
                controller: locationController,
                decoration: const InputDecoration(hintText: 'Enter location'),
              ),
            ),

            const SizedBox(height: 16),

            buildCard(
              icon: Icons.note_alt,
              title: 'Additional Notes',
              child: TextFormField(
                controller: notesController,
                maxLines: 5,
                decoration: const InputDecoration(hintText: 'Enter additional notes'),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: _isSubmitting ? null : submitRequest,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Request'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),

      bottomNavigationBar: const CareReceiverNavigationBarMobile(currentIndex: 1),
    );
  }
}
