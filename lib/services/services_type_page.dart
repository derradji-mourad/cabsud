import 'package:cabsudapp/services/route_page.dart';
import 'package:cabsudapp/services/distance_page.dart';
import 'package:cabsudapp/reuse/theme.dart';
import 'package:cabsudapp/localization/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

/// Sleek horizontal carousel design inspired by premium apps [web:142][web:144]
class ServiceSelectionPage extends StatefulWidget {
  const ServiceSelectionPage({super.key});

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  bool _isLanguageLoaded = false;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (_currentPageNotifier.value != page) {
        _currentPageNotifier.value = page;
      }
    });

    _loadLanguagePreferences();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadLanguagePreferences() async {
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

  void _navigateToService(int index) {
    final destinations = [
      const DistanceCalculator(),
      const DistanceCalculator(),
      const DistanceCalculator(),
      const RoutePage(),
      const RoutePage(),
    ];

    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destinations[index],
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.luxuryBackgroundGradient,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: AppTheme.luxuryBackgroundGradient,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeController,
            child: Column(
              children: [
                _buildAppBar(),
                const SizedBox(height: 20),
                _buildTitle(),
                const SizedBox(height: 32),
                Expanded(child: _buildCarousel()),
                _buildPageIndicator(),
                const SizedBox(height: 20),
                _buildSelectButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.charcoal.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primaryGold.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: AppTheme.primaryGold,
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),
          const Spacer(),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.lightGold, AppTheme.primaryGold],
            ).createShader(bounds),
            child: const Icon(
              Icons.directions_car_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.lightGold, AppTheme.primaryGold],
            ).createShader(bounds),
            child: Text(
              Strings.of(context).selectService,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Swipe to explore premium services',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.offWhite.withOpacity(0.6),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    final services = _getServices();

    return PageView.builder(
      controller: _pageController,
      itemCount: services.length,
      onPageChanged: (index) => HapticFeedback.selectionClick(),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double value = 1.0;
            if (_pageController.position.haveDimensions) {
              value = (_pageController.page ?? 0) - index;
              value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
            }

            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _HeroServiceCard(
            service: services[index],
            onTap: () => _navigateToService(index),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    return ValueListenableBuilder<int>(
      valueListenable: _currentPageNotifier,
      builder: (context, currentPage, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final isActive = currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: isActive ? 32 : 8,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                  colors: [AppTheme.primaryGold, AppTheme.accentGold],
                )
                    : null,
                color: isActive ? null : AppTheme.offWhite.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSelectButton() {
    return ValueListenableBuilder<int>(
      valueListenable: _currentPageNotifier,
      builder: (context, currentPage, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _ElegantButton(
            text: 'SELECT SERVICE',
            onPressed: () => _navigateToService(currentPage),
          ),
        );
      },
    );
  }

  List<_ServiceData> _getServices() {
    return [
      _ServiceData(
        title: Strings.of(context).airportTransport,
        subtitle: 'Professional Airport Transfer',
        imagePath: 'assets/intro/airport_transportation.jpg',
        icon: Icons.flight_takeoff_rounded,
        color: const Color(0xFF4A90E2),
      ),
      _ServiceData(
        title: Strings.of(context).cruiseTransport,
        subtitle: 'Luxury Cruise Port Service',
        imagePath: 'assets/intro/cruise_transport.jpg',
        icon: Icons.directions_boat_filled_rounded,
        color: const Color(0xFF5856D6),
      ),
      _ServiceData(
        title: Strings.of(context).trainStationTransport,
        subtitle: 'Reliable Train Station Pickup',
        imagePath: 'assets/intro/gare_transport.jpg',
        icon: Icons.train_rounded,
        color: const Color(0xFFFF9500),
      ),
      _ServiceData(
        title: Strings.of(context).carAtDisposal,
        subtitle: 'Premium Vehicle Disposal',
        imagePath: 'assets/intro/mise_a_disposition.jpg',
        icon: Icons.directions_car_filled_rounded,
        color: const Color(0xFFFF2D55),
      ),
      _ServiceData(
        title: Strings.of(context).tourism,
        subtitle: 'Exclusive Tourism Experience',
        imagePath: 'assets/intro/tourisem_transport.jpg',
        icon: Icons.tour_rounded,
        color: const Color(0xFF34C759),
      ),
    ];
  }
}

class _ServiceData {
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData icon;
  final Color color;

  _ServiceData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.color,
  });
}

/// Hero-style card with depth [web:144]
class _HeroServiceCard extends StatefulWidget {
  final _ServiceData service;
  final VoidCallback onTap;

  const _HeroServiceCard({
    required this.service,
    required this.onTap,
  });

  @override
  State<_HeroServiceCard> createState() => _HeroServiceCardState();
}

class _HeroServiceCardState extends State<_HeroServiceCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.service.color.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 50,
                offset: const Offset(0, 30),
                spreadRadius: -10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.asset(
                  widget.service.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppTheme.deepCharcoal,
                    child: Icon(
                      widget.service.icon,
                      size: 100,
                      color: widget.service.color.withOpacity(0.3),
                    ),
                  ),
                ),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Floating icon badge
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.service.color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: widget.service.color.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.service.icon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Subtitle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.service.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.service.color.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.service.subtitle.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: widget.service.color,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Title
                      Text(
                        widget.service.title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 20),

                      // Tap hint
                      Row(
                        children: [
                          Text(
                            'TAP TO SELECT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Elegant button with glassmorphism [web:132]
class _ElegantButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const _ElegantButton({
    required this.text,
    required this.onPressed,
  });

  @override
  State<_ElegantButton> createState() => _ElegantButtonState();
}

class _ElegantButtonState extends State<_ElegantButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGold, AppTheme.accentGold],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.richBlack,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.richBlack,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
