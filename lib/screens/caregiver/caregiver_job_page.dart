import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/caregiver_navigationbar_mobile.dart';

class CaregiverJobRequestsPage extends StatefulWidget {
  const CaregiverJobRequestsPage({super.key});

  @override
  State<CaregiverJobRequestsPage> createState() =>
      _CaregiverJobRequestsPageState();
}

class _CaregiverJobRequestsPageState extends State<CaregiverJobRequestsPage> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final uid = supabase.auth.currentUser!.id;

      // 1. Get the caregiver's profile ID
      final profile = await supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('auth_id', uid)
          .single();

      final caregiverId = profile['id'];

      // 2. Fetch pending bookings and join with patient_profiles
      final data = await supabase
          .from('bookings')
          .select('*, patient_profiles(name, age, address)')
          .eq('caregiver_id', caregiverId)
          .eq('status', 'Pending')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          requests = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendNotificationToPatient(
      Map<String, dynamic> booking, String title, String description) async {
    try {
      final patientId = booking['patient_id'];
      final patient = await supabase
          .from('patient_profiles')
          .select('auth_id')
          .eq('id', patientId)
          .single();

      final now = DateTime.now();
      await supabase.from('notifications').insert({
        'user_auth_id': patient['auth_id'],
        'title': title,
        'description': description,
        'type': 'booking',
        'related_booking': booking['id'],
        'date':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00',
      });
    } catch (_) {}
  }

  Future<void> acceptRequest(int index, String name) async {
    final booking = requests[index];
    final bookingId = booking['id'];

    try {
      await supabase
          .from('bookings')
          .update({'status': 'Accepted'})
          .eq('id', bookingId);

      // Notify the patient
      await _sendNotificationToPatient(
        booking,
        'Booking Accepted',
        'Your care request for ${booking['date']} has been accepted.',
      );

      setState(() {
        requests.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Successfully accepted request from $name",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to accept: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> confirmDecline(int index, String name) async {
    final bool? shouldDecline = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Decline Request"),
          content: Text("Are you sure you want to decline the care request from $name?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("No", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Yes, Decline", style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (shouldDecline == true) {
      cancelRequest(index);
    }
  }

  Future<void> cancelRequest(int index) async {
    final booking = requests[index];
    final bookingId = booking['id'];

    try {
      await supabase
          .from('bookings')
          .update({'status': 'Cancelled'})
          .eq('id', bookingId);

      // Notify the patient
      await _sendNotificationToPatient(
        booking,
        'Booking Declined',
        'Your care request for ${booking['date']} has been declined. Please try another caregiver.',
      );

      setState(() {
        requests.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request declined"), backgroundColor: Colors.grey),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to decline: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget buildRequestCard(Map<String, dynamic> request, int index) {
    final patientData = request['patient_profiles'] ?? {};
    final patientName = patientData['name'] ?? 'Unknown Patient';
    final age = patientData['age']?.toString() ?? 'N/A';
    final location = request['location'] ?? patientData['address'] ?? 'Location not provided';
    final serviceType = request['service_type'] ?? 'Visit';
    final date = request['date'] ?? '';
    final timeSlot = request['time_slot'] ?? '${request['start_time']} - ${request['end_time']}';

    final patientId = request['patient_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              // ================= THE FIX IS HERE =================
              Navigator.pushNamed(
                context,
                '/patient_details',
                arguments: patientId,
              ).then((_) {
                // This triggers the moment the Caregiver returns from the Patient Details screen
                // We show a quick loading state and fetch fresh data from Supabase!
                setState(() => _isLoading = true);
                _fetchRequests();
              });
              // ===================================================
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_circle, size: 18, color: AppTheme.primary),
                SizedBox(width: 6),
                Text(
                  "View Profile",
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Text(
            patientName,
            style: AppTheme.headingMedium,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  serviceType,
                  style: AppTheme.bodyText.copyWith(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.access_time, size: 16, color: AppTheme.textGrey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "$date | $timeSlot",
                  style: AppTheme.bodyText.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                "Age: $age",
                style: AppTheme.bodyText,
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location,
                  style: AppTheme.bodyText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => confirmDecline(index, patientName),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error, width: 1.5),
                  ),
                  child: const Text("Decline"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => acceptRequest(index, patientName),
                  child: const Text("Accept"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          "Job Requests",
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : requests.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No pending requests right now.",
              style: AppTheme.bodyText.copyWith(fontSize: 16),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return buildRequestCard(requests[index], index);
          },
        ),
      ),
      bottomNavigationBar: const CaregiverNavigationBarMobile(currentIndex: 1),
    );
  }
}