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
  static const _textDark = Color(0xFF0F172A);
  static const _textSoft = Color(0xFF7A8A96);
  static const _primary = Color(0xFF16A394);

  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  String _caregiverName = 'Caregiver';
  int _todayVisits = 0;
  String _monthlyEarnings = 'LKR 0';
  Map<String, dynamic>? _nextVisit;
  List<Map<String, dynamic>> _history = [];
  int? _caregiverId;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final uid = supabase.auth.currentUser!.id;

      // Get caregiver profile
      final profile = await supabase
          .from('caregiver_profiles')
          .select('id, name, hourly_rate')
          .eq('auth_id', uid)
          .single();

      _caregiverId = profile['id'] as int;
      _caregiverName = profile['name'] ?? 'Caregiver';
      final hourlyRate = (profile['hourly_rate'] ?? 0).toDouble();

      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final monthStr = '${today.year}-${today.month.toString().padLeft(2, '0')}';

      // Today's visits count
      final todayBookings = await supabase
          .from('bookings')
          .select('id')
          .eq('caregiver_id', _caregiverId!)
          .eq('date', todayStr)
          .inFilter('status', ['Accepted', 'In Progress', 'Completed']);

      _todayVisits = (todayBookings as List).length;

      // Monthly earnings (completed bookings * hourly rate)
      final monthBookings = await supabase
          .from('bookings')
          .select('id')
          .eq('caregiver_id', _caregiverId!)
          .gte('date', '$monthStr-01')
          .eq('status', 'Completed');

      final completedCount = (monthBookings as List).length;
      final earnings = (completedCount * hourlyRate).toInt();
      _monthlyEarnings = 'LKR $earnings';

      // Next upcoming visit
      final nextVisitResult = await supabase
          .from('bookings')
          .select('id, date, time_slot, location, service_type, patient_id, patient_profiles!patient_id(name)')
          .eq('caregiver_id', _caregiverId!)
          .gte('date', todayStr)
          .inFilter('status', ['Accepted', 'In Progress'])
          .order('date', ascending: true)
          .order('start_time', ascending: true)
          .limit(1);

      if ((nextVisitResult as List).isNotEmpty) {
        _nextVisit = nextVisitResult[0];
      }

      // Recent completed history
      final historyResult = await supabase
          .from('bookings')
          .select('id, date, service_type, patient_id, patient_profiles!patient_id(name)')
          .eq('caregiver_id', _caregiverId!)
          .eq('status', 'Completed')
          .order('date', ascending: false)
          .limit(5);

      _history = List<Map<String, dynamic>>.from(historyResult);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
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
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Hi, $_caregiverName',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFE9F3F2),
                          child: Icon(Icons.person, color: _textSoft, size: 20),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: "Today's visits",
                            value: '$_todayVisits',
                            valueColor: _textDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _StatCard(
                            title: 'This month',
                            value: _monthlyEarnings,
                            valueColor: _primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Next Visit
                    if (_nextVisit != null)
                      _buildNextVisitCard()
                    else
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0E3C3A), Color(0xFF062C2B)],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'No upcoming visits',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                    const SizedBox(height: 18),

                    // History
                    const Text(
                      'History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_history.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No completed visits yet',
                            style: TextStyle(color: _textSoft, fontSize: 15),
                          ),
                        ),
                      )
                    else
                      ..._history.map((booking) {
                        final patientData = booking['patient_profiles'];
                        final patientName = patientData is Map ? patientData['name'] ?? 'Patient' : 'Patient';
                        final serviceType = (booking['service_type'] ?? 'Visit').toString().toUpperCase();
                        final date = booking['date'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _JobCard(
                            tag: '$serviceType - COMPLETED',
                            name: patientName,
                            date: date,
                            onViewDetails: () {
                              Navigator.pushNamed(
                                context,
                                '/patient_details',
                                arguments: booking['patient_id'],
                              );
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const CaregiverNavigationBarMobile(currentIndex: 0),
    );
  }

  Widget _buildNextVisitCard() {
    final patientData = _nextVisit!['patient_profiles'];
    final patientName = patientData is Map ? patientData['name'] ?? 'Patient' : 'Patient';
    final timeSlot = _nextVisit!['time_slot'] ?? '';
    final location = _nextVisit!['location'] ?? '';
    final initials = _getInitials(patientName);
    const _textSoftOnDark = Color(0xFFA9C2BE);

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
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT VISIT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: _primary.withOpacity(0.85),
            ),
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
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeSlot,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textSoftOnDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: _textSoftOnDark),
                const SizedBox(width: 6),
                Text(
                  location,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textSoftOnDark),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/caregiver_update-status',
                  arguments: {
                    'visitId': _nextVisit!['id'],
                    'patientName': patientName,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Start visit',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ),
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
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textSoft),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String tag;
  final String name;
  final String date;
  final VoidCallback? onViewDetails;

  static const _cardBorder = Color(0xFFE7EEF0);
  static const _textDark = Color(0xFF0F172A);
  static const _textSoft = Color(0xFF7A8A96);

  const _JobCard({
    required this.tag,
    required this.name,
    required this.date,
    this.onViewDetails,
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
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFD5E6FF)),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2A6BCB),
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _textDark),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: _textSoft),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textSoft),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: onViewDetails,
              style: OutlinedButton.styleFrom(
                foregroundColor: _textSoft,
                side: const BorderSide(color: _cardBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View details', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
