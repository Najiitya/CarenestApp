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
  final supabase = Supabase.instance.client;

  final TextEditingController notesController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _paymentReceived = false;
  String? _bookingId;
  Map<String, dynamic>? _booking;
  Map<String, dynamic>? _patient;
  double _hourlyRate = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && _bookingId == null) {
      _bookingId = args.toString();
      _loadBooking(_bookingId!);
    } else if (args == null && _bookingId == null) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  /// Calculate hours between two TIME strings
  double _calculateHours(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return 1;
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes =
          int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final diff = (endMinutes - startMinutes) / 60.0;
      return diff > 0 ? diff : 1;
    } catch (_) {
      return 1;
    }
  }

  Future<void> _loadBooking(String bookingId) async {
    try {
      final booking = await supabase
          .from('bookings')
          .select('*, patient_profiles(name, auth_id)')
          .eq('id', bookingId)
          .single();

      // Get caregiver hourly rate
      final uid = supabase.auth.currentUser!.id;
      final profile = await supabase
          .from('caregiver_profiles')
          .select('hourly_rate')
          .eq('auth_id', uid)
          .single();

      if (mounted) {
        setState(() {
          _booking = booking;
          _patient = booking['patient_profiles'];
          _hourlyRate = double.tryParse(
                  profile['hourly_rate']?.toString() ?? '0') ??
              0;
          notesController.text = booking['care_notes'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _paymentAmount {
    if (_booking == null || _hourlyRate == 0) return 0;
    final hours = _calculateHours(
      _booking!['start_time']?.toString(),
      _booking!['end_time']?.toString(),
    );
    return hours * _hourlyRate;
  }

  double get _sessionHours {
    if (_booking == null) return 0;
    return _calculateHours(
      _booking!['start_time']?.toString(),
      _booking!['end_time']?.toString(),
    );
  }

  // ================= COMPLETION LOGIC =================
  Future<void> completeSession() async {
    // 1. Mandatory Care Notes Check
    if (notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Care notes are mandatory to complete the session.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Payment confirmation check
    if (!_paymentReceived) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please confirm that payment has been received before completing the session.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_bookingId == null) return;

    setState(() => _isSubmitting = true);

    try {
      // 3. Update booking: status to Completed, payment_status to Paid
      await supabase.from('bookings').update({
        'status': 'Completed',
        'care_notes': notesController.text.trim(),
        'payment_status': 'Paid',
      }).eq('id', _bookingId!);

      // 4. Send notification to patient
      final patientAuthId = _patient?['auth_id'];
      if (patientAuthId != null) {
        final now = DateTime.now();
        await supabase.from('notifications').insert({
          'user_auth_id': patientAuthId,
          'title': 'Session Completed',
          'description':
              'Your care session has been completed. Payment of LKR ${_paymentAmount.toInt()} received.',
          'type': 'booking',
          'related_booking': _bookingId,
          'date':
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
          'time':
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00',
          'is_read': false,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session completed & payment confirmed!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  // ====================================================

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

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final patientName = _patient?['name'] ?? 'Patient';
    final date = _booking?['date'] ?? '';
    final timeSlot = _booking?['time_slot'] ?? '';
    final startTime = _booking?['start_time'] ?? '';
    final endTime = _booking?['end_time'] ?? '';
    final displayTime = timeSlot.isNotEmpty
        ? timeSlot
        : (startTime.isNotEmpty
            ? '${_formatTime(startTime)} - ${_formatTime(endTime)}'
            : '');
    final payment = _paymentAmount;
    final hours = _sessionHours;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Complete Session',
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
            // Patient info header
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
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        patientName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patientName,
                              style: AppTheme.headingLarge
                                  .copyWith(color: Colors.white)),
                          const SizedBox(height: 4),
                          if (date.isNotEmpty)
                            Text(
                              '$date ${displayTime.isNotEmpty ? "| $displayTime" : ""}',
                              style: AppTheme.bodyText
                                  .copyWith(color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Payment Card ──
            Container(
              width: double.infinity,
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
                      Icon(Icons.payments, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'PAYMENT TO COLLECT',
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

                  _paymentRow(
                      'Hourly Rate', 'LKR ${_hourlyRate.toInt()}'),
                  const SizedBox(height: 8),
                  _paymentRow(
                      'Duration', '${hours.toStringAsFixed(1)} hours'),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'LKR ${payment.toInt()}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0EA5A0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Payment Confirmation Checkbox ──
            Container(
              decoration: BoxDecoration(
                color: _paymentReceived
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _paymentReceived
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                ),
              ),
              child: CheckboxListTile(
                value: _paymentReceived,
                onChanged: (val) {
                  setState(() => _paymentReceived = val ?? false);
                },
                activeColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text(
                  'I confirm that payment of LKR ${payment.toInt()} has been received from the patient',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _paymentReceived
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
                subtitle: Text(
                  _paymentReceived
                      ? 'Payment confirmed'
                      : 'You must confirm payment before completing',
                  style: TextStyle(
                    fontSize: 12,
                    color: _paymentReceived
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),

            const SizedBox(height: 16),

            // Care Notes (Mandatory)
            buildCard(
              icon: Icons.note_alt,
              title: 'Care Notes (Required)',
              child: TextFormField(
                controller: notesController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText:
                      'Please detail the care provided during this session...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Submit button
            SizedBox(
              width: double.infinity,
              
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _paymentReceived
                      ? AppTheme.primary
                      : Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed:
                    _isSubmitting ? null : completeSession,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Icon(Icons.check_circle,
                        color: Colors.white),
                label: Text(
                  _isSubmitting
                      ? 'Completing...'
                      : 'Complete Session (LKR ${payment.toInt()})',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar:
          const CaregiverNavigationBarMobile(currentIndex: 0),
    );
  }

  Widget _paymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 14, color: Colors.white54)),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ],
    );
  }
}
