import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'car_type.dart';
import '../localization/string.dart'; // Assuming this is your localization class

const String googleApiKey = 'AIzaSyA98tXlKLb3JRZWUv8tFZMeNCQ55VBINaI';

class DistanceCalculator extends StatefulWidget {
  @override
  _DistanceCalculatorState createState() => _DistanceCalculatorState();
}

class _DistanceCalculatorState extends State<DistanceCalculator> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  String distanceText = '';
  String durationText = '';
  List<String> pickupSuggestions = [];
  List<String> destinationSuggestions = [];
  Timer? debounceTimer;

  GoogleMapController? mapController;
  LatLng initialCameraPosition = const LatLng(48.8566, 2.3522);
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  Set<Marker> markers = {};
  PolylinePoints polylinePoints = PolylinePoints();

  bool _isLanguageLoaded = false;

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

  Future<void> fetchSuggestions(String query, bool isPickup) async {
    if (query.isEmpty) {
      setState(() => isPickup ? pickupSuggestions = [] : destinationSuggestions = []);
      return;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$googleApiKey&components=country:fr';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          List<String> suggestions = data['predictions']
              .map<String>((item) => item['description'].toString())
              .toList();
          setState(() {
            if (isPickup) {
              pickupSuggestions = suggestions;
            } else {
              destinationSuggestions = suggestions;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  void onTextChanged(String value, bool isPickup) {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 300), () {
      fetchSuggestions(value, isPickup);
    });
  }

  Future<Map<String, double>> getCoordinates(String address) async {
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleApiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        return {
          'lat': location['lat'],
          'lon': location['lng'],
        };
      }
    }
    throw Exception('Failed to get coordinates');
  }

  Future<void> drawRouteOnMap(String pickup, String destination) async {
    try {
      final results = await Future.wait([
        getCoordinates(pickup),
        getCoordinates(destination),
      ]);

      final pickupCoordinates = results[0];
      final destinationCoordinates = results[1];

      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${pickupCoordinates['lat']},${pickupCoordinates['lon']}&destination=${destinationCoordinates['lat']},${destinationCoordinates['lon']}&key=$googleApiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          polylineCoordinates.clear();
          polylines.clear();
          markers.clear();

          final points = polylinePoints.decodePolyline(
              data['routes'][0]['overview_polyline']['points']);

          polylineCoordinates.addAll(points
              .map((e) => LatLng(e.latitude, e.longitude))
              .toList());

          setState(() {
            polylines.add(Polyline(
              polylineId: const PolylineId('previewRoute'),
              points: polylineCoordinates,
              color: Colors.yellow,
              width: 5,
            ));

            markers.add(Marker(
              markerId: const MarkerId('pickup'),
              position: LatLng(pickupCoordinates['lat']!, pickupCoordinates['lon']!),
              infoWindow: InfoWindow(title: Strings.of(context).adresseDePickup),
            ));

            markers.add(Marker(
              markerId: const MarkerId('destination'),
              position: LatLng(destinationCoordinates['lat']!, destinationCoordinates['lon']!),
              infoWindow: InfoWindow(title: Strings.of(context).adresseDeDestination),
            ));

            initialCameraPosition = LatLng(pickupCoordinates['lat']!, pickupCoordinates['lon']!);
          });

          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    pickupCoordinates['lat']! < destinationCoordinates['lat']!
                        ? pickupCoordinates['lat']!
                        : destinationCoordinates['lat']!,
                    pickupCoordinates['lon']! < destinationCoordinates['lon']!
                        ? pickupCoordinates['lon']!
                        : destinationCoordinates['lon']!,
                  ),
                  northeast: LatLng(
                    pickupCoordinates['lat']! > destinationCoordinates['lat']!
                        ? pickupCoordinates['lat']!
                        : destinationCoordinates['lat']!,
                    pickupCoordinates['lon']! > destinationCoordinates['lon']!
                        ? pickupCoordinates['lon']!
                        : destinationCoordinates['lon']!,
                  ),
                ),
                80,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
    }
  }

  Future<void> calculateDistance(String pickup, String destination) async {
    try {
      final results = await Future.wait([
        getCoordinates(pickup),
        getCoordinates(destination),
      ]);

      final pickupCoordinates = results[0];
      final destinationCoordinates = results[1];

      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${pickupCoordinates['lat']},${pickupCoordinates['lon']}&destination=${destinationCoordinates['lat']},${destinationCoordinates['lon']}&key=$googleApiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final distanceInMeters = data['routes'][0]['legs'][0]['distance']['value'];
          final durationInSeconds = data['routes'][0]['legs'][0]['duration']['value'];

          final double distanceInKilometers = distanceInMeters / 1000;
          final int durationInMinutes = (durationInSeconds / 60).round();

          setState(() {
            distanceText = '${distanceInKilometers.toStringAsFixed(2)} km';
            durationText = '$durationInMinutes ${Strings.of(context).duree}';
          });

          double parsedDistance =
              double.tryParse(distanceText.replaceAll(' km', '')) ?? 0.0;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleSelectionPage(
                origin: 'distance',
                distance: parsedDistance,
                durationInMinutes: durationInMinutes.toDouble(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        distanceText = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.yellow,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFAE8625),
              Color(0xFFF7EF8A),
              Color(0xFFD2AC47),
              Color(0xFFEDC967),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            Strings.of(context).saisissezVotreAdresse,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  buildAutocompleteTextField(
                    controller: pickupController,
                    label: Strings.of(context).adresseDePickup,
                    isPickup: true,
                  ),
                  const SizedBox(height: 15),
                  buildAutocompleteTextField(
                    controller: destinationController,
                    label: Strings.of(context).adresseDeDestination,
                    isPickup: false,
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 250,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initialCameraPosition,
                        zoom: 10,
                      ),
                      onMapCreated: (controller) => mapController = controller,
                      polylines: polylines,
                      markers: markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                  const SizedBox(height: 30),
                  buildGradientButton(),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFFD2AC47), width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFF7EF8A), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            distanceText.isNotEmpty && durationText.isNotEmpty
                                ? '${Strings.of(context).distance} : $distanceText | ${Strings.of(context).duree} : $durationText'
                                : Strings.of(context).saisissezVotreAdresse,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAutocompleteTextField({
    required TextEditingController controller,
    required String label,
    required bool isPickup,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: (value) => onTextChanged(value, isPickup),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.yellow),
            filled: true,
            fillColor: Colors.black,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                width: 2,
                color: Color(0xFFD2AC47),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                width: 3,
                color: Color(0xFFF7EF8A),
              ),
            ),
          ),
        ),
        if ((isPickup ? pickupSuggestions : destinationSuggestions).isNotEmpty)
          Container(
            color: Colors.black,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: isPickup ? pickupSuggestions.length : destinationSuggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    isPickup ? pickupSuggestions[index] : destinationSuggestions[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    setState(() {
                      controller.text = isPickup
                          ? pickupSuggestions[index]
                          : destinationSuggestions[index];
                      if (isPickup) {
                        pickupSuggestions.clear();
                      } else {
                        destinationSuggestions.clear();
                      }

                      if (pickupController.text.isNotEmpty &&
                          destinationController.text.isNotEmpty) {
                        drawRouteOnMap(
                          pickupController.text,
                          destinationController.text,
                        );
                      }
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget buildGradientButton() {
    return GestureDetector(
      onTap: () {
        calculateDistance(pickupController.text, destinationController.text);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFAE8625),
              Color(0xFFF7EF8A),
              Color(0xFFD2AC47),
              Color(0xFFEDC967),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            Strings.of(context).calculerLaDistance,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
