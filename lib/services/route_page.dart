import 'dart:async';
import 'dart:convert';
import 'package:cabsudapp/reuse/isolate_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cabsudapp/custom_page_route.dart';
import 'package:cabsudapp/reuse/theme.dart';
import 'car_type.dart';
import '../localization/string.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cabsudapp/reuse/map_style.dart';

const _kGeocodeUrl =
    'https://utypxmgyfqfwlkpkqrff.supabase.co/functions/v1/geocode-address';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  RoutePageState createState() => RoutePageState();
}

class RoutePageState extends State<RoutePage> with TickerProviderStateMixin {
  bool _isLanguageLoaded = false;
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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

    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String selectedLanguage = prefs.getString('language') ?? 'fr';
    await prefs.setString('language', selectedLanguage);
    Strings.load(selectedLanguage);

    if (!mounted) return;

    _pulseController.stop();
    setState(() => _isLanguageLoaded = true);
    _fadeController.forward();

    // Show welcome dialog after a slight delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _showWelcomeDialog();
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.darkGold,
                        AppTheme.primaryGold,
                        AppTheme.accentGold,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGold.withValues(alpha: 0.6),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.richBlack.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          size: 56,
                          color: AppTheme.richBlack,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        Strings.of(context).infoTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.richBlack,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Strings.of(context).infoDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.richBlack,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: AppTheme.richBlack,
                            foregroundColor: AppTheme.primaryGold,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                Strings.of(context).understood,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
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

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
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
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const LuxuryRouteInterface(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryAppBar() {
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
                  Strings.of(context).planJourney,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }
}

/// Ultra-luxury route interface with step-by-step flow
class LuxuryRouteInterface extends StatefulWidget {
  const LuxuryRouteInterface({super.key});

  @override
  State<LuxuryRouteInterface> createState() => _LuxuryRouteInterfaceState();
}

class _LuxuryRouteInterfaceState extends State<LuxuryRouteInterface>
    with SingleTickerProviderStateMixin {
  final TextEditingController _departureController = TextEditingController();
  final ValueNotifier<List<String>> _suggestionsNotifier =
      ValueNotifier<List<String>>([]);
  final ValueNotifier<int> _durationNotifier = ValueNotifier<int>(1);
  final ValueNotifier<DateTime?> _dateTimeNotifier =
      ValueNotifier<DateTime?>(null);
  final ValueNotifier<LatLng?> _locationNotifier = ValueNotifier<LatLng?>(null);
  final ValueNotifier<int> _currentStepNotifier = ValueNotifier<int>(0);

  Timer? _debounceTimer;
  GoogleMapController? _mapController;
  late final AnimationController _stepAnimController;

  @override
  void initState() {
    super.initState();
    _stepAnimController = AnimationController(
      vsync: this,
    );
    _fillCurrentLocation();
  }

  @override
  void dispose() {
    _departureController.dispose();
    _suggestionsNotifier.dispose();
    _durationNotifier.dispose();
    _dateTimeNotifier.dispose();
    _locationNotifier.dispose();
    _debounceTimer?.cancel();
    _stepAnimController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      _suggestionsNotifier.value = [];
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          'https://utypxmgyfqfwlkpkqrff.supabase.co/functions/v1/autocomplete',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
        },
        body: jsonEncode({'input': query}),
      );
      if (response.statusCode == 200) {
        final suggestions = await parsePlacesV1Suggestions(response.body);
        if (mounted) {
          _suggestionsNotifier.value = suggestions;
        }
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  void _onDepartureChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 400),
      () => _fetchSuggestions(value),
    );
  }

  Future<void> _fillCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

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
            _departureController.text = address;
          });

          final latLng = LatLng(position.latitude, position.longitude);
          _locationNotifier.value = latLng;
          _currentStepNotifier.value =
              1; // Move to next step if desired or just fill it

          // Animate map if map controller is ready (might not be yet, but we update notifier)
          if (_mapController != null) {
            _mapController!
                .animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _saveTripDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pickup1_address', _departureController.text);
    await prefs.setString('trip1_duration', _durationNotifier.value.toString());
    if (_dateTimeNotifier.value != null) {
      await prefs.setString(
          'trip1_datetime', _dateTimeNotifier.value!.toIso8601String());
    }
  }

  bool _canProceed() {
    return _departureController.text.isNotEmpty &&
        _dateTimeNotifier.value != null;
  }

  void _handleContinue() {
    if (!_canProceed()) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Strings.of(context).fillAllFields,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    _saveTripDetails();
    Navigator.of(context).push(
      CustomPageRoute(
        child: const VehicleSelectionPage(origin: 'route'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _suggestionsNotifier.value = [];
      },
      child: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step 1: Location
                  _buildLocationCard(),
                  const SizedBox(height: 20),

                  // Step 2: Duration
                  _buildDurationCard(),
                  const SizedBox(height: 20),

                  // Step 3: Date & Time
                  _buildDateTimeCard(),

                  // Map (appears when location selected)
                  ValueListenableBuilder<LatLng?>(
                    valueListenable: _locationNotifier,
                    builder: (context, location, _) {
                      if (location == null) return const SizedBox.shrink();
                      return Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildMapCard(location),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom action button
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return ValueListenableBuilder<int>(
      valueListenable: _currentStepNotifier,
      builder: (context, currentStep, _) {
        final hasLocation = _departureController.text.isNotEmpty;
        final hasDateTime = _dateTimeNotifier.value != null;
        final progress =
            hasLocation && hasDateTime ? 1.0 : (hasLocation ? 0.5 : 0.0);

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
                  _buildStepLabel(1, '📍 Location', hasLocation),
                  _buildStepLabel(2, '📅 Schedule', hasDateTime),
                  _buildStepLabel(3, '✓ Ready', hasLocation && hasDateTime),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepLabel(int step, String label, bool isComplete) {
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

  Widget _buildLocationCard() {
    return _LuxuryCard(
      icon: Icons.location_on_rounded,
      title: Strings.of(context).departureAddress,
      child: Column(
        children: [
          TextField(
            controller: _departureController,
            style: const TextStyle(
              color: AppTheme.softWhite,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: AppTheme.primaryGold,
            decoration: InputDecoration(
              hintText: 'Enter your location...',
              hintStyle: TextStyle(
                color: AppTheme.offWhite.withValues(alpha: 0.5),
                fontSize: 16,
              ),
              filled: true,
              fillColor: AppTheme.deepCharcoal.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 12, right: 8),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryGold,
                  size: 24,
                ),
              ),
            ),
            onChanged: _onDepartureChanged,
          ),

          // Suggestions
          ValueListenableBuilder<List<String>>(
            valueListenable: _suggestionsNotifier,
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
                    return _buildSuggestionTile(suggestions[index]);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(String suggestion) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedback.selectionClick();
          _departureController.text = suggestion;
          _suggestionsNotifier.value = [];
          _currentStepNotifier.value = 1;

          try {
            final geocodeResponse = await http.post(
              Uri.parse(_kGeocodeUrl),
              headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
        },
              body: jsonEncode({'address': suggestion}),
            );
            if (geocodeResponse.statusCode == 200) {
              final coords =
                  await parseGeocodeResult(geocodeResponse.body);
              if (coords != null && mounted) {
                final newLocation = LatLng(coords['lat']!, coords['lng']!);
                _locationNotifier.value = newLocation;
                await Future.delayed(const Duration(milliseconds: 200));
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(newLocation, 14),
                );
              }
            }
          } catch (e) {
            debugPrint('Error getting location: $e');
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
                  color: AppTheme.primaryGold.withValues(alpha: 0.15),
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
                  suggestion,
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
  }

  Widget _buildDurationCard() {
    return ValueListenableBuilder<int>(
      valueListenable: _durationNotifier,
      builder: (context, duration, _) {
        return _LuxuryCard(
          icon: Icons.schedule_rounded,
          title: Strings.of(context).durationLabel,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(8, (index) {
              final hours = index + 1;
              final isSelected = duration == hours;

              return _DurationChip(
                hours: hours,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _durationNotifier.value = hours;
                },
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildDateTimeCard() {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: _dateTimeNotifier,
      builder: (context, selectedDateTime, _) {
        return _LuxuryCard(
          icon: Icons.event_rounded,
          title: 'Schedule Your Journey',
          child: InkWell(
            onTap: () => _showDateTimePicker(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.deepCharcoal.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedDateTime != null
                      ? AppTheme.primaryGold
                      : AppTheme.primaryGold.withValues(alpha: 0.3),
                  width: 2,
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
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedDateTime == null
                              ? 'Select date and time'
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
                              : '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} • '
                                  '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: AppTheme.softWhite,
                            fontSize: 17,
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
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDateTimePicker() async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateTimeNotifier.value ?? now,
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
          dialogTheme: const DialogThemeData(
            backgroundColor: AppTheme.charcoal,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dateTimeNotifier.value ?? now),
        builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryGold,
              onPrimary: AppTheme.richBlack,
              surface: AppTheme.charcoal,
              onSurface: AppTheme.softWhite,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppTheme.charcoal,
            ),
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
        _currentStepNotifier.value = 2;
        HapticFeedback.mediumImpact();
      }
    }
  }

  Widget _buildMapCard(LatLng location) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryGold.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGold.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: location,
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected-location'),
                      position: location,
                      infoWindow: InfoWindow(
                        title: _departureController.text,
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                    ),
                  },
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  style: luxuryMapStyle,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ),
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
      child: Hero(
        tag: 'continue_button',
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _dateTimeNotifier,
            _departureController,
          ]),
          builder: (context, _) {
            final canProceed = _canProceed();

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: canProceed
                    ? const LinearGradient(
                        colors: [AppTheme.primaryGold, AppTheme.accentGold],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : LinearGradient(
                        colors: [
                          AppTheme.slate.withValues(alpha: 0.3),
                          AppTheme.slate.withValues(alpha: 0.2),
                        ],
                      ),
                boxShadow: canProceed
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
                  onTap: canProceed ? _handleContinue : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          canProceed
                              ? Icons.check_circle_outline_rounded
                              : Icons.lock_outline_rounded,
                          color: canProceed
                              ? AppTheme.richBlack
                              : AppTheme.offWhite.withValues(alpha: 0.3),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          canProceed
                              ? Strings.of(context).continueButton
                              : 'Complete all steps',
                          style: TextStyle(
                            fontSize: 18,
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
      ),
    );
  }
}

/// Reusable luxury card widget
class _LuxuryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _LuxuryCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.charcoal.withValues(alpha: 0.6),
            AppTheme.deepCharcoal.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGold.withValues(alpha: 0.3),
                      AppTheme.primaryGold.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.softWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

/// Duration chip widget
class _DurationChip extends StatelessWidget {
  final int hours;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.hours,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.primaryGold, AppTheme.accentGold],
                )
              : null,
          color:
              isSelected ? null : AppTheme.deepCharcoal.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGold
                : AppTheme.primaryGold.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGold.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$hours ${hours > 1 ? 'hrs' : 'hr'}',
          style: TextStyle(
            color: isSelected ? AppTheme.richBlack : AppTheme.softWhite,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
