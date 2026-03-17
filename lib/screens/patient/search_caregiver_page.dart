import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../core/locations.dart';
import '../../widgets/carereceiver_navigationbar_mobile.dart';

class CaregiverSearchPage extends StatefulWidget {
  const CaregiverSearchPage({super.key});

  @override
  State<CaregiverSearchPage> createState() => _CaregiverSearchPageState();
}

class _CaregiverSearchPageState extends State<CaregiverSearchPage> {
  final supabase = Supabase.instance.client;
  String searchText = '';
  String? expandedName;
  bool _isLoading = true;
  List<Map<String, dynamic>> _caregivers = [];
  String? _patientLocation;
  String? _selectedFilterLocation;
  String? _selectedFilterGender;

  final _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final uid = supabase.auth.currentUser!.id;

      // Load patient's location
      final patient = await supabase
          .from('patient_profiles')
          .select('location')
          .eq('auth_id', uid)
          .single();

      final patientLocation = patient['location'] as String?;

      // Load all active caregivers (include gender in the select)
      final data = await supabase
          .from('caregiver_profiles')
          .select(
              'id, name, email, phone, gender, experience_years, total_patients, profile_image_url, service_area, verified, hourly_rate, reviews(rating)')
          .eq('status', 'Active');

      List<Map<String, dynamic>> processedCaregivers = [];

      for (var doc in data) {
        final caregiver = Map<String, dynamic>.from(doc);
        final reviews = caregiver['reviews'] as List<dynamic>? ?? [];

        double avgRating = 0.0;
        if (reviews.isNotEmpty) {
          double sum = 0;
          for (var r in reviews) {
            sum += (r['rating'] as num).toDouble();
          }
          avgRating = sum / reviews.length;
        }

        caregiver['calculated_rating'] = avgRating;
        caregiver['review_count'] = reviews.length;

        processedCaregivers.add(caregiver);
      }

      processedCaregivers.sort((a, b) => (b['calculated_rating'] as double)
          .compareTo(a['calculated_rating'] as double));

      if (mounted) {
        setState(() {
          _caregivers = processedCaregivers;
          _patientLocation = patientLocation;
          _selectedFilterLocation = patientLocation;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _caregivers = [];
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get filteredCaregivers {
    var list = _caregivers;

    // Filter by selected location
    if (_selectedFilterLocation != null &&
        _selectedFilterLocation!.isNotEmpty) {
      list = list
          .where((c) =>
              (c['service_area'] ?? '')
                  .toString()
                  .toLowerCase() ==
              _selectedFilterLocation!.toLowerCase())
          .toList();
    }

    // Filter by gender
    if (_selectedFilterGender != null &&
        _selectedFilterGender!.isNotEmpty) {
      list = list
          .where((c) =>
              (c['gender'] ?? '')
                  .toString()
                  .toLowerCase() ==
              _selectedFilterGender!.toLowerCase())
          .toList();
    }

    // Then filter by search text
    if (searchText.isNotEmpty) {
      list = list
          .where((c) =>
              (c['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(searchText.toLowerCase()) ||
              (c['service_area'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(searchText.toLowerCase()))
          .toList();
    }

    return list;
  }

  Widget buildSearchBar() {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Search caregiver...',
        prefixIcon: Icon(Icons.search, color: AppTheme.primary),
      ),
      onChanged: (value) {
        setState(() {
          searchText = value;
        });
      },
    );
  }

  Widget buildLocationFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilterLocation,
          isExpanded: true,
          hint: const Text('All Locations'),
          icon: const Icon(Icons.location_on, color: AppTheme.primary),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('All Locations'),
            ),
            ...SriLankanLocations.districts.map((loc) => DropdownMenuItem(
                  value: loc,
                  child: Text(loc),
                )),
          ],
          onChanged: (val) {
            setState(() {
              _selectedFilterLocation =
                  (val == null || val.isEmpty) ? null : val;
            });
          },
        ),
      ),
    );
  }

  Widget buildGenderFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilterGender,
          isExpanded: true,
          hint: const Text('All Genders'),
          icon: const Icon(Icons.wc, color: AppTheme.primary),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('All Genders'),
            ),
            ..._genderOptions.map((g) => DropdownMenuItem(
                  value: g,
                  child: Text(g),
                )),
          ],
          onChanged: (val) {
            setState(() {
              _selectedFilterGender =
                  (val == null || val.isEmpty) ? null : val;
            });
          },
        ),
      ),
    );
  }

  Widget buildCaregiverCard(Map<String, dynamic> caregiver) {
    bool isExpanded = expandedName == caregiver['name'];

    final rating = caregiver['calculated_rating'] as double;
    final ratingDisplay = rating > 0 ? rating.toStringAsFixed(1) : '0.0';

    final experience = caregiver['experience_years'] ?? 0;
    final patients = caregiver['total_patients'] ?? 0;
    final gender = caregiver['gender'] as String?;
    final caregiverId = caregiver['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          expandedName = isExpanded ? null : caregiver['name'];
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.softGreen,
                    child: Text(
                      (caregiver['name'] ?? 'C')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caregiver['name'] ?? 'Caregiver',
                          style:
                              AppTheme.headingMedium.copyWith(fontSize: 16),
                        ),
                        Row(
                          children: [
                            if (caregiver['service_area'] != null) ...[
                              const Icon(Icons.location_on,
                                  size: 14, color: AppTheme.primary),
                              const SizedBox(width: 2),
                              Text(
                                caregiver['service_area'],
                                style: AppTheme.bodyText
                                    .copyWith(fontSize: 12),
                              ),
                            ],
                            if (gender != null &&
                                gender.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Icon(
                                gender == 'Male'
                                    ? Icons.male
                                    : gender == 'Female'
                                        ? Icons.female
                                        : Icons.transgender,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                gender,
                                style: AppTheme.bodyText
                                    .copyWith(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        ratingDisplay,
                        style: AppTheme.bodyText
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                        width: 100,
                        child: Text('Experience',
                            style: AppTheme.bodyText
                                .copyWith(color: Colors.grey[600]))),
                    Text('$experience years',
                        style: AppTheme.bodyText
                            .copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                        width: 100,
                        child: Text('Patients',
                            style: AppTheme.bodyText
                                .copyWith(color: Colors.grey[600]))),
                    Text('$patients',
                        style: AppTheme.bodyText
                            .copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (gender != null && gender.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                          width: 100,
                          child: Text('Gender',
                              style: AppTheme.bodyText
                                  .copyWith(color: Colors.grey[600]))),
                      Text(gender,
                          style: AppTheme.bodyText
                              .copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                if (caregiver['hourly_rate'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                          width: 100,
                          child: Text('Rate',
                              style: AppTheme.bodyText
                                  .copyWith(color: Colors.grey[600]))),
                      Text('LKR ${caregiver['hourly_rate']}/hr',
                          style: AppTheme.bodyText
                              .copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/caregiver_details',
                            arguments: caregiverId,
                          );
                        },
                        child: const Text('View Profile'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/patient_request-caregiver',
                            arguments: caregiverId,
                          );
                        },
                        child: const Text('Book'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedFilterLocation != null) count++;
    if (_selectedFilterGender != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredCaregivers;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Find Caregiver',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildSearchBar(),
                  const SizedBox(height: 12),

                  // Filters row
                  Row(
                    children: [
                      Expanded(child: buildLocationFilter()),
                      const SizedBox(width: 10),
                      Expanded(child: buildGenderFilter()),
                    ],
                  ),

                  if (_patientLocation != null &&
                      _selectedFilterLocation == _patientLocation)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 14, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Showing caregivers in your area ($_patientLocation)',
                              style: AppTheme.bodyText.copyWith(
                                  fontSize: 12, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_activeFilterCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Text(
                            '${list.length} caregiver${list.length == 1 ? '' : 's'} found',
                            style: AppTheme.bodyText.copyWith(
                                fontSize: 12,
                                color: AppTheme.textGrey),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilterLocation = null;
                                _selectedFilterGender = null;
                              });
                            },
                            child: Text(
                              'Clear filters',
                              style: AppTheme.bodyText.copyWith(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off,
                                    size: 48,
                                    color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  _activeFilterCount > 0
                                      ? 'No caregivers match your filters'
                                      : searchText.isEmpty
                                          ? 'No caregivers available'
                                          : 'No results for "$searchText"',
                                  style: AppTheme.bodyText,
                                  textAlign: TextAlign.center,
                                ),
                                if (_activeFilterCount > 0) ...[
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFilterLocation = null;
                                        _selectedFilterGender = null;
                                      });
                                    },
                                    child:
                                        const Text('Clear all filters'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppTheme.primary,
                            child: ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                return buildCaregiverCard(list[index]);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar:
          const CareReceiverNavigationBarMobile(currentIndex: 1),
    );
  }
}
