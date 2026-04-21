import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../commande/commande.dart';
import '../custom_page_route.dart';
import '../localization/string.dart';
import 'package:cabsudapp/reuse/theme.dart';

/// Luxury color palette for consistent theming
// Removed _LuxuryColors class as we now use AppTheme

/// Premium vehicle selection page with luxury animations and optimized performance.
///
/// Features:
/// - Staggered card entrance animations
/// - Smooth selection transitions with haptic feedback
/// - Optimized ListView rendering with const constructors
/// - Type-safe vehicle data models
class VehicleSelectionPage extends StatefulWidget {
  final String origin;
  final double? distance;
  final double? durationInMinutes;
  final List<Map<String, dynamic>>? totalFares;

  const VehicleSelectionPage({
    super.key,
    required this.origin,
    this.distance,
    this.durationInMinutes,
    this.totalFares,
  });

  @override
  State<VehicleSelectionPage> createState() => _VehicleSelectionPageState();
}

class _VehicleSelectionPageState extends State<VehicleSelectionPage>
    with TickerProviderStateMixin {
  String? _selectedVehicleType;
  bool _isLanguageLoaded = false;
  late List<_VehicleModel> _vehicles;
  late List<AnimationController> _cardAnimationControllers;
  late List<Animation<double>> _cardFadeAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
  }

  @override
  void dispose() {
    for (var controller in _cardAnimationControllers) {
      controller.dispose();
    }
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
      _initializeCardAnimations();
    }
  }

  void _initializeCardAnimations() {
    _vehicles = _buildVehicleList();

    // Create staggered entrance animations for each card
    _cardAnimationControllers = List.generate(
      _vehicles.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _cardFadeAnimations = _cardAnimationControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    _cardSlideAnimations = _cardAnimationControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();

    // Staggered animation start
    for (int i = 0; i < _cardAnimationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _cardAnimationControllers[i].forward();
      });
    }
  }

  List<_VehicleModel> _buildVehicleList() {
    final strings = Strings.of(context);

    if (widget.totalFares != null) {
      return widget.totalFares!.map((fare) {
        final type = fare['vehicle_type'] as String;
        return _VehicleModel(
          type: _getVehicleTypeName(type, strings),
          description: _getVehicleDescription(type, strings),
          imagePath: _getVehicleImagePath(type),
          passengers: _getPassengerCount(type),
          bags: _getBagCount(type),
          amenities: _getAmenities(type),
          isPopular: type == 'premium',
          price: (fare['totalFare'] as num).toDouble(),
          distanceKm: (fare['distance_km'] as num?)?.toDouble(),
          durationMin: (fare['duration_min'] as num?)?.toDouble(),
          vehicleKey: type,
        );
      }).toList();
    } else {
      return [
        _VehicleModel(
          type: strings.vehicleTypeEco,
          description: strings.vehicleDescEco,
          imagePath: 'assets/cars/eco.png',
          passengers: 3,
          bags: 3,
          amenities: _getAmenities('eco'),
          fixedPrice: '20€/h',
          rate: 1.55,
          minuteRate: 0.30,
          priseEnCharge: 4.5,
          vehicleKey: 'eco',
        ),
        _VehicleModel(
          type: strings.vehicleTypeBerline,
          description: strings.vehicleDescBerline,
          imagePath: 'assets/cars/classE.png',
          passengers: 4,
          bags: 4,
          amenities: _getAmenities('premium'),
          isPopular: true,
          fixedPrice: '30€/h',
          rate: 2.00,
          minuteRate: 0.45,
          priseEnCharge: 7.0,
          vehicleKey: 'premium',
        ),
        _VehicleModel(
          type: strings.vehicleTypeVan,
          description: strings.vehicleDescVan,
          imagePath: 'assets/cars/van.png',
          passengers: 7,
          bags: 7,
          amenities: _getAmenities('van'),
          fixedPrice: '40€/h',
          rate: 2.20,
          minuteRate: 0.45,
          priseEnCharge: 7.5,
          vehicleKey: 'van',
        ),
      ];
    }
  }

  List<_Amenity> _getAmenities(String type) {
    switch (type) {
      case 'eco':
        return const [
          _Amenity(Icons.ac_unit_rounded, 'AC'),
          _Amenity(Icons.wifi_rounded, 'Wi-Fi'),
          _Amenity(Icons.usb_rounded, 'USB'),
        ];
      case 'premium':
        return const [
          _Amenity(Icons.ac_unit_rounded, 'AC'),
          _Amenity(Icons.wifi_rounded, 'Wi-Fi'),
          _Amenity(Icons.water_drop_rounded, 'Water'),
          _Amenity(Icons.chair_rounded, 'Leather'),
        ];
      case 'van':
        return const [
          _Amenity(Icons.ac_unit_rounded, 'AC'),
          _Amenity(Icons.wifi_rounded, 'Wi-Fi'),
          _Amenity(Icons.water_drop_rounded, 'Water'),
          _Amenity(Icons.group_rounded, 'Group'),
        ];
      default:
        return const [];
    }
  }

  String _getVehicleTypeName(String type, Strings strings) {
    switch (type) {
      case 'eco':
        return strings.vehicleTypeEco;
      case 'premium':
        return strings.vehicleTypeBerline;
      case 'van':
        return strings.vehicleTypeVan;
      default:
        return type;
    }
  }

  String _getVehicleDescription(String type, Strings strings) {
    switch (type) {
      case 'eco':
        return strings.vehicleDescEco;
      case 'premium':
        return strings.vehicleDescBerline;
      case 'van':
        return strings.vehicleDescVan;
      default:
        return '';
    }
  }

  String _getVehicleImagePath(String type) {
    switch (type) {
      case 'eco':
        return 'assets/cars/eco.png';
      case 'premium':
        return 'assets/cars/classE.png';
      case 'van':
        return 'assets/cars/van.png';
      default:
        return 'assets/cars/eco.png';
    }
  }

  int _getPassengerCount(String type) {
    return type == 'van' ? 7 : (type == 'premium' ? 4 : 3);
  }

  int _getBagCount(String type) {
    return type == 'van' ? 7 : (type == 'premium' ? 4 : 3);
  }

  void _onVehicleSelected(String vehicleType) {
    HapticFeedback.selectionClick();
    setState(() => _selectedVehicleType = vehicleType);
  }

  Future<void> _proceedToBooking() async {
    if (_selectedVehicleType == null) return;

    HapticFeedback.mediumImpact();

    final selectedVehicle = _vehicles.firstWhere(
      (vehicle) => vehicle.type == _selectedVehicleType,
    );

    final prefs = await SharedPreferences.getInstance();

    // Save vehicle details
    await prefs.setString('selectedVehicleType', selectedVehicle.vehicleKey);
    await prefs.setString('selectedVehicleDesc', selectedVehicle.description);
    await prefs.setInt('passengers', selectedVehicle.passengers);
    await prefs.setInt('bags', selectedVehicle.bags);
    await prefs.setString('imagePath', selectedVehicle.imagePath);
    await prefs.setString('origin', widget.origin);

    // Save price information
    if (selectedVehicle.price != null) {
      await prefs.setDouble('price', selectedVehicle.price!);
      if (selectedVehicle.distanceKm != null) {
        await prefs.setDouble('distance_km', selectedVehicle.distanceKm!);
      }
      if (selectedVehicle.durationMin != null) {
        await prefs.setDouble('duration_min', selectedVehicle.durationMin!);
      }
    } else if (selectedVehicle.fixedPrice != null) {
      await prefs.setString('fixedPrice', selectedVehicle.fixedPrice!);
    }

    if (mounted) {
      Navigator.of(context).push(
        CustomPageRoute(
          child: CommandePage(origin: widget.origin),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: _LuxuryLoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildLuxuryAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _VehicleListView(
              vehicles: _vehicles,
              selectedVehicleType: _selectedVehicleType,
              fadeAnimations: _cardFadeAnimations,
              slideAnimations: _cardSlideAnimations,
              onVehicleSelected: _onVehicleSelected,
              isFromDistance: widget.origin == 'distance',
            ),
          ),
          _ContinueButton(
            isVisible: _selectedVehicleType != null,
            onPressed: _proceedToBooking,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildLuxuryAppBar() {
    return _LuxuryAppBar(
      title: Strings.of(context).vehicleSelectionTitle,
      onBack: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
      },
    );
  }
}

/// Type-safe vehicle data model
class _VehicleModel {
  final String type;
  final String description;
  final String imagePath;
  final int passengers;
  final int bags;
  final String vehicleKey;
  final List<_Amenity> amenities;
  final bool isPopular;
  final double? price;
  final double? distanceKm;
  final double? durationMin;
  final String? fixedPrice;
  final double? rate;
  final double? minuteRate;
  final double? priseEnCharge;

  const _VehicleModel({
    required this.type,
    required this.description,
    required this.imagePath,
    required this.passengers,
    required this.bags,
    required this.vehicleKey,
    this.amenities = const [],
    this.isPopular = false,
    this.price,
    this.distanceKm,
    this.durationMin,
    this.fixedPrice,
    this.rate,
    this.minuteRate,
    this.priseEnCharge,
  });
}

class _Amenity {
  final IconData icon;
  final String label;
  const _Amenity(this.icon, this.label);
}

/// Luxury loading indicator
class _LuxuryLoadingIndicator extends StatelessWidget {
  const _LuxuryLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.secondary, AppTheme.primary],
          ).createShader(bounds),
          child: const Text(
            'CHARGEMENT...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.5,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Optimized vehicle list with staggered animations
class _VehicleListView extends StatelessWidget {
  final List<_VehicleModel> vehicles;
  final String? selectedVehicleType;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;
  final ValueChanged<String> onVehicleSelected;
  final bool isFromDistance;

  const _VehicleListView({
    required this.vehicles,
    required this.selectedVehicleType,
    required this.fadeAnimations,
    required this.slideAnimations,
    required this.onVehicleSelected,
    required this.isFromDistance,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        final isSelected = selectedVehicleType == vehicle.type;

        return RepaintBoundary(
          child: FadeTransition(
            opacity: fadeAnimations[index],
            child: SlideTransition(
              position: slideAnimations[index],
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _LuxuryVehicleCard(
                  key: ValueKey(vehicle.vehicleKey),
                  vehicle: vehicle,
                  isSelected: isSelected,
                  isFromDistance: isFromDistance,
                  onTap: () => onVehicleSelected(vehicle.type),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Premium vehicle card with luxury animations
class _LuxuryVehicleCard extends StatefulWidget {
  final _VehicleModel vehicle;
  final bool isSelected;
  final bool isFromDistance;
  final VoidCallback onTap;

  const _LuxuryVehicleCard({
    super.key,
    required this.vehicle,
    required this.isSelected,
    required this.isFromDistance,
    required this.onTap,
  });

  @override
  State<_LuxuryVehicleCard> createState() => _LuxuryVehicleCardState();
}

class _LuxuryVehicleCardState extends State<_LuxuryVehicleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: widget.isSelected ? 1.02 : (_isPressed ? 0.98 : 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: widget.isSelected
                ? const LinearGradient(
                    colors: [
                      AppTheme.secondary,
                      AppTheme.primary,
                      AppTheme.accent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isSelected ? null : AppTheme.card,
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? AppTheme.primary.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.5),
                blurRadius: widget.isSelected ? 28 : 20,
                offset: Offset(0, widget.isSelected ? 12 : 8),
                spreadRadius: widget.isSelected ? 0 : -4,
              ),
            ],
          ),
          child: Container(
            margin:
                widget.isSelected ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
            decoration: BoxDecoration(
              color:
                  widget.isSelected ? AppTheme.background : Colors.transparent,
              borderRadius: BorderRadius.circular(21.5),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vehicle image with hero animation + popular badge overlay
                SizedBox(
                  height: 140,
                  child: Stack(
                    children: [
                      Center(
                        child: Hero(
                          tag: widget.vehicle.imagePath,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: Image.asset(
                              widget.vehicle.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.directions_car_rounded,
                                  size: 60,
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.3),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      if (widget.vehicle.isPopular && !widget.isSelected)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: _PopularBadge(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Selected badge
                if (widget.isSelected) const _SelectedBadge(),

                const SizedBox(height: 12),

                // Vehicle name
                Text(
                  widget.vehicle.type,
                  style: TextStyle(
                    color: widget.isSelected ? AppTheme.primary : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Vehicle description
                Text(
                  widget.vehicle.description,
                  style: TextStyle(
                    color: widget.isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Amenity chips
                if (widget.vehicle.amenities.isNotEmpty)
                  _AmenityRow(
                    amenities: widget.vehicle.amenities,
                    isSelected: widget.isSelected,
                  ),

                if (widget.vehicle.amenities.isNotEmpty)
                  const SizedBox(height: 16),

                // Capacity information
                _CapacityRow(
                  isSelected: widget.isSelected,
                  passengers: widget.vehicle.passengers,
                  bags: widget.vehicle.bags,
                ),

                const SizedBox(height: 16),

                // Price information
                _PriceInfoRow(
                  isSelected: widget.isSelected,
                  isFromDistance: widget.isFromDistance,
                  vehicle: widget.vehicle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LUXURY APP BAR (extracted widget)
// ─────────────────────────────────────────────────────────────

class _LuxuryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const _LuxuryAppBar({required this.title, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 18);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      toolbarHeight: kToolbarHeight + 18,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primary),
        onPressed: onBack,
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.subtleGoldGradient.createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tap a vehicle to reserve',
            style: TextStyle(
              color: AppTheme.offWhite.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.background,
              AppTheme.card.withValues(alpha: 0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  POPULAR BADGE
// ─────────────────────────────────────────────────────────────

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentGold, AppTheme.primaryGold],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              color: AppTheme.richBlack, size: 12),
          SizedBox(width: 4),
          Text(
            'POPULAR',
            style: TextStyle(
              color: AppTheme.richBlack,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AMENITY ROW
// ─────────────────────────────────────────────────────────────

class _AmenityRow extends StatelessWidget {
  final List<_Amenity> amenities;
  final bool isSelected;
  const _AmenityRow({required this.amenities, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: amenities
          .map((a) => _AmenityChip(amenity: a, isSelected: isSelected))
          .toList(growable: false),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final _Amenity amenity;
  final bool isSelected;
  const _AmenityChip({required this.amenity, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primary.withValues(alpha: 0.18)
            : AppTheme.muted.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(amenity.icon, size: 13, color: AppTheme.primaryGold),
          const SizedBox(width: 5),
          Text(
            amenity.label,
            style: TextStyle(
              color: AppTheme.softWhite.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SELECTED BADGE (extracted widget)
// ─────────────────────────────────────────────────────────────

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withValues(alpha: 0.2),
              AppTheme.primary.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 16),
            SizedBox(width: 6),
            Text(
              'SÉLECTIONNÉ',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CAPACITY ROW (extracted widget)
// ─────────────────────────────────────────────────────────────

class _CapacityRow extends StatelessWidget {
  final bool isSelected;
  final int passengers;
  final int bags;

  const _CapacityRow({
    required this.isSelected,
    required this.passengers,
    required this.bags,
  });

  @override
  Widget build(BuildContext context) {
    final strings = Strings.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CapacityItem(
          icon: Icons.person_outline_rounded,
          label: strings.vehiclePassengers,
          value: passengers.toString(),
          isSelected: isSelected,
        ),
        Container(
          width: 1.5,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                isSelected
                    ? AppTheme.primary.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
        _CapacityItem(
          icon: Icons.luggage_outlined,
          label: strings.vehicleBags,
          value: bags.toString(),
          isSelected: isSelected,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CAPACITY ITEM (extracted widget)
// ─────────────────────────────────────────────────────────────

class _CapacityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSelected;

  const _CapacityItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 28),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PRICE INFO ROW (extracted widget)
// ─────────────────────────────────────────────────────────────

class _PriceInfoRow extends StatelessWidget {
  final bool isSelected;
  final bool isFromDistance;
  final _VehicleModel vehicle;

  const _PriceInfoRow({
    required this.isSelected,
    required this.isFromDistance,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    final strings = Strings.of(context);
    final priceText = isFromDistance && vehicle.price != null
        ? '${vehicle.price!.toStringAsFixed(2)} €'
        : vehicle.fixedPrice ?? 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [
                  AppTheme.primary.withValues(alpha: 0.15),
                  AppTheme.primary.withValues(alpha: 0.1),
                ]
              : [
                  AppTheme.primary.withValues(alpha: 0.1),
                  AppTheme.secondary.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isFromDistance ? strings.vehiclePrice : strings.vehicleFixedPrice,
            style: TextStyle(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            priceText,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium continue button with smooth animations
class _ContinueButton extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onPressed;

  const _ContinueButton({
    required this.isVisible,
    required this.onPressed,
  });

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: widget.isVisible ? Offset.zero : const Offset(0, 1.5),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        opacity: widget.isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              widget.onPressed();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.diagonal3Values(
                  _isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.secondary,
                      AppTheme.primary,
                      AppTheme.accent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isPressed
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        Strings.of(context).continueButton.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.black87,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
