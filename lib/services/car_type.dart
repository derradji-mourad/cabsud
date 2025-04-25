import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../commande/commande.dart';
import '../localization/string.dart'; // Update this if your Strings.dart path is different
import 'date.dart';

class VehicleSelectionPage extends StatefulWidget {
  final String origin; // "distance" or "route"
  final double? distance;
  final double? durationInMinutes;

  const VehicleSelectionPage({
    Key? key,
    required this.origin,
    this.distance,
    this.durationInMinutes,
  }) : super(key: key);

  @override
  State<VehicleSelectionPage> createState() => _VehicleSelectionPageState();
}

class _VehicleSelectionPageState extends State<VehicleSelectionPage> {
  String? selectedVehicle;
  bool _isLanguageLoaded = false;

  final List<Map<String, dynamic>> vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? selectedLanguage = prefs.getString('language');

    if (selectedLanguage == null) {
      selectedLanguage = 'fr';
      await prefs.setString('language', 'fr');
    }

     Strings.load(selectedLanguage);

    setState(() {
      _isLanguageLoaded = true;
    });
  }

  double calculateCost(Map<String, dynamic> vehicle) {
    return (widget.distance! * vehicle['rate']) +
        (widget.durationInMinutes! * vehicle['minuteRate']) +
        vehicle['priseEnCharge'];
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final strings = Strings.of(context);
    final bool isFromDistance = widget.origin == 'distance';

    vehicles.clear();
    vehicles.addAll([
      {
        'type': strings.vehicleTypeEco,
        'rate': 1.55,
        'minuteRate': 0.30,
        'priseEnCharge': 4.5,
        'fixedPrice': '20€/h',
        'imagePath': 'assets/cars/eco.png',
        'passengers': 3,
        'bags': 3,
        'description': strings.vehicleDescEco,
      },
      {
        'type': strings.vehicleTypeBerline,
        'rate': 2.00,
        'minuteRate': 0.45,
        'priseEnCharge': 7.0,
        'fixedPrice': '30€/h',
        'imagePath': 'assets/cars/classE.png',
        'passengers': 4,
        'bags': 4,
        'description': strings.vehicleDescBerline,
      },
      {
        'type': strings.vehicleTypeVan,
        'rate': 2.20,
        'minuteRate': 0.45,
        'priseEnCharge': 7.5,
        'fixedPrice': '40€/h',
        'imagePath': 'assets/cars/van.png',
        'passengers': 7,
        'bags': 7,
        'description': strings.vehicleDescVan,
      },
    ]);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFAE8625),
              Color(0xFFF7EF8A),
              Color(0xFFD2AC47),
              Color(0xFFEDC967),
            ],
          ).createShader(bounds),
          child: Text(
            strings.vehicleSelectionTitle,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final isSelected = selectedVehicle == vehicle['type'];
                final cost = isFromDistance ? calculateCost(vehicle) : null;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedVehicle = vehicle['type'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                        colors: [
                          Color(0xFFAE8625),
                          Color(0xFFF7EF8A),
                          Color(0xFFD2AC47),
                          Color(0xFFEDC967),
                        ],
                      )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.transparent, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child: Image.asset(vehicle['imagePath'],
                                height: 150)),
                        const SizedBox(height: 10),
                        Text(vehicle['type'],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        Text(vehicle['description'],
                            style: TextStyle(
                              color:
                              isSelected ? Colors.black54 : Colors.grey,
                            )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${strings.vehiclePassengers}: ${vehicle['passengers']}",
                                style: TextStyle(
                                  color:
                                  isSelected ? Colors.black : Colors.white,
                                )),
                            Text("${strings.vehicleBags}: ${vehicle['bags']}",
                                style: TextStyle(
                                  color:
                                  isSelected ? Colors.black : Colors.white,
                                )),
                          ],
                        ),
                        Text(
                          isFromDistance
                              ? "${strings.vehiclePrice}: ${cost!.toStringAsFixed(2)} €"
                              : "${strings.vehicleFixedPrice}: ${vehicle['fixedPrice']}",
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.yellow,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (selectedVehicle != null)
            Container(
              margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFAE8625),
                    Color(0xFFF7EF8A),
                    Color(0xFFD2AC47),
                    Color(0xFFEDC967),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AppointmentScreen(origin: widget.origin),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  strings.continueButton,
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
