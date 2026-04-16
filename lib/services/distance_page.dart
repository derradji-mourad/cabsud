import 'dart:async';
import 'dart:convert';
import 'package:cabsudapp/reuse/isolate_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cabsudapp/reuse/theme.dart';
import '../custom_page_route.dart';
import 'car_type.dart';
import '../localization/string.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cabsudapp/reuse/map_style.dart';
import 'package:geocoding/geocoding.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Ultra-luxury distance calculator with premium animations and micro-interactions
class DistanceCalculator extends StatefulWidget {
  const DistanceCalculator({super.key});

  @override
  DistanceCalculatorState createState() => DistanceCalculatorState();
}

class DistanceCalculatorState extends State<DistanceCalculator>
    with TickerProviderStateMixin {
  // Controllers
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  GoogleMapController? _mapController;
  final _polylinePoints = PolylinePoints();

  // State
  final ValueNotifier<List<String>> _pickupSuggestionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<List<String>> _destinationSuggestionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<DateTime?> _dateTimeNotifier = ValueNotifier(null);
  final ValueNotifier<String> _distanceNotifier = ValueNotifier('');
  final ValueNotifier<String> _durationNotifier = ValueNotifier('');
  final ValueNotifier<Set<Polyline>> _polylinesNotifier = ValueNotifier({});
  final ValueNotifier<Set<Marker>> _markersNotifier = ValueNotifier({});
  final ValueNotifier<int> _currentStepNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _isCalculatingNotifier = ValueNotifier(false);

  Timer? _debounceTimer;
  bool _isLanguageLoaded = false;

  // Animations
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOutCubic,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeLanguage();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _mapController?.dispose();
    _debounceTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    _pickupSuggestionsNotifier.dispose();
    _destinationSuggestionsNotifier.dispose();
    _dateTimeNotifier.dispose();
    _distanceNotifier.dispose();
    _durationNotifier.dispose();
    _polylinesNotifier.dispose();
    _markersNotifier.dispose();
    _currentStepNotifier.dispose();
    _isCalculatingNotifier.dispose();
    super.dispose();
  }

  Future<void> _initializeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedLanguage = prefs.getString('language') ?? 'fr';
    if (!prefs.containsKey('language')) {
      await prefs.setString('language', selectedLanguage);
    }
    Strings.load(selectedLanguage);

    if (mounted) {
      setState(() => _isLanguageLoaded = true);
      _fadeController.forward();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = '${place.street}, ${place.locality}, ${place.country}';
        if (mounted) {
          setState(() {
            _pickupController.text = address;
            // Trigger any necessary UI updates or route drawing if destination is already set
            if (_destinationController.text.isNotEmpty) {
              _drawRoute();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _onAddressChanged(String query, bool isPickup) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchAddressSuggestions(query, isPickup);
    });
  }

  Future<void> _fetchAddressSuggestions(String query, bool isPickup) async {
    if (query.isEmpty) {
      if (isPickup) {
        _pickupSuggestionsNotifier.value = [];
      } else {
        _destinationSuggestionsNotifier.value = [];
      }
      return;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}'
        '&components=country:fr'
        '&language=fr',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final suggestions = await parseAddressSuggestions(response.body);

        if (mounted) {
          if (isPickup) {
            _pickupSuggestionsNotifier.value = suggestions;
          } else {
            _destinationSuggestionsNotifier.value = suggestions;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  bool _canProceed() {
    return _pickupController.text.trim().isNotEmpty &&
        _destinationController.text.trim().isNotEmpty &&
        _dateTimeNotifier.value != null;
  }

  Future<void> _calculateAndNavigate() async {
    if (!_canProceed()) return;

    _isCalculatingNotifier.value = true;
    HapticFeedback.mediumImpact();

    try {
      final jwt = await _getValidAccessToken();
      if (jwt == null) {
        _isCalculatingNotifier.value = false;
        return;
      }

      final response = await http.post(
        Uri.parse(
            '${dotenv.env['SUPABASE_URL']}/functions/v1/calculate_fare_from_address'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': dotenv.env['SUPABASE_ANON_KEY']!,
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'pickup': _pickupController.text,
          'destination': _destinationController.text,
          'servicetype': 'Transfer',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['totalFares'] != null && data['totalFares'].isNotEmpty) {
          final fare = data['totalFares'][0];
          final distanceKm = (fare['distance_km'] as num).toDouble();
          final durationMin = (fare['duration_min'] as num).toDouble();

          _distanceNotifier.value = '${distanceKm.toStringAsFixed(2)} km';
          _durationNotifier.value = '${durationMin.toStringAsFixed(0)} min';

          await _saveTripDetails();

          if (mounted) {
            Navigator.of(context).push(
              CustomPageRoute(
                child: VehicleSelectionPage(
                  origin: 'distance',
                  totalFares:
                      List<Map<String, dynamic>>.from(data['totalFares']),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      _showErrorSnackbar('Une erreur est survenue');
    } finally {
      _isCalculatingNotifier.value = false;
    }
  }

  Future<void> _drawRoute() async {
    if (_pickupController.text.isEmpty || _destinationController.text.isEmpty) {
      return;
    }

    try {
      final coordinates = await Future.wait([
        _getCoordinatesForAddress(_pickupController.text),
        _getCoordinatesForAddress(_destinationController.text),
      ]);

      final pickupLatLng =
          LatLng(coordinates[0]['lat']!, coordinates[0]['lon']!);
      final destinationLatLng =
          LatLng(coordinates[1]['lat']!, coordinates[1]['lon']!);

      final directionsUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${coordinates[0]['lat']},${coordinates[0]['lon']}'
        '&destination=${coordinates[1]['lat']},${coordinates[1]['lon']}'
        '&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}',
      );

      final response = await http.get(directionsUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final polylineEncoded =
              data['routes'][0]['overview_polyline']['points'];
          final decodedPoints = _polylinePoints.decodePolyline(polylineEncoded);
          final routeCoordinates = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          _animateRoute(routeCoordinates, pickupLatLng, destinationLatLng);
        }
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
    }
  }

  void _animateRoute(
      List<LatLng> fullRoute, LatLng pickup, LatLng destination) {
    final animated = <LatLng>[];
    int index = 0;

    _polylinesNotifier.value = {};
    _markersNotifier.value = {};

    Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextIndex = (index + 10).clamp(0, fullRoute.length);
      animated.addAll(fullRoute.getRange(index, nextIndex));

      _polylinesNotifier.value = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: List<LatLng>.from(animated),
          color: AppTheme.primaryGold,
          width: 5,
          patterns: [PatternItem.dot, PatternItem.gap(8)],
        ),
      };

      index = nextIndex;

      if (index >= fullRoute.length) {
        timer.cancel();
        _addMarkers(pickup, destination);
        _animateCamera(pickup, destination);
      }
    });
  }

  void _addMarkers(LatLng pickup, LatLng destination) {
    _markersNotifier.value = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickup,
        infoWindow: InfoWindow(title: Strings.of(context).adresseDePickup),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        infoWindow: InfoWindow(title: Strings.of(context).adresseDeDestination),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };
  }

  void _animateCamera(LatLng pickup, LatLng destination) {
    if (_mapController == null) return;

    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              pickup.latitude < destination.latitude
                  ? pickup.latitude
                  : destination.latitude,
              pickup.longitude < destination.longitude
                  ? pickup.longitude
                  : destination.longitude,
            ),
            northeast: LatLng(
              pickup.latitude > destination.latitude
                  ? pickup.latitude
                  : destination.latitude,
              pickup.longitude > destination.longitude
                  ? pickup.longitude
                  : destination.longitude,
            ),
          ),
          100,
        ),
      );
    });
  }

  Future<Map<String, double>> _getCoordinatesForAddress(String address) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?address=${Uri.encodeComponent(address)}'
      '&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = await parseJsonMap(response.body);
      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        return {'lat': location['lat'], 'lon': location['lng']};
      }
    }
    throw Exception('Failed to geocode address');
  }

  Future<void> _saveTripDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pickup_address', _pickupController.text);
    await prefs.setString('destination_address', _destinationController.text);
    if (_dateTimeNotifier.value != null) {
      await prefs.setString(
          'trip_datetime', _dateTimeNotifier.value!.toIso8601String());
    }
  }

  Future<String?> _getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) {
      await _showSessionExpiredDialog();
      return null;
    }

    try {
      final response =
          await Supabase.instance.client.auth.refreshSession(refreshToken);
      final jwt = response.session?.accessToken;

      if (jwt != null) {
        await prefs.setString('jwt_token', jwt);
        return jwt;
      } else {
        await _showSessionExpiredDialog();
        return null;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await _showSessionExpiredDialog();
      return null;
    }
  }

  Future<void> _showSessionExpiredDialog() async {
    if (!mounted) return;
    // Implementation here
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.luxuryBackgroundGradient,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryGold.withValues(alpha: 0.2),
                              AppTheme.primaryGold.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          size: 48,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryGold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: AppTheme.luxuryBackgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              _buildLuxuryAppBar(),
              _buildProgressIndicator(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(),
                ),
              ),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryAppBar() {
    return const _LuxuryAppBar();
  }

  Widget _buildProgressIndicator() {
    return ValueListenableBuilder<int>(
      valueListenable: _currentStepNotifier,
      builder: (context, currentStep, _) {
        final hasPickup = _pickupController.text.isNotEmpty;
        final hasDestination = _destinationController.text.isNotEmpty;
        final hasDateTime = _dateTimeNotifier.value != null;
        final progress = (hasPickup && hasDestination && hasDateTime)
            ? 1.0
            : ((hasPickup && hasDestination) ? 0.66 : (hasPickup ? 0.33 : 0.0));

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: progress),
                  curve: Curves.easeInOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: AppTheme.slate.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryGold),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStepLabel('📍 From', hasPickup),
                  _buildStepLabel('🎯 To', hasDestination),
                  _buildStepLabel('📅 When', hasDateTime),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepLabel(String label, bool isComplete) {
    return Text(
      label,
      style: TextStyle(
        color: isComplete
            ? AppTheme.primaryGold
            : AppTheme.offWhite.withValues(alpha: 0.4),
        fontSize: 12,
        fontWeight: isComplete ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildContent() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _pickupSuggestionsNotifier.value = [];
        _destinationSuggestionsNotifier.value = [];
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildAddressField(
              controller: _pickupController,
              label: Strings.of(context).adresseDePickup,
              icon: Icons.trip_origin_rounded,
              suggestionsNotifier: _pickupSuggestionsNotifier,
              isPickup: true,
            ),
            const SizedBox(height: 20),
            _buildAddressField(
              controller: _destinationController,
              label: Strings.of(context).adresseDeDestination,
              icon: Icons.location_on_rounded,
              suggestionsNotifier: _destinationSuggestionsNotifier,
              isPickup: false,
            ),
            const SizedBox(height: 20),
            _buildDateTimePicker(),
            const SizedBox(height: 24),
            _buildMapView(),
            const SizedBox(height: 20),
            _buildDistanceInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueNotifier<List<String>> suggestionsNotifier,
    required bool isPickup,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.charcoal.withValues(alpha: 0.6),
                AppTheme.deepCharcoal.withValues(alpha: 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGold.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: (value) => _onAddressChanged(value, isPickup),
            style: const TextStyle(
              color: AppTheme.softWhite,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: AppTheme.offWhite.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              floatingLabelStyle: const TextStyle(
                color: AppTheme.primaryGold,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(icon, color: AppTheme.primaryGold, size: 24),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
        ValueListenableBuilder<List<String>>(
          valueListenable: suggestionsNotifier,
          builder: (context, suggestions, _) {
            if (suggestions.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppTheme.deepCharcoal,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGold.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: suggestions.length,
                separatorBuilder: (context, index) => Divider(
                  color: AppTheme.primaryGold.withValues(alpha: 0.1),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.text = suggestions[index];
                        suggestionsNotifier.value = [];

                        if (_pickupController.text.isNotEmpty &&
                            _destinationController.text.isNotEmpty) {
                          _drawRoute();
                          _currentStepNotifier.value = 2;
                        } else if (isPickup) {
                          _currentStepNotifier.value = 1;
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGold
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: AppTheme.primaryGold,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                suggestions[index],
                                style: const TextStyle(
                                  color: AppTheme.softWhite,
                                  fontSize: 15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: _dateTimeNotifier,
      builder: (context, selectedDateTime, _) {
        return InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            final now = DateTime.now();

            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDateTime ?? now,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
              builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppTheme.primaryGold,
                    onPrimary: AppTheme.richBlack,
                    surface: AppTheme.charcoal,
                    onSurface: AppTheme.softWhite,
                  ),
                  dialogTheme:
                      const DialogThemeData(backgroundColor: AppTheme.charcoal),
                ),
                child: child!,
              ),
            );

            if (pickedDate == null) return;
            if (!mounted) return;

            final pickedTime = await showTimePicker(
              // ignore: use_build_context_synchronously
              context: context,
              initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? now),
              builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppTheme.primaryGold,
                    onPrimary: AppTheme.richBlack,
                    surface: AppTheme.charcoal,
                    onSurface: AppTheme.softWhite,
                  ),
                  dialogTheme:
                      const DialogThemeData(backgroundColor: AppTheme.charcoal),
                ),
                child: child!,
              ),
            );

            if (pickedTime != null && mounted) {
              _dateTimeNotifier.value = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );
              _currentStepNotifier.value = 3;
              HapticFeedback.mediumImpact();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.charcoal.withValues(alpha: 0.6),
                  AppTheme.deepCharcoal.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selectedDateTime != null
                    ? AppTheme.primaryGold
                    : AppTheme.primaryGold.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGold.withValues(alpha: 0.3),
                        AppTheme.primaryGold.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppTheme.primaryGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedDateTime == null
                            ? 'Select date & time'
                            : 'Scheduled',
                        style: TextStyle(
                          color: AppTheme.offWhite.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedDateTime == null
                            ? 'Tap to choose'
                            : DateFormat('dd/MM/yyyy HH:mm')
                                .format(selectedDateTime),
                        style: const TextStyle(
                          color: AppTheme.softWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selectedDateTime != null
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: selectedDateTime != null
                      ? AppTheme.primaryGold
                      : AppTheme.offWhite.withValues(alpha: 0.5),
                  size: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    final mapHeight = (MediaQuery.of(context).size.height * 0.3).clamp(180.0, 300.0);
    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ValueListenableBuilder<Set<Polyline>>(
          valueListenable: _polylinesNotifier,
          builder: (context, polylines, _) {
            return ValueListenableBuilder<Set<Marker>>(
              valueListenable: _markersNotifier,
              builder: (context, markers, _) {
                return GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(48.8566, 2.3522),
                    zoom: 12,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  style: luxuryMapStyle,
                  polylines: polylines,
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDistanceInfo() {
    return ValueListenableBuilder<String>(
      valueListenable: _distanceNotifier,
      builder: (context, distance, _) {
        return ValueListenableBuilder<String>(
          valueListenable: _durationNotifier,
          builder: (context, duration, _) {
            final hasInfo = distance.isNotEmpty && duration.isNotEmpty;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: hasInfo
                    ? AppTheme.primaryGold.withValues(alpha: 0.15)
                    : AppTheme.charcoal.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasInfo
                      ? AppTheme.primaryGold.withValues(alpha: 0.5)
                      : AppTheme.primaryGold.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasInfo
                          ? Icons.check_circle_rounded
                          : Icons.route_rounded,
                      color: AppTheme.primaryGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      hasInfo
                          ? '$distance • $duration'
                          : 'Route info will appear here',
                      style: TextStyle(
                        color: hasInfo
                            ? AppTheme.softWhite
                            : AppTheme.offWhite.withValues(alpha: 0.6),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.richBlack.withValues(alpha: 0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: _isCalculatingNotifier,
        builder: (context, isCalculating, _) {
          final canProceed = _canProceed();

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: canProceed && !isCalculating
                  ? const LinearGradient(
                      colors: [AppTheme.primaryGold, AppTheme.accentGold],
                    )
                  : LinearGradient(
                      colors: [
                        AppTheme.slate.withValues(alpha: 0.3),
                        AppTheme.slate.withValues(alpha: 0.2),
                      ],
                    ),
              boxShadow: canProceed && !isCalculating
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryGold.withValues(alpha: 0.5),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    canProceed && !isCalculating ? _calculateAndNavigate : null,
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: isCalculating
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.richBlack),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'CALCULATING...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.richBlack,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              canProceed
                                  ? Icons.calculate_rounded
                                  : Icons.lock_outline_rounded,
                              color: canProceed
                                  ? AppTheme.richBlack
                                  : AppTheme.offWhite.withValues(alpha: 0.3),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              canProceed
                                  ? Strings.of(context)
                                      .calculerLaDistance
                                      .toUpperCase()
                                  : 'COMPLETE ALL STEPS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: canProceed
                                    ? AppTheme.richBlack
                                    : AppTheme.offWhite.withValues(alpha: 0.3),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LuxuryAppBar extends StatelessWidget {
  const _LuxuryAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.richBlack.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.primaryGold,
                size: 20,
              ),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          Expanded(
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.subtleGoldGradient.createShader(bounds),
                child: Text(
                  Strings.of(context).saisissezVotreAdresse,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
