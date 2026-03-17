import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import 'package:carenest_mobileapp/widgets/caregiver_navigationbar_mobile.dart';

class UpdateCareStatusPage extends StatefulWidget {
  const UpdateCareStatusPage({Key? key}) : super(key: key);

  @override
  State<UpdateCareStatusPage> createState() => _UpdateCareStatusPageState();
}

class _UpdateCareStatusPageState extends State<UpdateCareStatusPage> {
  String? selectedStatus;
  final TextEditingController notesController = TextEditingController();
  bool _isSubmitting = false;

  int? _visitId;
  String? _patientName;

  final List<String> statusList = ['In Progress', 'Completed'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && _visitId == null) {
      _visitId = args['visitId'] as int?;
      _patientName = args['patientName'] as String?;
    }
  }

  void updateCareStatus() async {
    if (selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a status')),
      );
      return;
    }

    if (_visitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No visit selected'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('bookings').update({
        'status': selectedStatus,
      }).eq('id', _visitId!);

      // Send notification to patient
      final booking = await supabase
          .from('bookings')
          .select('patient_id, date')
          .eq('id', _visitId!)
          .single();

      final patient = await supabase
          .from('patient_profiles')
          .select('auth_id')
          .eq('id', booking['patient_id'])
          .single();

      final now = DateTime.now();
      await supabase.from('notifications').insert({
        'user_auth_id': patient['auth_id'],
        'title': 'Visit Status Updated',
        'description': 'Your visit on ${booking['date']} has been marked as $selectedStatus',
        'type': 'booking',
        'related_booking': _visitId,
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Care status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
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
          'Update Care Status',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppTheme.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 38, color: AppTheme.textDark),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_patientName ?? 'Patient', style: AppTheme.headingLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Visit ID: ${_visitId ?? '-'}',
                          style: AppTheme.bodyText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            buildCard(
              icon: Icons.medical_services,
              title: 'Care Status',
              child: DropdownButtonFormField<String>(
                value: selectedStatus,
                hint: const Text('Select status'),
                items: statusList.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) => setState(() => selectedStatus = value),
                decoration: const InputDecoration(hintText: 'Select status'),
              ),
            ),

            const SizedBox(height: 30),

            buildCard(
              icon: Icons.note_alt,
              title: 'Care Notes',
              child: TextFormField(
                controller: notesController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Enter care notes...',
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                onPressed: _isSubmitting ? null : updateCareStatus,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Update'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CaregiverNavigationBarMobile(currentIndex: 0),
    );
  }
}
