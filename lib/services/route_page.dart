import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'car_type.dart';
import '../localization/string.dart';

const String googleApiKey = 'AIzaSyA98tXlKLb3JRZWUv8tFZMeNCQ55VBINaI';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  _RoutePageState createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFAE8625),
                    Color(0xFFF7EF8A),
                    Color(0xFFD2AC47),
                    Color(0xFFEDC967),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.black),
                  const SizedBox(height: 16),
                  Text(
                    Strings.of(context).infoTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Strings.of(context).infoDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        Strings.of(context).understood,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFAE8625),
              Color(0xFFF7EF8A),
              Color(0xFFD2AC47),
              Color(0xFFEDC967)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            Strings.of(context).planJourney,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SimpleInterface(),
      ),
      backgroundColor: Colors.black,
    );
  }
}

class SimpleInterface extends StatefulWidget {
  const SimpleInterface({super.key});

  @override
  _SimpleInterfaceState createState() => _SimpleInterfaceState();
}

class _SimpleInterfaceState extends State<SimpleInterface> {
  final TextEditingController _departureController = TextEditingController();
  int duration = 1;
  List<String> suggestions = [];
  Timer? debounceTimer;
  LatLng? selectedLocation;
  GoogleMapController? _mapController;

  Future<void> fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => suggestions = []);
      return;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$googleApiKey&components=country:fr';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            suggestions = data['predictions']
                .map<String>((item) => item['description'].toString())
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  void onDepartureChanged(String value) {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 300), () {
      fetchSuggestions(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          buildCard(
            child: Column(
              children: [
                TextField(
                  controller: _departureController,
                  decoration: InputDecoration(
                    labelText: Strings.of(context).departureAddress,
                    labelStyle: const TextStyle(color: Colors.white),
                    prefixIcon: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFAE8625), Color(0xFFF7EF8A), Color(0xFFD2AC47), Color(0xFFEDC967)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Icon(Icons.location_on, color: Colors.white),
                    ),
                    enabledBorder: _gradientBorder(),
                    focusedBorder: _gradientBorder(),
                    border: _gradientBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => onDepartureChanged(value),
                ),
                if (suggestions.isNotEmpty)
                  Container(
                    color: Colors.black,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            suggestions[index],
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () async {
                            final address = suggestions[index];
                            setState(() {
                              _departureController.text = address;
                              suggestions.clear();
                            });

                            List<Location> locations = await locationFromAddress(address);
                            if (locations.isNotEmpty) {
                              final loc = locations.first;
                              setState(() {
                                selectedLocation = LatLng(loc.latitude, loc.longitude);
                              });

                              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(selectedLocation!, 14));
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          buildCard(
            child: DropdownButtonFormField<int>(
              value: duration,
              decoration: InputDecoration(
                labelText: Strings.of(context).durationLabel,
                labelStyle: const TextStyle(color: Colors.white),
                enabledBorder: _gradientBorder(),
                focusedBorder: _gradientBorder(),
                border: _gradientBorder(),
              ),
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
              onChanged: (value) => setState(() => duration = value ?? 1),
              items: List.generate(24, (index) => index + 1)
                  .map((hour) => DropdownMenuItem(
                value: hour,
                child: Text('$hour ${hour > 1 ? Strings.of(context).hours : Strings.of(context).hour}',
                    style: const TextStyle(color: Colors.white)),
              ))
                  .toList(),
            ),
          ),
          if (selectedLocation != null)
            Container(
              height: 300,
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD2AC47)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: selectedLocation!,
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected-location'),
                      position: selectedLocation!,
                      infoWindow: InfoWindow(title: _departureController.text),
                    ),
                  },
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                ),
              ),
            ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFAE8625), Color(0xFFF7EF8A), Color(0xFFD2AC47), Color(0xFFEDC967)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => VehicleSelectionPage(origin: 'route')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                Strings.of(context).continueButton,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard({required Widget child}) {
    return Card(
      color: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(padding: const EdgeInsets.all(12.0), child: child),
    );
  }

  InputBorder _gradientBorder() {
    return const OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFD2AC47), width: 2),
    );
  }
}
