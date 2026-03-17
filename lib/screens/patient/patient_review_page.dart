import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../widgets/carereceiver_navigationbar_mobile.dart';

class PatientReviewPage extends StatefulWidget {
  const PatientReviewPage({super.key});

  @override
  State<PatientReviewPage> createState() => _PatientReviewPageState();
}

class _PatientReviewPageState extends State<PatientReviewPage> {
  final supabase = Supabase.instance.client;

  int rating = 0;
  int onTimeRating = 0;
  int responseRating = 0;
  final TextEditingController commentController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _bookingId;
  Map<String, dynamic>? _bookingData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && _bookingId == null) {
      _bookingId = args.toString();
      _fetchBookingDetails();
    } else if (args == null && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookingDetails() async {
    try {
      final data = await supabase
          .from('bookings')
          .select('*, caregiver_profiles(name), patient_profiles(name)')
          .eq('id', _bookingId!)
          .single();

      if (mounted) {
        setState(() {
          _bookingData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to load session details: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateCaregiverMetrics(int caregiverId) async {
    try {
      // Get all reviews for this caregiver (including new fields)
      final reviews = await supabase
          .from('reviews')
          .select('rating, on_time_rating, response_time_rating')
          .eq('caregiver_id', caregiverId);

      double avgRating = 0;
      double avgOnTime = 0;
      double avgResponse = 0;
      int onTimeCount = 0;
      int responseCount = 0;

      if (reviews.isNotEmpty) {
        double sumRating = 0;
        double sumOnTime = 0;
        double sumResponse = 0;

        for (var r in reviews) {
          sumRating += (r['rating'] as num).toDouble();

          if (r['on_time_rating'] != null) {
            sumOnTime += (r['on_time_rating'] as num).toDouble();
            onTimeCount++;
          }
          if (r['response_time_rating'] != null) {
            sumResponse += (r['response_time_rating'] as num).toDouble();
            responseCount++;
          }
        }

        avgRating =
            double.parse((sumRating / reviews.length).toStringAsFixed(1));

        if (onTimeCount > 0) {
          avgOnTime = sumOnTime / onTimeCount;
        }
        if (responseCount > 0) {
          avgResponse = sumResponse / responseCount;
        }
      }

      // Convert on-time rating (1-5) to percentage
      double onTimePercent = onTimeCount > 0 ? (avgOnTime / 5) * 100 : 0;

      // Convert response rating (1-5) to descriptive text
      String responseTimeText;
      if (responseCount == 0) {
        responseTimeText = 'N/A';
      } else if (avgResponse >= 4.5) {
        responseTimeText = '< 15 min';
      } else if (avgResponse >= 3.5) {
        responseTimeText = '< 30 min';
      } else if (avgResponse >= 2.5) {
        responseTimeText = '< 1 hour';
      } else if (avgResponse >= 1.5) {
        responseTimeText = '< 2 hours';
      } else {
        responseTimeText = '> 2 hours';
      }

      // Get booking stats
      final allBookings = await supabase
          .from('bookings')
          .select('status')
          .eq('caregiver_id', caregiverId);

      int total = allBookings.length;
      int completed = 0;
      for (var b in allBookings) {
        if (b['status'] == 'Completed') completed++;
      }

      double completionRate = total > 0 ? (completed / total) * 100 : 0;

      // Update caregiver profile with all calculated metrics
      await supabase.from('caregiver_profiles').update({
        'rating': avgRating,
        'satisfaction_rating': avgRating,
        'on_time_rate':
            double.parse(onTimePercent.toStringAsFixed(1)),
        'completion_rate':
            double.parse(completionRate.toStringAsFixed(1)),
        'response_time': responseTimeText,
        'total_patients': completed,
      }).eq('id', caregiverId);
    } catch (_) {}
  }

  Future<void> submitReview() async {
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select an overall rating"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    if (onTimeRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please rate the caregiver's punctuality"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    if (responseRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please rate the caregiver's response time"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please write a comment"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    if (_bookingData == null) return;

    setState(() => _isSubmitting = true);

    try {
      final caregiverId = _bookingData!['caregiver_id'];
      final patientId = _bookingData!['patient_id'];

      // Insert review with all rating fields
      await supabase.from('reviews').insert({
        'booking_id': _bookingId,
        'patient_id': patientId,
        'caregiver_id': caregiverId,
        'rating': rating,
        'on_time_rating': onTimeRating,
        'response_time_rating': responseRating,
        'comment': commentController.text.trim(),
      });

      // Recalculate caregiver metrics from all their reviews & bookings
      await _updateCaregiverMetrics(caregiverId);

      // Send notification to caregiver about the new review
      final caregiver = await supabase
          .from('caregiver_profiles')
          .select('auth_id')
          .eq('id', caregiverId)
          .single();

      final now = DateTime.now();
      await supabase.from('notifications').insert({
        'user_auth_id': caregiver['auth_id'],
        'title': 'New Review Received',
        'description':
            'You received a $rating-star review: "${commentController.text.trim()}"',
        'type': 'review',
        'related_booking': _bookingId,
        'date':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Review submitted successfully!"),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error submitting review: $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildStarRow(String label, int currentRating, ValueChanged<int> onChanged, {IconData icon = Icons.star, Color color = Colors.amber}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: AppTheme.headingMedium.copyWith(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return IconButton(
              onPressed: () => onChanged(starIndex),
              icon: Icon(
                starIndex <= currentRating ? Icons.star : Icons.star_border,
                color: color,
                size: 36,
              ),
            );
          }),
        ),
        if (currentRating > 0)
          Center(
            child: Text(
              _getRatingLabel(label, currentRating),
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  String _getRatingLabel(String category, int value) {
    if (category.contains('Overall')) {
      const labels = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];
      return labels[value];
    } else if (category.contains('Punctuality')) {
      const labels = [
        '',
        'Very Late',
        'Late',
        'On Time',
        'Early',
        'Always On Time'
      ];
      return labels[value];
    } else if (category.contains('Response')) {
      const labels = [
        '',
        '> 2 hours',
        '< 2 hours',
        '< 1 hour',
        '< 30 min',
        '< 15 min'
      ];
      return labels[value];
    }
    return '';
  }

  Widget detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: AppTheme.bodyText.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTheme.bodyText),
          ),
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
          "Caregiver Review",
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar:
          const CareReceiverNavigationBarMobile(currentIndex: 1),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _bookingData == null
              ? const Center(child: Text("Booking details not found."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Session Details ──
                      Text("Session Details", style: AppTheme.headingMedium),
                      const SizedBox(height: 12),
                      Card(
                        color: AppTheme.surface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              detailRow("Date",
                                  _bookingData!['date'] ?? "N/A"),
                              detailRow("Time",
                                  "${_bookingData!['start_time']} - ${_bookingData!['end_time'] ?? 'Ongoing'}"),
                              detailRow(
                                  "Caregiver",
                                  _bookingData!['caregiver_profiles']
                                          ?['name'] ??
                                      "Unknown"),
                              detailRow("Service",
                                  _bookingData!['service_type'] ?? "N/A"),
                              detailRow("Location",
                                  _bookingData!['location'] ?? "N/A"),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Overall Rating ──
                      _buildStarRow(
                        'Overall Rating',
                        rating,
                        (val) => setState(() => rating = val),
                        icon: Icons.star,
                        color: Colors.amber,
                      ),

                      const SizedBox(height: 20),
                      Divider(color: Colors.grey[200]),
                      const SizedBox(height: 16),

                      // ── Punctuality / On-Time Rating ──
                      _buildStarRow(
                        'Punctuality (On-Time)',
                        onTimeRating,
                        (val) => setState(() => onTimeRating = val),
                        icon: Icons.schedule,
                        color: Colors.green,
                      ),

                      const SizedBox(height: 20),
                      Divider(color: Colors.grey[200]),
                      const SizedBox(height: 16),

                      // ── Response Time Rating ──
                      _buildStarRow(
                        'Response Time',
                        responseRating,
                        (val) => setState(() => responseRating = val),
                        icon: Icons.flash_on,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 28),

                      // ── Comment ──
                      Text("Write a Review", style: AppTheme.headingMedium),
                      const SizedBox(height: 10),
                      TextField(
                        controller: commentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              "Describe the caregiver's service...",
                          filled: true,
                          fillColor: AppTheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.primary),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ── Submit Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2))
                              : const Text("Submit Review",
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
