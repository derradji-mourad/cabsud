import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cabsudapp/commande/succed.dart';
import 'package:cabsudapp/commande/payment.dart';
import 'package:cabsudapp/custom_page_route.dart';
import 'package:cabsudapp/reuse/theme.dart';

class TripSummaryPage extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const TripSummaryPage({super.key, required this.tripData});

  @override
  State<TripSummaryPage> createState() => _TripSummaryPageState();
}

class _TripSummaryPageState extends State<TripSummaryPage>
    with TickerProviderStateMixin {
  String? type, description, imagePath, fixedPrice, origin;
  int? passengers, bags;
  double? price, distanceKm, durationMin;
  String? pickupAddress, destinationAddress, tripDateTime;
  String? pickupAddress1, tripDuration, tripDateTime1;
  String? region, zipcode, userId;

  bool _isLoading = true;
  bool _isSubmitting = false;

  // FIXED: Initialize with default values or make nullable
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // FIXED: Initialize animations FIRST before anything else
    _initAnimations();
    _loadTripInfo();
  }

  void _initAnimations() {
    // Initialize controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize animations AFTER controllers
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadTripInfo() async {
    final prefs = await SharedPreferences.getInstance();

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return; // Safety check

    setState(() {
      type = widget.tripData['vehicleType'] ??
          prefs.getString('selectedVehicleType');
      description = prefs.getString('selectedVehicleDesc') ?? '';
      imagePath = prefs.getString('imagePath');

      passengers = widget.tripData['passengers'] is String
          ? int.tryParse(widget.tripData['passengers']) ??
              prefs.getInt('passengers')
          : widget.tripData['passengers'] ?? prefs.getInt('passengers');

      bags = widget.tripData['bags'] is String
          ? int.tryParse(widget.tripData['bags']) ?? prefs.getInt('bags')
          : widget.tripData['bags'] ?? prefs.getInt('bags');

      origin = widget.tripData['origin'] ?? prefs.getString('origin');
      region = widget.tripData['region'] ?? prefs.getString('region');
      zipcode = widget.tripData['zipcode'] ?? prefs.getString('zipcode');
      userId = widget.tripData['user_id'] ?? prefs.getString('user_id');

      if (origin == 'distance') {
        price =
            widget.tripData['price']?.toDouble() ?? prefs.getDouble('price');
        distanceKm = widget.tripData['distance_km']?.toDouble() ??
            prefs.getDouble('distance_km');
        durationMin = widget.tripData['duration_min']?.toDouble() ??
            prefs.getDouble('duration_min');
        pickupAddress = prefs.getString('pickup_address');
        destinationAddress = prefs.getString('destination_address');
        tripDateTime = prefs.getString('trip_datetime');
      } else if (origin == 'route') {
        fixedPrice =
            widget.tripData['fixedPrice'] ?? prefs.getString('fixedPrice');
        pickupAddress1 = widget.tripData['pickup1_address'] ??
            prefs.getString('pickup1_address');
        tripDuration = widget.tripData['trip1_duration'] ??
            prefs.getString('trip1_duration');
        tripDateTime1 = widget.tripData['trip1_datetime'] ??
            prefs.getString('trip1_datetime');
      }

      _isLoading = false;
    });
  }

  Future<void> _submitTrip() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final String servicetype = origin == 'distance' ? 'Transfer' : 'Custom';

    final rawDateTime = origin == 'distance'
        ? (tripDateTime ?? prefs.getString('trip_datetime'))
        : (tripDateTime1 ?? prefs.getString('trip1_datetime'));

    String formattedDateTime = '';

    if (rawDateTime != null) {
      final parsed = DateTime.tryParse(rawDateTime);
      if (parsed != null) {
        formattedDateTime = parsed.toIso8601String();
      }
    }

    if (formattedDateTime.isEmpty) {
      _showErrorSnackBar("Invalid or missing trip date and time.");
      setState(() => _isSubmitting = false);
      return;
    }

    final regionValue = widget.tripData['region'] ?? prefs.getString('region');
    final zipcodeValue =
        widget.tripData['zipcode'] ?? prefs.getString('zipcode');
    final userIdValue =
        widget.tripData['user_id'] ?? prefs.getString('user_id');

    if (regionValue == null || zipcodeValue == null || userIdValue == null) {
      _showErrorSnackBar(
          "Missing required fields: region, zip code, or user ID.");
      setState(() => _isSubmitting = false);
      return;
    }

    final pickuplocation =
        widget.tripData['pickuplocation'] ?? prefs.getString('pickup_address');
    final dropofflocation = widget.tripData['dropofflocation'] ??
        prefs.getString('destination_address');

    if (pickuplocation == null ||
        (servicetype == 'Transfer' && dropofflocation == null)) {
      _showErrorSnackBar("Missing pickup or dropoff location.");
      setState(() => _isSubmitting = false);
      return;
    }

    final requestData = {
      'firstname': widget.tripData['firstName'] ?? prefs.getString('firstName'),
      'lastname': widget.tripData['lastName'] ?? prefs.getString('lastName'),
      'phonenumber': widget.tripData['phone'] ?? prefs.getString('phone'),
      'email': widget.tripData['email'] ?? prefs.getString('email'),
      'user_id': userIdValue,
      'pickuplocation': pickuplocation,
      'dropofflocation': servicetype == 'Transfer' ? dropofflocation : null,
      'datetime': formattedDateTime,
      'city': widget.tripData['city'] ?? prefs.getString('city'),
      'region': regionValue,
      'address': widget.tripData['address'] ?? prefs.getString('address'),
      'zipcode': int.tryParse(zipcodeValue ?? ''),
      'servicetype': servicetype,
      'vehicle_type': type,
      'is_cash': widget.tripData['is_cash'] ?? true,
      'additionalinfo': widget.tripData['additionalInfo'] ??
          prefs.getString('additionalInfo'),
      'extraInfo': widget.tripData['extraInfo'] ?? prefs.getString('extraInfo'),
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://utypxmgyfqfwlkpkqrff.supabase.co/functions/v1/create_service_request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final isCash = widget.tripData['is_cash'] ?? true;

        if (!mounted) return;

        if (isCash) {
          Navigator.of(context)
              .push(CustomPageRoute(child: const SuccessPage()));
        } else {
          Navigator.of(context).push(
              CustomPageRoute(child: PaymentScreen(requestId: userIdValue)));
        }
      } else {
        _showErrorDialog(response.statusCode, response.body, requestData);
      }
    } catch (e) {
      _showErrorSnackBar("Failed to send request: $e");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.softWhite),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        elevation: 8,
      ),
    );
  }

  void _showErrorDialog(
      int statusCode, String body, Map<String, dynamic> requestData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: const Text(
          "Server Error",
          style:
              TextStyle(color: AppTheme.softWhite, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            "Status Code: $statusCode\nResponse Body: $body\n\nSent JSON:\n${const JsonEncoder.withIndent('  ').convert(requestData)}",
            style: const TextStyle(color: AppTheme.offWhite, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "Fermer",
              style: TextStyle(color: AppTheme.primaryGold),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isLoading ? _buildLoadingState() : _buildContent(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      centerTitle: true,
      title: ShaderMask(
        shaderCallback: (b) => AppTheme.subtleGoldGradient.createShader(b),
        child: const Text(
          'RÉCAPITULATIF',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 3,
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: AppTheme.primaryGold.withValues(alpha: 0.75),
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.primaryGold.withValues(alpha: 0.25),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      key: const ValueKey('loading'),
      decoration: AppTheme.luxuryBackgroundGradient,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildContent() {
    final formattedDateTime1 = tripDateTime1 != null
        ? DateFormat('yyyy-MM-dd – HH:mm')
            .format(DateTime.parse(tripDateTime1!))
        : 'N/A';

    return Container(
      key: const ValueKey('content'),
      decoration: AppTheme.luxuryBackgroundGradient,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: AppTheme.spaceM),
                _buildVehicleCard(),
                const SizedBox(height: AppTheme.spaceL),
                _buildPassengerCard(formattedDateTime1),
                const SizedBox(height: AppTheme.spaceXL),
                _buildConfirmButton(),
                const SizedBox(height: AppTheme.spaceL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ... Rest of the widget methods remain the same ...
  // (Copy all the _buildVehicleCard, _buildPassengerCard, _buildConfirmButton, etc. from previous code)

  Widget _buildVehicleCard() {
    return Hero(
      tag: 'vehicle_card',
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: AppTheme.premiumCardDecoration,
          padding: const EdgeInsets.all(AppTheme.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: AppTheme.primaryGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VOTRE VÉHICULE',
                          style: TextStyle(
                            color: AppTheme.primaryGold.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type ?? 'N/A',
                          style: const TextStyle(
                            color: AppTheme.softWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (imagePath != null) ...[
                const SizedBox(height: AppTheme.spaceL),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    child: Image.asset(
                      imagePath!,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spaceL),
              const _LuxuryDivider(),
              const SizedBox(height: AppTheme.spaceM),
              _InfoRow(
                  icon: Icons.info_outline, label: 'Catégorie', value: description ?? 'N/A'),
              const SizedBox(height: AppTheme.spaceS),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                        icon: Icons.people_outline, value: '$passengers', label: 'Passagers'),
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child:
                        _StatChip(icon: Icons.luggage_outlined, value: '$bags', label: 'Bagages'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceM),
              if (origin == 'distance') ...[
                _buildPriceSection(),
                const SizedBox(height: AppTheme.spaceS),
                _InfoRow(icon: Icons.route, label: 'Distance',
                    value: '${distanceKm?.toStringAsFixed(2)} km'),
                const SizedBox(height: AppTheme.spaceS),
                _InfoRow(icon: Icons.access_time, label: 'Durée',
                    value: '${durationMin?.toStringAsFixed(0)} min'),
              ] else if (origin == 'route') ...[
                _buildFixedPriceSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerCard(String formattedDateTime1) {
    return Container(
      decoration: AppTheme.premiumCardDecoration,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Text(
                'INFORMATIONS PASSAGER',
                style: TextStyle(
                  color: AppTheme.primaryGold.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceL),
          const _LuxuryDivider(),
          const SizedBox(height: AppTheme.spaceM),
          _InfoItem(label: "Nom",
              value: "${widget.tripData['firstName']} ${widget.tripData['lastName']}"),
          if (widget.tripData['companyName'] != null &&
              widget.tripData['companyName'].isNotEmpty)
            _InfoItem(label: "Société", value: widget.tripData['companyName']),
          _InfoItem(label: "Adresse",
              value: "${widget.tripData['address']}, ${widget.tripData['city']}, ${widget.tripData['zipcode']}, ${widget.tripData['region']}"),
          _InfoItem(label: "Téléphone", value: widget.tripData['phone']),
          _InfoItem(label: "Email", value: widget.tripData['email']),
          _InfoItem(label: "Date & Heure",
              value: origin == 'route' ? formattedDateTime1 : (tripDateTime ?? 'N/A')),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Hero(
      tag: 'confirm_button',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          gradient: AppTheme.subtleGoldGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSubmitting ? null : _submitTrip,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.richBlack),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: AppTheme.richBlack, size: 22),
                        SizedBox(width: AppTheme.spaceS),
                        Text(
                          'CONFIRMER LA RÉSERVATION',
                          style: TextStyle(
                            color: AppTheme.richBlack,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 1.5,
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


  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGold.withValues(alpha: 0.2),
            AppTheme.accentGold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'PRIX TOTAL',
            style: TextStyle(
              color: AppTheme.softWhite.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            '€${price?.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppTheme.primaryGold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedPriceSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGold.withValues(alpha: 0.2),
            AppTheme.accentGold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'PRIX FIXE',
            style: TextStyle(
              color: AppTheme.softWhite.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            fixedPrice ?? 'N/A',
            style: const TextStyle(
              color: AppTheme.primaryGold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────
//  EXTRACTED WIDGETS
// ─────────────────────────────────────────────────────────────

class _LuxuryDivider extends StatelessWidget {
  const _LuxuryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.primaryGold.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 20),
        const SizedBox(width: AppTheme.spaceS),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppTheme.offWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.softWhite,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.slate.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryGold, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.softWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.offWhite.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.offWhite.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                color: AppTheme.softWhite,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
