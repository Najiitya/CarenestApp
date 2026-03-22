import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/carereceiver_navigationbar_mobile.dart';

class CareReceiverDashboardPage extends StatefulWidget {
  const CareReceiverDashboardPage({super.key});

  @override
  State<CareReceiverDashboardPage> createState() =>
      _CareReceiverDashboardPageState();
}

class _CareReceiverDashboardPageState extends State<CareReceiverDashboardPage> {
  static const _bg = Color(0xFFF7FAFA);
  static const _primary = Color(0xFF16A394);

  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _dashboardBookings = [];

  late final RealtimeChannel _bookingsChannel;

  @override
  void initState() {
    super.initState();
    _loadData();

    _bookingsChannel = supabase.channel('public:bookings').onPostgresChanges(
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

  Future<void> _loadData() async {
    try {
      final uid = supabase.auth.currentUser!.id;

      final profile = await supabase
          .from('patient_profiles')
          .select()
          .eq('auth_id', uid)
          .single();

      final patientId = profile['id'];

      // 1. Fetch all relevant bookings
      final bookings = await supabase
          .from('bookings')
          .select('*, caregiver_profiles(name, service_area, hourly_rate)')
          .eq('patient_id', patientId)
          .inFilter('status', [
        'Pending',
        'Accepted',
        'Confirmed',
        'Ongoing',
        'Cancelled',
        'Rejected',
        'Completed'
      ])
          .order('created_at', ascending: false);

      // 2. NEW: Fetch all reviews this patient has already submitted
      final reviews = await supabase
          .from('reviews')
          .select('booking_id')
          .eq('patient_id', patientId);

      // Create a list of booking IDs that are already reviewed
      final reviewedBookingIds = reviews.map((r) => r['booking_id'].toString()).toList();

      if (mounted) {
        setState(() {
          _profile = profile;

          // 3. NEW: Filter out Completed bookings if their ID is in the reviewed list!
          _dashboardBookings = List<Map<String, dynamic>>.from(bookings).where((b) {
            if (b['status'] == 'Completed') {
              return !reviewedBookingIds.contains(b['id'].toString());
            }
            return true; // Keep everything else
          }).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _dismissAndFindAnother(String bookingId) async {
    try {
      await supabase.from('bookings').delete().eq('id', bookingId);
      setState(() {
        _dashboardBookings.removeWhere((b) => b['id'].toString() == bookingId);
      });
      if (mounted) {
        Navigator.pushNamed(context, '/caregiver_search');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Instantly hides the card right after the review is submitted
  void _hideReviewedBooking(String bookingId) {
    setState(() {
      _dashboardBookings.removeWhere((b) => b['id'].toString() == bookingId);
    });
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
      var adjustedEnd = endMinutes;
      if (adjustedEnd <= startMinutes) adjustedEnd += 1440; // overnight
      final diff = (adjustedEnd - startMinutes) / 60.0;
      return diff > 0 ? diff : 1;
    } catch (_) {
      return 1;
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

  List<Widget> _buildActiveCaregiverGroups() {
    final activeBookings = _dashboardBookings.where((b) =>
        ['Accepted', 'Confirmed', 'Ongoing', 'In Progress'].contains(b['status'])
    ).toList();

    if (activeBookings.isEmpty) return [];

    Map<String, List<Map<String, dynamic>>> groupedBookings = {};
    for (var booking in activeBookings) {
      final caregiverId = booking['caregiver_id'].toString();
      groupedBookings.putIfAbsent(caregiverId, () => []).add(booking);
    }

    return groupedBookings.values.map((group) {
      final firstBooking = group.first;
      final caregiverName = firstBooking['caregiver_profiles']?['name'] ?? 'Caregiver';
      final specialty = firstBooking['service_type'] ?? 'Care Service';

      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Column(
          children: [
            _CurrentCaregiverCard(
              caregiverName: caregiverName,
              specialty: specialty,
            ),
            const SizedBox(height: 14),

            ...group.map((booking) {
              final status = booking['status'] ?? 'Pending';
              final date = booking['date'] ?? '';
              final startTime = booking['start_time'] ?? '';
              final endTime = booking['end_time'] ?? '';

              final hourlyRate = double.tryParse(
                      booking['caregiver_profiles']?['hourly_rate']
                              ?.toString() ??
                          '0') ??
                  0;
              final hours = _calculateHours(startTime, endTime);
              final payment = hours * hourlyRate;

              final isToday = date == DateTime.now().toIso8601String().split('T')[0];
              final dateDisplay = isToday ? 'Today' : date;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _SessionStatusTile(
                  timeText: '$dateDisplay, ${_formatTime(startTime)}',
                  title: booking['service_type'] ?? 'Service',
                  caregiverName: caregiverName,
                  status: status == 'Completed' ? _ItemStatus.completed : _ItemStatus.upcoming,
                  statusLabel: status,
                  payment: payment > 0 ? 'LKR ${payment.toInt()}' : null,
                ),
              );
            }),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator(color: _primary)),
        bottomNavigationBar: const CareReceiverNavigationBarMobile(currentIndex: 0),
      );
    }

    final name = _profile?['name'] ?? 'Patient';
    final firstName = name.split(' ').first;

    final pendingBookings = _dashboardBookings.where((b) => b['status'] == 'Pending').toList();
    final cancelledBookings = _dashboardBookings.where((b) => b['status'] == 'Cancelled' || b['status'] == 'Rejected').toList();

    final completedBookings = _dashboardBookings.where((b) => b['status'] == 'Completed').toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            children: [
              const SizedBox(height: 2),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Hi, $firstName',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/patient_profile'),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFE9F3F2),
                      child: Icon(Icons.person, color: Color(0xFF7A8A96), size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_dashboardBookings.isEmpty)
                _buildEmptyState()
              else ...[
                ...pendingBookings.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildPendingCard(
                    b['caregiver_profiles']?['name'] ?? 'Caregiver',
                    b['service_type'] ?? 'Service',
                    b['date'] ?? '',
                    b['start_time'] ?? '',
                  ),
                )),

                ...cancelledBookings.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildCancelledCard(
                    b['caregiver_profiles']?['name'] ?? 'Caregiver',
                    b['service_type'] ?? 'Service',
                    b['id'].toString(),
                  ),
                )),

                ..._buildActiveCaregiverGroups(),

                if (completedBookings.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Past Sessions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  ...completedBookings.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _CompletedSessionCard(
                      caregiverName: b['caregiver_profiles']?['name'] ?? 'Caregiver',
                      specialty: b['service_type'] ?? 'Service',
                      date: b['date'] ?? '',
                      bookingId: b['id'].toString(),
                      onReviewCompleted: () => _hideReviewedBooking(b['id'].toString()),
                    ),
                  )),
                ]
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CareReceiverNavigationBarMobile(currentIndex: 0),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EEF0)),
      ),
      child: Column(
        children: [
          Icon(Icons.search, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No active bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF7A8A96))),
          const SizedBox(height: 8),
          const Text('Search for a caregiver to get started', style: TextStyle(fontSize: 14, color: Color(0xFF7A8A96))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/caregiver_search'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Find Caregiver'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(String name, String type, String date, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.orange.shade200)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
            child: Icon(Icons.hourglass_empty, color: Colors.orange.shade800),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Waiting for $name...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                const SizedBox(height: 4),
                Text("Requested $type on $date", style: TextStyle(fontSize: 13, color: Colors.orange.shade800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledCard(String name, String type, String bookingId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.red.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                child: Icon(Icons.cancel_outlined, color: Colors.red.shade800),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text("Caregiver Unavailable", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900))),
            ],
          ),
          const SizedBox(height: 12),
          Text("$name was unable to accept your $type request. Please find another caregiver.", style: TextStyle(fontSize: 13, color: Colors.red.shade800)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _dismissAndFindAnother(bookingId),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Find another caregiver"),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentCaregiverCard extends StatelessWidget {
  final String caregiverName;
  final String specialty;

  const _CurrentCaregiverCard({
    required this.caregiverName,
    required this.specialty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0B3B3A), Color(0xFF062F2E)]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Caregiver', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), shape: BoxShape.circle),
                    child: const Icon(Icons.medical_services_outlined, color: Color(0xFF6B7280), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(caregiverName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(specialty, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5A0), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Contact now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedSessionCard extends StatelessWidget {
  final String caregiverName;
  final String specialty;
  final String date;
  final String bookingId;
  final VoidCallback onReviewCompleted;

  const _CompletedSessionCard({
    required this.caregiverName,
    required this.specialty,
    required this.date,
    required this.bookingId,
    required this.onReviewCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2E4053), Color(0xFF1B2631)]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Completed Session • $date', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(caregiverName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(specialty, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/review_page',
                      arguments: bookingId,
                    ).then((value) {
                      if (value == true) {
                        onReviewCompleted();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5A0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text('Rate this caregiver', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionStatusTile extends StatelessWidget {
  final String timeText;
  final String title;
  final String caregiverName;
  final _ItemStatus status;
  final String statusLabel;
  final String? payment;

  const _SessionStatusTile({
    required this.timeText,
    required this.title,
    required this.caregiverName,
    required this.status,
    required this.statusLabel,
    this.payment,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == _ItemStatus.completed;
    final isOngoing = statusLabel == 'Ongoing';

    Color iconBgColor = isOngoing
        ? Colors.green.withOpacity(0.15)
        : isCompleted
        ? const Color(0xFF0EA5A0).withOpacity(0.12)
        : const Color(0xFFCBD5E1).withOpacity(0.20);

    Color iconColor = isOngoing
        ? Colors.green
        : isCompleted
        ? const Color(0xFF0EA5A0)
        : const Color(0xFF64748B);

    IconData iconData = isOngoing
        ? Icons.play_arrow_rounded
        : isCompleted
        ? Icons.check
        : Icons.access_time;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(iconData, size: 22, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isOngoing ? Colors.green.shade200 : const Color(0xFFE7EEF0),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$timeText: $title with $caregiverName - $statusLabel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isOngoing ? Colors.green.shade800 : const Color(0xFF334155),
                  ),
                ),
                if (payment != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5A0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      payment!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0EA5A0),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _ItemStatus { completed, upcoming }