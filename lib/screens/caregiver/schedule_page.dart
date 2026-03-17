import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  int? _caregiverId;
  List<Map<String, dynamic>> _dayBookings = [];
  Map<String, List<Map<String, dynamic>>> _weekBookings = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final uid = supabase.auth.currentUser!.id;

      final profile = await supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('auth_id', uid)
          .single();

      _caregiverId = profile['id'];

      await _loadDayBookings();
      await _loadWeekBookings();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDayBookings() async {
    if (_caregiverId == null) return;
    final dateStr = selectedDate.toIso8601String().split('T')[0];

    final data = await supabase
        .from('bookings')
        .select('*, patient_profiles(name, location)')
        .eq('caregiver_id', _caregiverId!)
        .eq('date', dateStr)
        .order('start_time');

    if (mounted) {
      setState(() {
        _dayBookings = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> _loadWeekBookings() async {
    if (_caregiverId == null) return;

    // Get Monday of current week
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final data = await supabase
        .from('bookings')
        .select('id, date, status')
        .eq('caregiver_id', _caregiverId!)
        .gte('date', monday.toIso8601String().split('T')[0])
        .lte('date', sunday.toIso8601String().split('T')[0]);

    // Group by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final booking in data) {
      final date = booking['date'] as String;
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(booking);
    }

    if (mounted) {
      setState(() {
        _weekBookings = grouped;
      });
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

  String _getTimeOfDay(String? time) {
    if (time == null) return 'Morning';
    try {
      final hour = int.parse(time.split(':')[0]);
      if (hour < 12) return 'Morning';
      if (hour < 17) return 'Afternoon';
      return 'Evening';
    } catch (_) {
      return 'Morning';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schedule',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _selectDate(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              tabs: const [Tab(text: 'Daily'), Tab(text: 'Weekly')],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [_buildDailySchedule(), _buildWeeklySchedule()],
            ),
    );
  }

  Widget _buildDailySchedule() {
    // Group bookings by time of day
    final morning = _dayBookings
        .where((b) => _getTimeOfDay(b['start_time']) == 'Morning')
        .toList();
    final afternoon = _dayBookings
        .where((b) => _getTimeOfDay(b['start_time']) == 'Afternoon')
        .toList();
    final evening = _dayBookings
        .where((b) => _getTimeOfDay(b['start_time']) == 'Evening')
        .toList();

    final completed =
        _dayBookings.where((b) => b['status'] == 'Completed').length;
    final pending = _dayBookings.length - completed;

    return RefreshIndicator(
      onRefresh: _loadDayBookings,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Date selector strip
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final date =
                        DateTime.now().add(Duration(days: index - 3));
                    final isSelected =
                        date.day == selectedDate.day &&
                        date.month == selectedDate.month &&
                        date.year == selectedDate.year;
                    return _buildDateCard(date, isSelected);
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                            'Total Visits', '${_dayBookings.length}', Icons.event),
                        Container(
                            width: 1, height: 40, color: Colors.white38),
                        _buildSummaryItem(
                            'Completed', '$completed', Icons.check_circle),
                        Container(
                            width: 1, height: 40, color: Colors.white38),
                        _buildSummaryItem(
                            'Pending', '$pending', Icons.pending),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_dayBookings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.event_busy,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('No visits scheduled for this day',
                                style: AppTheme.bodyText),
                          ],
                        ),
                      ),
                    ),

                  // Morning
                  if (morning.isNotEmpty) ...[
                    _buildTimeSection('Morning', '8:00 AM - 12:00 PM'),
                    const SizedBox(height: 12),
                    ...morning.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildVisitCard(b),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Afternoon
                  if (afternoon.isNotEmpty) ...[
                    _buildTimeSection('Afternoon', '12:00 PM - 5:00 PM'),
                    const SizedBox(height: 12),
                    ...afternoon.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildVisitCard(b),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Evening
                  if (evening.isNotEmpty) ...[
                    _buildTimeSection('Evening', '5:00 PM - 8:00 PM'),
                    const SizedBox(height: 12),
                    ...evening.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildVisitCard(b),
                        )),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(7, (index) {
        final date = monday.add(Duration(days: index));
        final dateStr = date.toIso8601String().split('T')[0];
        final bookings = _weekBookings[dateStr] ?? [];
        final total = bookings.length;
        final completed =
            bookings.where((b) => b['status'] == 'Completed').length;
        final pending = total - completed;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildWeekDayCard(
            '${dayNames[index]}, ${date.month}/${date.day}',
            total,
            completed,
            pending,
          ),
        );
      }),
    );
  }

  // ── Helper Widgets ────────────────────────────────

  Widget _buildDateCard(DateTime date, bool isSelected) {
    final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][
        date.weekday - 1];

    return GestureDetector(
      onTap: () {
        setState(() => selectedDate = date);
        _loadDayBookings();
      },
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(dayName,
                style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${date.day}',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? Colors.white : AppTheme.textDark)),
            const SizedBox(height: 2),
            if (date.day == DateTime.now().day &&
                date.month == DateTime.now().month)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color:
                      isSelected ? Colors.white : AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildTimeSection(String title, String time) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppTheme.headingMedium),
        const SizedBox(width: 8),
        Text(time, style: AppTheme.bodyText),
      ],
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> booking) {
    final patientName =
        booking['patient_profiles']?['name'] ?? 'Patient';
    final location = booking['patient_profiles']?['location'] ??
        booking['location'] ??
        '';
    final startTime = _formatTime(booking['start_time']);
    final endTime = _formatTime(booking['end_time']);
    final status = booking['status'] ?? 'Pending';
    final description = booking['description'] ?? '';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'Completed':
        statusColor = Colors.green;
        statusText = 'Completed';
        statusIcon = Icons.check_circle;
        break;
      case 'In Progress':
        statusColor = Colors.blue;
        statusText = 'In Progress';
        statusIcon = Icons.play_circle;
        break;
      case 'Confirmed':
        statusColor = Colors.orange;
        statusText = 'Confirmed';
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person,
                    color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName,
                        style: AppTheme.bodyText.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark)),
                    if (location.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(location, style: AppTheme.bodyText),
                        ],
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusText,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time,
                    size: 16, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text('$startTime - $endTime',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800])),
              ],
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekDayCard(
      String day, int totalVisits, int completed, int pending) {
    final hasVisits = totalVisits > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasVisits ? AppTheme.primary : Colors.grey[200]!,
          width: hasVisits ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today,
                  color:
                      hasVisits ? AppTheme.primary : Colors.grey[400],
                  size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(day,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasVisits
                            ? AppTheme.textDark
                            : Colors.grey[600])),
              ),
              if (hasVisits)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$totalVisits visits',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          if (hasVisits) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildWeekStatChip('Completed', completed, Colors.green),
                const SizedBox(width: 8),
                _buildWeekStatChip('Pending', pending, Colors.orange),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text('No visits scheduled',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      _loadDayBookings();
    }
  }
}
