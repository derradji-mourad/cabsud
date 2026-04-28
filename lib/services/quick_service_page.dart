import 'dart:async';
import 'dart:convert';
import 'package:cabsudapp/reuse/isolate_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cabsudapp/reuse/theme.dart';
import '../localization/string.dart';
import '../custom_page_route.dart';
import '../home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cabsudapp/reuse/map_style.dart';

/// Quick Trip booking page - simplified form with name, pickup, and dropoff
class QuickServicePage extends StatefulWidget {
  const QuickServicePage({super.key});

  @override
  QuickServicePageState createState() => QuickServicePageState();
}

class QuickServicePageState extends State<QuickServicePage>
    with TickerProviderStateMixin {
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State
  final ValueNotifier<List<String>> _pickupSuggestionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<List<String>> _dropoffSuggestionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<bool> _isSubmittingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isSuccessNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isCalculatingFaresNotifier = ValueNotifier(false);
  final ValueNotifier<List<Map<String, dynamic>>> _availableFaresNotifier =
      ValueNotifier([]);
  final ValueNotifier<Map<String, dynamic>?> _selectedFareNotifier =
      ValueNotifier(null);
  final ValueNotifier<Set<Polyline>> _polylinesNotifier = ValueNotifier({});
  final ValueNotifier<Set<Marker>> _markersNotifier = ValueNotifier({});
  final ValueNotifier<String> _paymentMethodNotifier = ValueNotifier('cash');
  final ValueNotifier<bool> _saveCardNotifier = ValueNotifier(false);
  CardFieldInputDetails? _cardDetails;

  GoogleMapController? _mapController;
  LatLngBounds? _pendingBounds;
  final _polylinePoints = PolylinePoints();

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

    // Listen to address changes to trigger calculation
    _pickupController.addListener(_onAddressChangedListener);
    _dropoffController.addListener(_onAddressChangedListener);
  }

  @override
  void dispose() {
    _pickupController.removeListener(_onAddressChangedListener);
    _dropoffController.removeListener(_onAddressChangedListener);
    _nameController.dispose();
    _phoneController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _debounceTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    _pickupSuggestionsNotifier.dispose();
    _dropoffSuggestionsNotifier.dispose();
    _isSubmittingNotifier.dispose();
    _isSuccessNotifier.dispose();
    _isCalculatingFaresNotifier.dispose();
    _availableFaresNotifier.dispose();
    _selectedFareNotifier.dispose();
    _polylinesNotifier.dispose();
    _markersNotifier.dispose();
    _paymentMethodNotifier.dispose();
    _saveCardNotifier.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onAddressChangedListener() {
    // Reset selection if addresses change
    if (_availableFaresNotifier.value.isNotEmpty) {
      _availableFaresNotifier.value = [];
      _selectedFareNotifier.value = null;
    }
  }

  // ... (Language init logic remains same)

  void _onAddressSelected() {
    if (_pickupController.text.isNotEmpty &&
        _dropoffController.text.isNotEmpty) {
      _calculateFares();
      _drawRoute();
    }
  }

  Future<void> _calculateFares() async {
    _isCalculatingFaresNotifier.value = true;
    _selectedFareNotifier.value = null;
    _availableFaresNotifier.value = [];

    try {
      final jwt = await _getValidAccessToken();
      // Even if no JWT, we might allow calculation if public endpoint, but following existing pattern

      final response = await http.post(
        Uri.parse(
            '${dotenv.env['SUPABASE_URL']}/functions/v1/calculate_fare_from_address'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': dotenv.env['SUPABASE_ANON_KEY']!,
          if (jwt != null) 'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'pickup': _pickupController.text,
          'destination': _dropoffController.text,
          'servicetype': 'Transfer',
        }),
      );

      if (response.statusCode == 200) {
        final data = await parseJsonMap(response.body);
        if (data['totalFares'] != null) {
          final fares = List<Map<String, dynamic>>.from(data['totalFares']);
          _availableFaresNotifier.value = fares;
          if (fares.isNotEmpty) {
            // Optional: auto-select first option?
            // _selectedFareNotifier.value = fares[0];
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating fares: $e');
    } finally {
      _isCalculatingFaresNotifier.value = false;
    }
  }

  // ... (Address fetch logic remains same)

  Future<void> _submitQuickTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFareNotifier.value == null) {
      _showErrorSnackbar(Strings.of(context).selectVehicleFirst);
      return;
    }

    final isCard = _paymentMethodNotifier.value == 'card';
    if (isCard && (_cardDetails == null || !_cardDetails!.complete)) {
      _showErrorSnackbar('Please enter complete card details');
      return;
    }

    _isSubmittingNotifier.value = true;
    HapticFeedback.mediumImpact();

    try {
      final selectedFare = _selectedFareNotifier.value!;

      // Charge the card upfront when "card" is selected. If this throws
      // (network error, declined card, SCA cancelled…) we never touch the
      // backend, so no ghost trip is recorded.
      //
      // TODO: move PaymentIntent creation to a Supabase Edge Function.
      // Creating it here requires STRIPE_SECRET_KEY on the client, which is
      // extractable from the shipped APK/AAB and must not leak.
      if (isCard) {
        await _chargeCardForFare(selectedFare);
      }

      final jwt = await _getValidAccessToken();
      final response = await http.post(
        Uri.parse('${dotenv.env['SUPABASE_URL']}/functions/v1/quick_service'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': dotenv.env['SUPABASE_ANON_KEY']!,
          if (jwt != null) 'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'passenger_name': _nameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'pickup_address': _pickupController.text.trim(),
          'dropoff_address': _dropoffController.text.trim(),
          'car_type': selectedFare['vehicle_type'],
          'price': selectedFare['totalFare'],
          'distance_km': selectedFare['distance_km'],
          'duration_min': selectedFare['duration_min'],
          'payment_method': _paymentMethodNotifier.value,
          'save_card': _saveCardNotifier.value,
          'paid': isCard,
        }),
      );

      if (response.statusCode == 200) {
        _isSuccessNotifier.value = true;
        HapticFeedback.heavyImpact();
      } else {
        debugPrint(
            'Quick trip error response: ${response.statusCode} - ${response.body}');
        if (mounted) _showErrorSnackbar(Strings.of(context).tripRequestError);
      }
    } on StripeException catch (e) {
      debugPrint('Stripe error: ${e.error.code} – ${e.error.localizedMessage}');
      if (mounted) {
        _showErrorSnackbar(e.error.localizedMessage ?? 'Payment failed');
      }
    } catch (e) {
      debugPrint('Error submitting quick trip: $e');
      if (mounted) _showErrorSnackbar(Strings.of(context).tripRequestError);
    } finally {
      if (mounted) _isSubmittingNotifier.value = false;
    }
  }

  /// Create a Stripe PaymentIntent for [fare] and confirm it with the card
  /// currently entered in the [CardField]. Throws on any failure so the
  /// caller can abort the booking.
  Future<void> _chargeCardForFare(Map<String, dynamic> fare) async {
    final amountInCents = ((fare['totalFare'] as num) * 100).toInt();

    final intentResponse = await http.post(
      Uri.parse(
        'https://utypxmgyfqfwlkpkqrff.supabase.co/functions/v1/create-payment-intent',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amountInCents,
        'currency': 'eur',
        'name': _nameController.text.trim(),
      }),
    );

    if (intentResponse.statusCode != 200) {
      throw Exception(
          'Failed to create PaymentIntent (${intentResponse.statusCode})');
    }

    final intentData = await parseJsonMap(intentResponse.body);
    final clientSecret = intentData['clientSecret'] as String?;
    if (clientSecret == null) {
      throw Exception('PaymentIntent response missing clientSecret');
    }

    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(
          billingDetails: BillingDetails(
            name: _nameController.text.trim(),
          ),
        ),
      ),
    );
  }

  Future<String?> _getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) {
      return null;
    }

    try {
      final response =
          await Supabase.instance.client.auth.refreshSession(refreshToken);
      final jwt = response.session?.accessToken;

      if (jwt != null) {
        await prefs.setString('jwt_token', jwt);
        return jwt;
      }
      return null;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      return null;
    }
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
                          Icons.flash_on_rounded,
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

    return ValueListenableBuilder<bool>(
      valueListenable: _isSuccessNotifier,
      builder: (context, isSuccess, _) {
        if (isSuccess) {
          return _buildSuccessScreen();
        }
        return _buildFormScreen();
      },
    );
  }

  Widget _buildSuccessScreen() {
    return const _SuccessScreen();
  }

  Widget _buildFormScreen() {
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

  Widget _buildContent() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _pickupSuggestionsNotifier.value = [];
        _dropoffSuggestionsNotifier.value = [];
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle
              Text(
                Strings.of(context).quickServiceSubtitle,
                style: TextStyle(
                  color: AppTheme.offWhite.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              // Name field
              _buildTextField(
                controller: _nameController,
                label: Strings.of(context).passengerName,
                hint: Strings.of(context).passengerNameHint,
                icon: Icons.person_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return Strings.of(context).nameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone field
              _buildTextField(
                controller: _phoneController,
                label: Strings.of(context).phoneLabel,
                hint: Strings.of(context).phoneHint,
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return Strings.of(context).phoneValidation;
                  }
                  if (trimmed.length < 7) {
                    return Strings.of(context).phoneValidation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Pickup address
              _buildAddressField(
                controller: _pickupController,
                label: Strings.of(context).adresseDePickup,
                icon: Icons.trip_origin_rounded,
                suggestionsNotifier: _pickupSuggestionsNotifier,
                isPickup: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return Strings.of(context).pickupRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Dropoff address
              _buildAddressField(
                controller: _dropoffController,
                label: Strings.of(context).adresseDeDestination,
                icon: Icons.location_on_rounded,
                suggestionsNotifier: _dropoffSuggestionsNotifier,
                isPickup: false,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return Strings.of(context).dropoffRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Map View
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ValueListenableBuilder<Set<Polyline>>(
                    valueListenable: _polylinesNotifier,
                    builder: (context, polylines, _) {
                      return ValueListenableBuilder<Set<Marker>>(
                        valueListenable: _markersNotifier,
                        builder: (context, markers, _) {
                          return GoogleMap(
                            initialCameraPosition: const CameraPosition(
                              target:
                                  LatLng(43.2965, 5.3698), // Default Marseille
                              zoom: 12,
                            ),
                            onMapCreated: (controller) {
                              _mapController = controller;
                              final pending = _pendingBounds;
                              if (pending != null) {
                                _pendingBounds = null;
                                controller.animateCamera(
                                  CameraUpdate.newLatLngBounds(pending, 50),
                                );
                              }
                            },
                            style: luxuryMapStyle,
                            markers: markers,
                            polylines: polylines,
                            myLocationEnabled: false,
                            zoomControlsEnabled: false,
                            mapType: MapType.normal,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Vehicle Selection
              ValueListenableBuilder<bool>(
                valueListenable: _isCalculatingFaresNotifier,
                builder: (context, isCalculating, _) {
                  if (isCalculating) {
                    return Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryGold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Strings.of(context).calculatingFares,
                            style: const TextStyle(
                              color: AppTheme.softWhite,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _availableFaresNotifier,
                    builder: (context, fares, _) {
                      if (fares.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Strings.of(context).selectVehicle,
                            style: const TextStyle(
                              color: AppTheme.softWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: fares.map((fare) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ValueListenableBuilder<
                                    Map<String, dynamic>?>(
                                  valueListenable: _selectedFareNotifier,
                                  builder: (context, selectedFare, _) {
                                    final isSelected = selectedFare == fare;
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        _selectedFareNotifier.value = fare;
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryGold
                                                  .withValues(alpha: 0.1)
                                              : AppTheme.charcoal
                                                  .withValues(alpha: 0.3),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryGold
                                                : AppTheme.primaryGold
                                                    .withValues(alpha: 0.1),
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getVehicleIcon(
                                                  fare['vehicle_type']),
                                              color: isSelected
                                                  ? AppTheme.primaryGold
                                                  : AppTheme.offWhite
                                                      .withValues(alpha: 0.5),
                                              size: 32,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _getDisplayVehicleName(
                                                        fare['vehicle_type']),
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? AppTheme.primaryGold
                                                          : AppTheme.softWhite,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${fare['duration_min'].toStringAsFixed(0)} min • ${fare['distance_km'].toStringAsFixed(1)} km',
                                                    style: TextStyle(
                                                      color: AppTheme.offWhite
                                                          .withValues(
                                                              alpha: 0.5),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${(fare['totalFare'] as num).toStringAsFixed(2)}€',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? AppTheme.primaryGold
                                                    : AppTheme.softWhite,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),

                          const SizedBox(height: 32),

                          // Payment Method Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.charcoal.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    AppTheme.primaryGold.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Strings.of(context).paymentMethod,
                                  style: const TextStyle(
                                    color: AppTheme.softWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ValueListenableBuilder<String>(
                                    valueListenable: _paymentMethodNotifier,
                                    builder: (context, method, _) {
                                      return Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                  child: _buildPaymentOption(
                                                      'cash',
                                                      Strings.of(context).cash,
                                                      Icons.money,
                                                      method == 'cash')),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                  child: _buildPaymentOption(
                                                      'card',
                                                      Strings.of(context).card,
                                                      Icons.credit_card,
                                                      method == 'card')),
                                            ],
                                          ),
                                          if (method == 'card') ...[
                                            const SizedBox(height: 24),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                              decoration: BoxDecoration(
                                                color: AppTheme.deepCharcoal,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: AppTheme.primaryGold
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: CardField(
                                                onCardChanged: (card) {
                                                  _cardDetails = card;
                                                },
                                                style: const TextStyle(
                                                  color: AppTheme.softWhite,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                cursorColor:
                                                    AppTheme.primaryGold,
                                                decoration:
                                                    const InputDecoration(
                                                  border: InputBorder.none,
                                                  fillColor: Colors.transparent,
                                                  filled: false,
                                                  hintStyle: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            ValueListenableBuilder<bool>(
                                                valueListenable:
                                                    _saveCardNotifier,
                                                builder:
                                                    (context, saveCard, _) {
                                                  return GestureDetector(
                                                    onTap: () {
                                                      HapticFeedback
                                                          .selectionClick();
                                                      _saveCardNotifier.value =
                                                          !saveCard;
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(4),
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color: saveCard
                                                                  ? AppTheme
                                                                      .primaryGold
                                                                  : Colors.grey,
                                                              width: 2,
                                                            ),
                                                            color: saveCard
                                                                ? AppTheme
                                                                    .primaryGold
                                                                : null,
                                                          ),
                                                          child: saveCard
                                                              ? const Icon(
                                                                  Icons.check,
                                                                  size: 12,
                                                                  color: AppTheme
                                                                      .richBlack)
                                                              : const SizedBox(
                                                                  width: 12,
                                                                  height: 12),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Expanded(
                                                          child: Text(
                                                            'Save card for future use',
                                                            style: TextStyle(
                                                              color: AppTheme
                                                                  .offWhite
                                                                  .withValues(
                                                                      alpha: 0.8),
                                                              fontSize: 14,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                          ],
                                        ],
                                      );
                                    }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 32),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.charcoal.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryGold.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.primaryGold.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Quick trip requests are processed immediately. You will be contacted shortly.',
                        style: TextStyle(
                          color: AppTheme.offWhite.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppTheme.softWhite,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: AppTheme.offWhite.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: AppTheme.offWhite.withValues(alpha: 0.4),
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
          errorStyle: const TextStyle(color: Colors.redAccent),
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
    required String? Function(String?) validator,
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
          child: TextFormField(
            controller: controller,
            onChanged: (value) => _onAddressChanged(value, isPickup),
            validator: validator,
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
              errorStyle: const TextStyle(color: Colors.redAccent),
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
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: suggestions.length,
                separatorBuilder: (context, index) => Divider(
                  color: AppTheme.primaryGold.withValues(alpha: 0.1),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.place_rounded,
                      color: AppTheme.primaryGold.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    title: Text(
                      suggestions[index],
                      style: const TextStyle(
                        color: AppTheme.softWhite,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.text = suggestions[index];
                      suggestionsNotifier.value = [];
                      FocusScope.of(context).unfocus();
                      _onAddressSelected();
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isSubmittingNotifier,
      builder: (context, isSubmitting, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: GestureDetector(
            onTap: isSubmitting ? null : _submitQuickTrip,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: isSubmitting
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryGold.withValues(alpha: 0.5),
                          AppTheme.accentGold.withValues(alpha: 0.5),
                        ],
                      )
                    : AppTheme.primaryGoldGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSubmitting
                    ? []
                    : [
                        BoxShadow(
                          color: AppTheme.primaryGold.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Center(
                child: isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppTheme.richBlack),
                        ),
                      )
                    : Text(
                        Strings.of(context).requestTrip,
                        style: const TextStyle(
                          color: AppTheme.richBlack,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _initializeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedLanguage = prefs.getString('language') ?? 'fr';
    if (!prefs.containsKey('language')) {
      await prefs.setString('language', selectedLanguage);
    }
    Strings.load(selectedLanguage);

    if (mounted) {
      _pulseController.stop(); // Stop pulse — loading is done
      setState(() => _isLanguageLoaded = true);
      _fadeController.forward();
    }
  }

  void _onAddressChanged(String query, bool isPickup) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchAddressSuggestions(query, isPickup);
    });
  }

  Future<void> _fetchAddressSuggestions(String query, bool isPickup) async {
    if (query.length < 3) {
      if (isPickup) {
        _pickupSuggestionsNotifier.value = [];
      } else {
        _dropoffSuggestionsNotifier.value = [];
      }
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

        if (isPickup) {
          _pickupSuggestionsNotifier.value = suggestions;
        } else {
          _dropoffSuggestionsNotifier.value = suggestions;
        }
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'eco':
        return Icons.eco;
      case 'premium':
        return Icons.diamond_outlined;
      case 'van':
        return Icons.airport_shuttle;
      default:
        return Icons.directions_car;
    }
  }

  String _getDisplayVehicleName(String type) {
    switch (type.toLowerCase()) {
      case 'eco':
        return 'Eco Class';
      case 'premium':
        return 'Business Class';
      case 'van':
        return 'Van';
      default:
        return type.toUpperCase();
    }
  }

  Future<void> _drawRoute() async {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      return;
    }

    try {
      final coordinates = await Future.wait([
        _getCoordinatesForAddress(_pickupController.text),
        _getCoordinatesForAddress(_dropoffController.text),
      ]);

      final pickupLatLng =
          LatLng(coordinates[0]['lat']!, coordinates[0]['lon']!);
      final dropoffLatLng =
          LatLng(coordinates[1]['lat']!, coordinates[1]['lon']!);

      _addMarkers(pickupLatLng, dropoffLatLng);
      _animateCamera(pickupLatLng, dropoffLatLng);

      // Fetch route in a separate try-catch to ensure markers persist
      try {
        final response = await http.post(
          Uri.parse(
            'https://utypxmgyfqfwlkpkqrff.supabase.co/functions/v1/route-drawing',
          ),
          headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
        },
          body: jsonEncode({
            'originLat': pickupLatLng.latitude,
            'originLng': pickupLatLng.longitude,
            'destLat': dropoffLatLng.latitude,
            'destLng': dropoffLatLng.longitude,
          }),
        );
        if (response.statusCode == 200) {
          final routeData = await parseRoutesV2Data(response.body);
          final encodedPolyline = routeData['encodedPolyline'] as String;
          if (encodedPolyline.isNotEmpty) {
            final result = _polylinePoints.decodePolyline(encodedPolyline);
            final routeCoordinates = result
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();
            _polylinesNotifier.value = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: routeCoordinates,
                color: AppTheme.primaryGold,
                width: 5,
              ),
            };
          }
        }
      } catch (e) {
        debugPrint('Error fetching directions: $e');
      }
    } catch (e) {
      debugPrint('Error geocoding addresses: $e');
      // Show error to user so they know why map isn't appearing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Strings.of(context).tripRequestError),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  void _addMarkers(LatLng pickup, LatLng dropoff) {
    if (!mounted) return;
    _markersNotifier.value = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickup,
        infoWindow: InfoWindow(title: Strings.of(context).adresseDePickup),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: dropoff,
        infoWindow: InfoWindow(title: Strings.of(context).adresseDeDestination),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  void _animateCamera(LatLng pickup, LatLng dropoff) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        pickup.latitude < dropoff.latitude
            ? pickup.latitude
            : dropoff.latitude,
        pickup.longitude < dropoff.longitude
            ? pickup.longitude
            : dropoff.longitude,
      ),
      northeast: LatLng(
        pickup.latitude > dropoff.latitude
            ? pickup.latitude
            : dropoff.latitude,
        pickup.longitude > dropoff.longitude
            ? pickup.longitude
            : dropoff.longitude,
      ),
    );

    final controller = _mapController;
    if (controller == null) {
      // Map not yet created — apply when onMapCreated fires.
      _pendingBounds = bounds;
      return;
    }
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  Future<Map<String, double>> _getCoordinatesForAddress(String address) async {
    final response = await http.post(
      Uri.parse(
        'https://utypxmgyfqfwlkpkqrff.supabase.co/functions/v1/geocode-address',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
      },
      body: jsonEncode({'address': address}),
    );

    if (response.statusCode == 200) {
      final data = await parseJsonMap(response.body);
      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        return {'lat': location['lat'], 'lon': location['lng']};
      }
      debugPrint('Geocode status not OK: ${data['status']}');
    } else {
      debugPrint('Geocode error ${response.statusCode}: ${response.body}');
    }
    throw Exception('Failed to geocode address: ${response.statusCode}');
  }

  Widget _buildPaymentOption(
      String value, String label, IconData icon, bool isSelected) {
    return _PaymentOptionTile(
      value: value,
      label: label,
      icon: icon,
      isSelected: isSelected,
      onTap: () {
        HapticFeedback.selectionClick();
        _paymentMethodNotifier.value = value;
      },
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
                  Strings.of(context).quickServiceTitle,
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SUCCESS SCREEN (extracted widget)
// ─────────────────────────────────────────────────────────────

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.luxuryBackgroundGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGold.withValues(alpha: 0.3),
                          AppTheme.primaryGold.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 80,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        AppTheme.lightGold,
                        AppTheme.primaryGold,
                        AppTheme.accentGold,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      Strings.of(context).tripRequested,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pushAndRemoveUntil(
                        CustomPageRoute(child: const HomePage()),
                        (route) => false,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGoldGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Text(
                        Strings.of(context).backToHome,
                        style: const TextStyle(
                          color: AppTheme.richBlack,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PAYMENT OPTION TILE (extracted widget)
// ─────────────────────────────────────────────────────────────

class _PaymentOptionTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGold.withValues(alpha: 0.2)
              : AppTheme.charcoal.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGold
                : AppTheme.primaryGold.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.primaryGold : AppTheme.offWhite,
                size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryGold : AppTheme.offWhite,
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
