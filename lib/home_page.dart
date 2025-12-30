import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cabsudapp/reuse/theme.dart';
import 'package:cabsudapp/parametre.dart';
import 'package:cabsudapp/services/contact_page.dart';
import 'package:cabsudapp/services/services_page.dart';
import 'package:cabsudapp/services/route_page.dart';
import 'package:cabsudapp/localization/string.dart';
import 'package:cabsudapp/services/services_type_page.dart';
import 'custom_page_route.dart';

/// Modern carousel-based home page with 3D card effects [web:136][web:139]
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isLanguageLoaded = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLanguage();
      _precacheImages();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
    }
  }

  void _precacheImages() {
    for (final asset in [
      'assets/intro/mise_a_disposition.jpg',
      'assets/intro/tourisem_transport.jpg',
      'assets/intro/Atob.jpg',
    ]) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.luxuryBackgroundGradient,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.95 + (_pulseController.value * 0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primaryGold.withOpacity(0.4),
                              AppTheme.primaryGold.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          size: 50,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppTheme.lightGold, AppTheme.primaryGold],
                        ).createShader(bounds),
                        child: const Text(
                          'CABSUD',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: Colors.white,
                          ),
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
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            ModernCarouselHome(),
            ContactPage(),
            SettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildMinimalNavBar(),
    );
  }

  Widget _buildMinimalNavBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.charcoal,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.primaryGold.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, 0, Strings.of(context).accueil),
          _buildNavItem(Icons.phone_rounded, 1, Strings.of(context).contact1),
          _buildNavItem(Icons.settings_rounded, 2, Strings.of(context).parametres),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
            colors: [AppTheme.primaryGold, AppTheme.accentGold],
          )
              : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.richBlack : AppTheme.offWhite,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.richBlack,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Modern carousel home with 3D card effects [web:136][web:139]
class ModernCarouselHome extends StatefulWidget {
  const ModernCarouselHome({super.key});

  @override
  State<ModernCarouselHome> createState() => _ModernCarouselHomeState();
}

class _ModernCarouselHomeState extends State<ModernCarouselHome>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      setState(() => _currentPage = page.round());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = Strings.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    final services = [
      _ServiceData(
        title: strings.faireUneCommande1,
        subtitle: 'Book Your Ride',
        description: 'Premium transport at your fingertips',
        imagePath: 'assets/intro/mise_a_disposition.jpg',
        icon: Icons.directions_car_rounded,
        color: AppTheme.primaryGold,
        destination: const ServiceSelectionPage(),
      ),
      _ServiceData(
        title: strings.miseADisposition1,
        subtitle: 'Car Disposal',
        description: 'Luxury vehicle at your disposal',
        imagePath: 'assets/intro/tourisem_transport.jpg',
        icon: Icons.calendar_today_rounded,
        color: AppTheme.accentGold,
        destination: const RoutePage(),
      ),
      _ServiceData(
        title: strings.nosServices1,
        subtitle: 'All Services',
        description: 'Explore our premium offerings',
        imagePath: 'assets/intro/Atob.jpg',
        icon: Icons.star_rounded,
        color: AppTheme.darkGold,
        destination: const ServicesPage(),
      ),
    ];

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeController,
        child: Column(
          children: [
            // Header
            _buildModernHeader(),

            // Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: services.length,
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                },
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = (_pageController.page ?? 0) - index;
                        value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                      }

                      return Center(
                        child: SizedBox(
                          height: screenHeight * 0.65 * value,
                          child: child,
                        ),
                      );
                    },
                    child: Carousel3DCard(
                      service: services[index],
                      isActive: _currentPage == index,
                    ),
                  );
                },
              ),
            ),

            // Page indicator
            _buildPageIndicator(services.length),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppTheme.lightGold, AppTheme.primaryGold],
                    ).createShader(bounds),
                    child: const Text(
                      'CABSUD',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose Your Journey',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.offWhite.withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGold, AppTheme.accentGold],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: AppTheme.richBlack,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            gradient: _currentPage == index
                ? const LinearGradient(
              colors: [AppTheme.primaryGold, AppTheme.accentGold],
            )
                : null,
            color: _currentPage == index
                ? null
                : AppTheme.offWhite.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _ServiceData {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final IconData icon;
  final Color color;
  final Widget destination;

  _ServiceData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.icon,
    required this.color,
    required this.destination,
  });
}

/// 3D carousel card with depth effect [web:136][web:139]
class Carousel3DCard extends StatefulWidget {
  final _ServiceData service;
  final bool isActive;

  const Carousel3DCard({
    super.key,
    required this.service,
    required this.isActive,
  });

  @override
  State<Carousel3DCard> createState() => _Carousel3DCardState();
}

class _Carousel3DCardState extends State<Carousel3DCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            widget.service.destination,
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
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.service.color.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 20),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 40,
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
                ),

                // Dark overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Animated shimmer
                if (widget.isActive)
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-1.0 + _shimmerController.value * 3, -1.0),
                            end: Alignment(1.0 + _shimmerController.value * 3, 1.0),
                            colors: [
                              Colors.transparent,
                              widget.service.color.withOpacity(0.15),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      );
                    },
                  ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.service.color,
                              widget.service.color.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: widget.service.color.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.service.icon,
                          color: AppTheme.richBlack,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Subtitle
                      Text(
                        widget.service.subtitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.service.color,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Title
                      Text(
                        widget.service.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Description
                      Text(
                        widget.service.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.offWhite.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // CTA Button
                      if (widget.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.service.color,
                                widget.service.color.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: widget.service.color.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'BOOK NOW',
                                style: TextStyle(
                                  color: AppTheme.richBlack,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: AppTheme.richBlack,
                                size: 20,
                              ),
                            ],
                          ),
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
