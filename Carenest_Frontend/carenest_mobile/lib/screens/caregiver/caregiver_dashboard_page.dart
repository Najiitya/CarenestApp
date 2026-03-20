import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/caregiver_navigationbar_mobile.dart';

class CaregiverDashboardPage extends StatefulWidget {
  const CaregiverDashboardPage({super.key});

  @override
  State<CaregiverDashboardPage> createState() => _CaregiverDashboardPageState();
}

class _CaregiverDashboardPageState extends State<CaregiverDashboardPage> {
  static const _bg = Color(0xFFF7FAFA);
  static const _cardBorder = Color(0xFFE7EEF0);
  static const _textDark = Color(0xFF0F172A);
  static const _textSoft = Color(0xFF7A8A96);
  static const _primary = Color(0xFF16A394);

  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  Map<String, dynamic>? _profile;
  int _upcomingVisitCount = 0;
  double _monthEarnings = 0;
  int _pendingCount = 0;

  List<Map<String, dynamic>> _upcomingVisits = [];
  List<Map<String, dynamic>> _history = [];

  late final RealtimeChannel _bookingsChannel;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Real-time listener: auto-reload when any booking changes
    _bookingsChannel = supabase.channel('caregiver_bookings').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'bookings',
      callback: (payload) {
        _loadData();
      },
    ).subscribe();
  }

  @override
  void dispose() {
    supabase.removeChannel(_bookingsChannel);
    super.dispose();
  }

  /// Calculate hours between two TIME strings like "08:00:00" and "12:00:00"
  double _calculateHours(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return 1; // default 1 hour
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes =
          int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final diff = (endMinutes - startMinutes) / 60.0;
      return diff > 0 ? diff : 1; // at least 1 hour
    } catch (_) {
      return 1;
    }
  }

  Future<void> _loadData() async {
    try {
      final uid = supabase.auth.currentUser!.id;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final monthStart =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-01';

      // Get caregiver profile
      final profile = await supabase
          .from('caregiver_profiles')
          .select()
          .eq('auth_id', uid)
          .single();

      final caregiverId = profile['id'];
      final hourlyRate =
          double.tryParse(profile['hourly_rate']?.toString() ?? '0') ?? 0;

      // Get total count of upcoming accepted/confirmed visits
      final upcomingBookingsCount = await supabase
          .from('bookings')
          .select('id')
          .eq('caregiver_id', caregiverId)
          .inFilter('status', [
        'Accepted',
        'Confirmed',
        'Ongoing',
        'In Progress',
      ]).gte('date', today);

      // Get this month's completed bookings for earnings (with times)
      final monthBookings = await supabase
          .from('bookings')
          .select('id, start_time, end_time')
          .eq('caregiver_id', caregiverId)
          .eq('status', 'Completed')
          .gte('date', monthStart)
          .lte('date', today);

      // Calculate earnings from actual hours worked
      double totalEarnings = 0;
      if (monthBookings != null) {
        for (var b in monthBookings) {
          final hours = _calculateHours(
            b['start_time']?.toString(),
            b['end_time']?.toString(),
          );
          totalEarnings += hours * hourlyRate;
        }
      }

      // Count pending requests
      final pendingReqs = await supabase
          .from('bookings')
          .select('id')
          .eq('caregiver_id', caregiverId)
          .eq('status', 'Pending');

      final upcomingData = await supabase
          .from('bookings')
          .select('*, patient_profiles(name, location, auth_id)')
          .eq('caregiver_id', caregiverId)
          .inFilter('status', [
        'Accepted',
        'Confirmed',
        'Ongoing',
        'In Progress',
      ])
          .gte('date', today)
          .order('date', ascending: true)
          .order('start_time', ascending: true)
          .limit(5);

      // Get recent completed bookings (history) with times for payment display
      final historyData = await supabase
          .from('bookings')
          .select('*, patient_profiles(name)')
          .eq('caregiver_id', caregiverId)
          .eq('status', 'Completed')
          .order('date', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _profile = profile;

          _upcomingVisitCount = upcomingBookingsCount != null
              ? (upcomingBookingsCount as List).length
              : 0;

          _monthEarnings = totalEarnings;

          _pendingCount =
              pendingReqs != null ? (pendingReqs as List).length : 0;

          _upcomingVisits = upcomingData != null
              ? List<Map<String, dynamic>>.from(upcomingData)
              : [];
          _history = historyData != null
              ? List<Map<String, dynamic>>.from(historyData)
              : [];

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ================= START VISIT LOGIC =================
  Future<void> _startVisit(Map<String, dynamic> visit) async {
    final bookingId = visit['id'];
    final patientAuthId = visit['patient_profiles']?['auth_id'];
    final caregiverName = _profile?['name'] ?? 'Your caregiver';

    if (patientAuthId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Cannot find patient authentication ID"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await supabase
          .from('bookings')
          .update({'status': 'Ongoing'})
          .eq('id', bookingId);

      final String formalMessage =
          'Your caregiver, $caregiverName, has officially commenced the scheduled care session.';

      await supabase.from('notifications').insert({
        'user_auth_id': patientAuthId,
        'title': 'Session Commenced',
        'message': formalMessage,
        'description': formalMessage,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Visit started! The patient has been notified."),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isLoading = true);
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error starting visit: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ================= CANCEL VISIT CONFIRMATION =================
  Future<void> _cancelVisitConfirmation(String bookingId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cancel Visit"),
        content: const Text(
          "Are you sure you want to cancel this scheduled visit? The patient will be notified automatically.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep Visit",
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Cancel",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase
            .from('bookings')
            .update({'status': 'Cancelled'})
            .eq('id', bookingId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Visit cancelled successfully"),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = true);
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Error cancelling visit: $e"),
                backgroundColor: Colors.red),
          );
        }
      }
    }
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
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(
            child: CircularProgressIndicator(color: _primary)),
        bottomNavigationBar:
            const CaregiverNavigationBarMobile(currentIndex: 0),
      );
    }

    final name = _profile?['name'] ?? 'Caregiver';
    final firstName = name.split(' ').first;
    final hourlyRate =
        double.tryParse(_profile?['hourly_rate']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Hi, $firstName',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/caregiver_profile'),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFE9F3F2),
                      child:
                          Icon(Icons.person, color: _textSoft, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: "Upcoming visits",
                      value: '$_upcomingVisitCount',
                      valueColor: _textDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      title: 'This month',
                      value: 'LKR ${_monthEarnings.toInt()}',
                      valueColor: _primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (_pendingCount > 0) ...[
                _buildPendingRequestsCard(),
                const SizedBox(height: 18),
              ],

              if (_upcomingVisits.isEmpty)
                _buildNoUpcomingCard()
              else ...[
                const Text(
                  'Upcoming Visits',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textDark),
                ),
                const SizedBox(height: 12),
                ..._upcomingVisits.map((visit) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildVisitCard(visit, hourlyRate),
                  );
                }),
              ],
              const SizedBox(height: 18),

              const Text(
                'History',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textDark),
              ),
              const SizedBox(height: 12),

              if (_history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _cardBorder),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text('No completed visits yet',
                        style: TextStyle(color: _textSoft, fontSize: 14)),
                  ),
                ),

              ..._history.map((booking) {
                final patientName =
                    booking['patient_profiles']?['name'] ?? 'Patient';
                final serviceType = booking['service_type'] ?? 'Visit';
                final date = booking['date'] ?? '';
                final hours = _calculateHours(
                  booking['start_time']?.toString(),
                  booking['end_time']?.toString(),
                );
                final payment = hours * hourlyRate;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(
                    tag:
                        '${serviceType.toString().toUpperCase()} - COMPLETED',
                    patientName: patientName,
                    date: date,
                    payment: 'LKR ${payment.toInt()}',
                    hours: '${hours.toStringAsFixed(1)} hrs',
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          const CaregiverNavigationBarMobile(currentIndex: 0),
    );
  }

  Widget _buildPendingRequestsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
                color: Color(0xFFFFEDD5), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_active,
                color: Color(0xFFEA580C)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_pendingCount New ${_pendingCount == 1 ? "Request" : "Requests"}!',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9A3412)),
                ),
                const SizedBox(height: 4),
                const Text('Tap to view and accept.',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFFC2410C))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/caregiver_job'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(
      Map<String, dynamic> visit, double hourlyRate) {
    final patientName = visit['patient_profiles']?['name'] ?? 'Patient';
    final location =
        visit['patient_profiles']?['location'] ?? visit['location'] ?? '';
    final date = visit['date'] ?? '';
    final startTime = visit['start_time'] ?? '';
    final endTime = visit['end_time'] ?? '';
    final status = visit['status'] ?? '';
    final bookingId = visit['id']?.toString() ?? '';

    final hours = _calculateHours(startTime, endTime);
    final payment = hours * hourlyRate;

    final initials = patientName.length >= 2
        ? patientName.substring(0, 2).toUpperCase()
        : patientName.toUpperCase();

    final isToday =
        date == DateTime.now().toIso8601String().split('T')[0];
    final timeDisplay = isToday
        ? 'Today, ${_formatTime(startTime)}'
        : '$date, ${_formatTime(startTime)}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E3C3A), Color(0xFF062C2B)],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 26,
              offset: const Offset(0, 14)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                status == 'Ongoing' ? 'ONGOING VISIT' : 'SCHEDULED VISIT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: status == 'Ongoing'
                      ? Colors.greenAccent
                      : _primary.withOpacity(0.85),
                ),
              ),
              if (isToday)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('TODAY',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                alignment: Alignment.center,
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(timeDisplay,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA9C2BE))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 18, color: Color(0xFFA9C2BE)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(location,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFA9C2BE))),
              ),
              // Payment estimate
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LKR ${payment.toInt()} (${hours.toStringAsFixed(1)}h)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (status == 'Ongoing')
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/caregiver_update-status',
                    arguments: bookingId,
                  ).then((value) {
                    if (value == true) {
                      setState(() => _isLoading = true);
                      _loadData();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Complete Session',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        if (bookingId.isNotEmpty) {
                          _cancelVisitConfirmation(bookingId);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _startVisit(visit),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Start visit',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNoUpcomingCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E3C3A), Color(0xFF062C2B)],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('NO UPCOMING VISITS',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: _primary.withOpacity(0.85))),
          const SizedBox(height: 8),
          const Text('You have no scheduled visits at the moment.',
              style: TextStyle(fontSize: 14, color: Color(0xFFA9C2BE))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  static const _cardBorder = Color(0xFFE7EEF0);
  static const _textSoft = Color(0xFF7A8A96);

  const _StatCard({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _cardBorder),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textSoft)),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: valueColor,
                    letterSpacing: -0.3)),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String tag;
  final String patientName;
  final String date;
  final String payment;
  final String hours;
  static const _cardBorder = Color(0xFFE7EEF0);
  static const _textDark = Color(0xFF0F172A);
  static const _textSoft = Color(0xFF7A8A96);
  static const _primary = Color(0xFF16A394);

  const _HistoryCard({
    required this.tag,
    required this.patientName,
    required this.date,
    required this.payment,
    required this.hours,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _cardBorder),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFD5E6FF)),
            ),
            child: Text(tag,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2A6BCB),
                    letterSpacing: 0.4)),
          ),
          const SizedBox(height: 10),
          Text(patientName,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _textDark)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: _textSoft),
              const SizedBox(width: 6),
              Text(date,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textSoft)),
              const SizedBox(width: 6),
              Text('• $hours',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textSoft)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(payment,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
