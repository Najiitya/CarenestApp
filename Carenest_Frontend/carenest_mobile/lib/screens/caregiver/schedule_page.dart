import 'package:flutter/material.dart';
import 'package:carenest_mobile/core/app_theme.dart';
import '../../widgets/caregiver_navigationbar_mobile.dart';

class CaregiverJobRequestsPage extends StatefulWidget {
  const CaregiverJobRequestsPage({super.key});

  @override
  State<CaregiverJobRequestsPage> createState() =>
      _CaregiverJobRequestsPageState();
}

class _CaregiverJobRequestsPageState extends State<CaregiverJobRequestsPage> {

  List<Map<String, dynamic>> requests = [
    {
      "name": "John Silva",
      "age": 72,
      "location": "Negombo"
    },
    {
      "name": "Mary Fernando",
      "age": 68,
      "location": "Colombo"
    },
    {
      "name": "Sunil Perera",
      "age": 75,
      "location": "Gampaha"
    }
  ];

  void acceptRequest(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Accepted request from $name"),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void viewProfile(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Viewing profile of $name"),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void cancelRequest(int index) {
    setState(() {
      requests.removeAt(index);
    });
  }

  Widget buildRequestCard(Map request, int index) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TOP ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Text(
                request["name"],
                style: AppTheme.titleStyle,
              ),

              GestureDetector(
                onTap: () => cancelRequest(index),
                child: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// AGE
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 6),
              Text(
                "Age: ${request["age"]}",
                style: AppTheme.bodyStyle,
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// LOCATION
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 6),
              Text(
                request["location"],
                style: AppTheme.bodyStyle,
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// BUTTONS
          Row(
            children: [

              Expanded(
                child: OutlinedButton(
                  onPressed: () => viewProfile(request["name"]),
                  child: const Text("View Profile"),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton(
                  style: AppTheme.primaryButtonStyle,
                  onPressed: () => acceptRequest(request["name"]),
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

      backgroundColor: AppTheme.backgroundColor,

      appBar: AppBar(
        title: const Text("Job Requests"),
        backgroundColor: AppTheme.primaryColor,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return buildRequestCard(requests[index], index);
          },
        ),
      ),

      /// CAREGIVER NAV BAR ADDED
      bottomNavigationBar:
          const CaregiverNavigationBarMobile(currentIndex: 1),
    );
  }
}