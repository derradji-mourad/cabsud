import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'car_type.dart';

class DistanceCalculator extends StatefulWidget {
  @override
  _DistanceCalculatorState createState() => _DistanceCalculatorState();
}

class _DistanceCalculatorState extends State<DistanceCalculator> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  String distance = '';
  DateTime? pickupDateTime;
  bool isRoundTrip = false;

  List<String> pickupSuggestions = [];
  List<String> destinationSuggestions = [];

  Future<Map<String, double>> getCoordinates(String address) async {
    final String url =
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&addressdetails=1&limit=1&countrycodes=FR';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          return {
            'lat': double.parse(data[0]['lat']),
            'lon': double.parse(data[0]['lon'])
          };
        }
        throw 'Address not found';
      }
      throw 'Failed to fetch coordinates';
    } catch (e) {
      throw 'Error: $e';
    }
  }

  Future<void> calculateDistance(String pickup, String destination) async {
    try {
      final pickupCoordinates = await getCoordinates(pickup);
      final destinationCoordinates = await getCoordinates(destination);

      final String url =
          'http://router.project-osrm.org/route/v1/driving/${pickupCoordinates['lon']},${pickupCoordinates['lat']};${destinationCoordinates['lon']},${destinationCoordinates['lat']}?overview=false';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double distanceInMeters = data['routes'][0]['distance'];
        final double distanceInKilometers = distanceInMeters / 1000;

        setState(() {
          distance = '${distanceInKilometers.toStringAsFixed(2)} km';
        });

        // Navigate to the vehicle selection page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleSelectionPage(
              distance: distanceInKilometers,

            ),
          ),
        );
      } else {
        setState(() {
          distance = 'Failed to calculate distance.';
        });
      }
    } catch (e) {
      setState(() {
        distance = 'Error: $e';
      });
    }
  }

  Future<void> getAddressSuggestions(String query, bool isPickup) async {
    final url =
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5&countrycodes=FR';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final suggestions =
        data.map((item) => item['display_name'].toString()).toList();
        setState(() {
          if (isPickup) {
            pickupSuggestions = suggestions;
          } else {
            destinationSuggestions = suggestions;
          }
        });
      }
    } catch (_) {
      // Handle error silently
    }
  }

  Future<void> selectPickupDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          pickupDateTime = DateTime(
              date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.black,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFD4AF37)),
          bodyMedium: TextStyle(color: Color(0xFFD4AF37)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black,
          labelStyle: TextStyle(color: Color(0xFFD4AF37)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD4AF37)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Distance Calculator'),
          centerTitle: true,
          backgroundColor: Colors.black,
          foregroundColor: Color(0xFFD4AF37),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildInputField(
                  controller: pickupController,
                  label: 'Pickup Address',
                  icon: Icons.location_on,
                  onChanged: (value) => getAddressSuggestions(value, true),
                ),
                const SizedBox(height: 10),
                buildInputField(
                  controller: destinationController,
                  label: 'Destination Address',
                  icon: Icons.flag,
                  onChanged: (value) =>
                      getAddressSuggestions(value, false),
                ),
                const SizedBox(height: 10),
                if (pickupSuggestions.isNotEmpty)
                  buildSuggestionList(pickupSuggestions, true),
                if (destinationSuggestions.isNotEmpty)
                  buildSuggestionList(destinationSuggestions, false),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: selectPickupDateTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFD4AF37)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pickupDateTime != null
                              ? 'Pickup: ${pickupDateTime!.toLocal()}'.split(
                              '.')[0]
                              : 'Select Pickup Date & Time',
                          style: const TextStyle(
                              fontSize: 16, color: Color(0xFFD4AF37)),
                        ),
                        const Icon(Icons.calendar_today,
                            color: Color(0xFFD4AF37)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: isRoundTrip,
                      onChanged: (value) => setState(() {
                        isRoundTrip = value!;
                      }),
                    ),
                    const Text('Allez/Retour',
                        style: TextStyle(fontSize: 16, color: Color(0xFFD4AF37))),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFAEB625),
                        Color(0xFFF7EF8A),
                        Color(0xFFD2AC47),
                        Color(0xFFEDC967),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      calculateDistance(
                        pickupController.text,
                        destinationController.text,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Calculate Distance',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: Colors.black,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      distance.isNotEmpty
                          ? 'Distance: $distance${isRoundTrip ? ' (Round Trip)' : ''}'
                          : 'Enter addresses to calculate distance',
                      style: const TextStyle(
                          fontSize: 18, color: Color(0xFFD4AF37)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Color(0xFFD4AF37)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFFD4AF37)),
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  Widget buildSuggestionList(List<String> suggestions, bool isPickup) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            suggestions[index],
            style: const TextStyle(color: Color(0xFFD4AF37)),
          ),
          onTap: () {
            setState(() {
              if (isPickup) {
                pickupController.text = suggestions[index];
                pickupSuggestions.clear();
              } else {
                destinationController.text = suggestions[index];
                destinationSuggestions.clear();
              }
            });
          },
        );
      },
    );
  }
}



