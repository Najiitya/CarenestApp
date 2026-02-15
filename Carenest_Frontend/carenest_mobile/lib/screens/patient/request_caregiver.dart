import 'package:flutter/material.dart';
import 'package:carenest_mobile/core/app_theme.dart';

class RequestCarePage extends StatefulWidget {
  const RequestCarePage({Key? key}) : super(key: key);

  @override
  State<RequestCarePage> createState() => _RequestCarePageState();
}

class _RequestCarePageState extends State<RequestCarePage> {
  String? serviceType;
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  final TextEditingController locationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final List<String> serviceTypes = ['Home care', 'Hospital Care'];

  Future<void> pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> pickStartTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => startTime = time);
    }
  }

  Future<void> pickEndTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => endTime = time);
    }
  }

  void submitRequest() {
    if (serviceType == null ||
        selectedDate == null ||
        startTime == null ||
        endTime == null ||
        locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Care request submitted successfully')),
    );

    // Clear form after submission
    setState(() {
      serviceType = null;
      selectedDate = null;
      startTime = null;
      endTime = null;
      locationController.clear();
      notesController.clear();
    });
  }

  Widget buildToggleButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    bool isSelected = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: isSelected ? Colors.white : AppTheme.primary),
      label: Text(
        text,
        style: AppTheme.bodyText.copyWith(
          color: isSelected ? Colors.white : AppTheme.textDark,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: isSelected ? AppTheme.primary : AppTheme.surface,
        side: BorderSide(color: AppTheme.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark, // your Figma primary color
        elevation: 0, // removes shadow
        centerTitle: true, // title centered
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.pop(context); // go back
          },
        ),
        title: Text(
          'Request Care',
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Type
            Text('Service Type', style: AppTheme.headingMedium),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: serviceType,
              hint: const Text('Select service type'),
              items: serviceTypes.map((service) {
                return DropdownMenuItem(value: service, child: Text(service));
              }).toList(),
              onChanged: (value) => setState(() => serviceType = value),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppTheme.primary, // focused border color
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Date
            Text('Select Date', style: AppTheme.headingMedium),
            const SizedBox(height: 14),
            buildToggleButton(
              onPressed: pickDate,
              text: selectedDate == null
                  ? 'Select Date'
                  : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              icon: Icons.calendar_today,
              isSelected: selectedDate != null,
            ),

            const SizedBox(height: 30),

            // Start & End Time
            Text('Select Time', style: AppTheme.headingMedium),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: buildToggleButton(
                    onPressed: pickStartTime,
                    text: startTime == null
                        ? 'Start Time'
                        : startTime!.format(context),
                    icon: Icons.access_time,
                    isSelected: startTime != null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: buildToggleButton(
                    onPressed: pickEndTime,
                    text: endTime == null
                        ? 'End Time'
                        : endTime!.format(context),
                    icon: Icons.access_time,
                    isSelected: endTime != null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Location
            Text('Location', style: AppTheme.headingMedium),
            const SizedBox(height: 14),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                hintText: 'Home address or Hospital name',
                filled: true,
                fillColor: AppTheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppTheme.primary, // normal border color
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppTheme.primary, // focused border color
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Notes
            Text('Additional Notes', style: AppTheme.headingMedium),

            const SizedBox(height: 14),
            TextField(
              controller: notesController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Enter additional notes...',
                filled: true,
                fillColor: AppTheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppTheme.primary, // normal border color
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppTheme.primary, // focused border color
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),

      // Submit Button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, // <-- change your color here
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                // optional: rounded corners
              ),
            ),
            child: Text('Request Care', style: AppTheme.buttonText),
          ),
        ),
      ),
    );
  }
}
