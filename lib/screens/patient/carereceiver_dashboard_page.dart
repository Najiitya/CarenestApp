import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/carereceiver_navigationbar_mobile.dart';

class CareReceiverDashboardPage extends StatefulWidget {
  const CareReceiverDashboardPage({super.key});

  @override
  State<CareReceiverDashboardPage> createState() => _CareReceiverDashboardPageState();
}

class _CareReceiverDashboardPageState extends State<CareReceiverDashboardPage> {
  static const _bg = Color(0xFFF7FAFA);
  static const _primary = Color(0xFF0EA5A0);
  static const _textDark = Color(0xFF0F172A);
  static const _textSoft = Color(0xFF7A8A96);

  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  String _patientName = 'User';
  List<Map<String, dynamic>> _todayBookings = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final uid = supabase.auth.currentUser!.id;

      // Get patient profile
      final profile = await supabase
          .from('patient_profiles')
          .select('id, name')
          .eq('auth_id', uid)
          .single();

      final patientId = profile['id'] as int;
      _patientName = profile['name'] ?? 'User';

      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Get today's bookings with caregiver info
      final bookings = await supabase
          .from('bookings')
          .select('id, date, time_slot, start_time, end_time, service_type, status, location, caregiver_id, caregiver_profiles!caregiver_id(name, service_area)')
          .eq('patient_id', patientId)
          .eq('date', todayStr)
          .inFilter('status', ['Accepted', 'In Progress', 'Completed'])
          .order('start_time', ascending: true);

      _todayBookings = List<Map<String, dynamic>>.from(bookings);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  _ItemStatus _getSessionStatus(Map<String, dynamic> booking) {
    if (booking['status'] == 'Completed') return _ItemStatus.completed;
    if (booking['status'] == 'In Progress') return _ItemStatus.inProgress;
    return _ItemStatus.upcoming;
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : RefreshIndicator(
                color: _primary,
                onRefresh: _loadDashboardData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  children: [
                    const SizedBox(height: 2),

                    // Header
                    Text(
                      'Hi, $_patientName',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_todayBookings.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0B3B3A), Color(0xFF062F2E)],
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.white54, size: 40),
                            const SizedBox(height: 12),
                            const Text(
                              'No sessions scheduled for today',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/caregiver_search'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'Find a caregiver',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._todayBookings.map((booking) {
                        final caregiverData = booking['caregiver_profiles'];
                        final caregiverName = caregiverData is Map ? caregiverData['name'] ?? 'Caregiver' : 'Caregiver';
                        final serviceType = booking['service_type'] ?? 'Care Service';
                        final status = _getSessionStatus(booking);
                        final timeSlot = booking['time_slot'] ?? '${_formatTime(booking['start_time'])} - ${_formatTime(booking['end_time'])}';
                        final caregiverId = booking['caregiver_id'];

                        return Column(
                          children: [
                            _CurrentCaregiverCard(
                              caregiverName: caregiverName,
                              specialty: serviceType,
                              onContact: () {
                                if (caregiverId != null) {
                                  Navigator.pushNamed(
                                    context,
                                    '/caregiver_details',
                                    arguments: caregiverId,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            _SessionStatusTile(
                              timeText: timeSlot,
                              title: serviceType,
                              status: status,
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const CareReceiverNavigationBarMobile(currentIndex: 0),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           CAREGIVER CARD                                   */
/* -------------------------------------------------------------------------- */

class _CurrentCaregiverCard extends StatelessWidget {
  final String caregiverName;
  final String specialty;
  final VoidCallback? onContact;

  const _CurrentCaregiverCard({
    required this.caregiverName,
    required this.specialty,
    this.onContact,
  });

  static const _radius = 18.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B3B3A), Color(0xFF062F2E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Caregiver',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: Color(0xFF6B7280),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caregiverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialty,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: onContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5A0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              SESSION TILE                                  */
/* -------------------------------------------------------------------------- */

class _SessionStatusTile extends StatelessWidget {
  final String timeText;
  final String title;
  final _ItemStatus status;

  const _SessionStatusTile({
    required this.timeText,
    required this.title,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == _ItemStatus.completed;
    final isInProgress = status == _ItemStatus.inProgress;

    final IconData icon;
    final Color iconColor;
    final Color bgColor;
    final String statusText;

    if (isCompleted) {
      icon = Icons.check;
      iconColor = const Color(0xFF0EA5A0);
      bgColor = const Color(0xFF0EA5A0).withOpacity(0.12);
      statusText = 'Completed';
    } else if (isInProgress) {
      icon = Icons.play_arrow;
      iconColor = Colors.orange;
      bgColor = Colors.orange.withOpacity(0.12);
      statusText = 'In Progress';
    } else {
      icon = Icons.access_time;
      iconColor = const Color(0xFF64748B);
      bgColor = const Color(0xFFCBD5E1).withOpacity(0.20);
      statusText = 'Upcoming';
    }

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7EEF0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              '$timeText: $title – $statusText',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _ItemStatus { completed, upcoming, inProgress }
