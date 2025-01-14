import 'package:cabsudapp/services/route_page.dart';
import 'package:flutter/material.dart';

import 'distance_page.dart';

class ServiceSelectionPage extends StatefulWidget {
  const ServiceSelectionPage({super.key});

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  String? selectedService;

  // Services data model
  final List<Map<String, dynamic>> services = [
    {
      'name': 'Airport Transport',
      'imagePath': 'assets/intro/airport_transportation.jpg',
    },
    {
      'name': 'Cruise Transport',
      'imagePath': 'assets/intro/cruise_transport.jpg',
    },
    {
      'name': 'Train Station Transport',
      'imagePath': 'assets/intro/gare_transport.jpg',
    },
    {
      'name': 'Car at Disposal',
      'imagePath': 'assets/intro/mise_a_disposition.jpg',
    },
    {
      'name': 'Tourism',
      'imagePath': 'assets/intro/tourisem_transport.jpg',
    },
  ];

  void navigateToPage() {
    Widget nextPage;

    switch (selectedService) {
      case 'Airport Transport':
        nextPage = DistanceCalculator();
        break;
      case 'Cruise Transport':
        nextPage = DistanceCalculator();
        break;
      case 'Train Station Transport':
        nextPage = DistanceCalculator();
        break;
      case 'Car at Disposal':
        nextPage = const RoutePage();
        break;
      case 'Tourism':
        nextPage = const RoutePage();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Select a Service',
          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                final isSelected = selectedService == service['name'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedService = service['name'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: isSelected
                        ? BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFD4AF37),
                          Color(0xFFF7EF8A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    )
                        : BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      margin: isSelected ? const EdgeInsets.all(2) : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14)),
                            child: Image.asset(
                              service['imagePath'],
                              fit: BoxFit.cover,
                              height: 180,
                              width: double.infinity,
                            ),
                          ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Selected',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              service['name'],
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFD4AF37)
                                    : Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (selectedService != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: navigateToPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
