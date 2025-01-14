import 'package:flutter/material.dart';

import '../commande/commande.dart';

class VehicleSelectionPage extends StatefulWidget {
  final double distance; // Pass the distance from the previous page

  const VehicleSelectionPage({Key? key, required this.distance}) : super(key: key);

  @override
  State<VehicleSelectionPage> createState() => _VehicleSelectionPageState();
}

class _VehicleSelectionPageState extends State<VehicleSelectionPage> {
  String? selectedVehicle;

  // Vehicle data model
  final List<Map<String, dynamic>> vehicles = [
    {
      'type': 'Eco',
      'passengers': 3,
      'bags': 3,
      'imagePath': 'assets/cars/eco.png', // Add your image path here
      'description': 'Economic & Comfortable',
      'rate': 25, // Rate per kilometer for Eco
    },
    {
      'type': 'Berline',
      'passengers': 4,
      'bags': 4,
      'imagePath': 'assets/cars/classE.png', // Add your image path here
      'description': 'Premium Comfort',
      'rate': 50, // Rate per kilometer for Berline
    },
    {
      'type': 'Van',
      'passengers': 7,
      'bags': 7,
      'imagePath': 'assets/cars/van.png', // Add your image path here
      'description': 'Group Travel',
      'rate': 100, // Rate per kilometer for Van
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Select Your Vehicle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final isSelected = selectedVehicle == vehicle['type'];
                final double cost = widget.distance * vehicle['rate']; // Calculate the cost

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedVehicle = vehicle['type'];
                    });
                    // Add further action here if needed
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Vehicle Image
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            color: Colors.grey[900],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                // Display the vehicle image
                                child: Image.asset(
                                  vehicle['imagePath'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  right: 16,
                                  top: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Selected',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Vehicle Details
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    vehicle['type'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    vehicle['description'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  // Passengers capacity
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person, color: Colors.white70),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${vehicle['passengers']} Passengers',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Bags capacity
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.work, color: Colors.white70),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${vehicle['bags']} Bags',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Cost Display
                              Row(
                                children: [
                                  const Icon(Icons.attach_money, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cost: \$${cost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Continue Button
          if (selectedVehicle != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>   CommandePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
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