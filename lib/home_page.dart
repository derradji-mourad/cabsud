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
import 'package:cabsudapp/services/quick_service_page.dart';

// ─────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────

class ServiceData {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final IconData icon;
  final Color color;
  final Widget destination;

  const ServiceData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.icon,
    required this.color,
    required this.destination,
  });
}

// ─────────────────────────────────────────────────────────────
//  HOME PAGE (root)
// ─────────────────────────────────────────────────────────────

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
      _pulseController.stop();
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
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: AppTheme.luxuryBackgroundGradient,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeOut,
          child: _isLanguageLoaded
              ? IndexedStack(
                  key: const ValueKey('content'),
                  index: _currentIndex,
                  children: const [
                    ModernCarouselHome(),
                    ContactPage(),
                    SettingsPage(),
                  ],
                )
              : _LoadingScreen(
                  key: const ValueKey('loading'),
                  pulseController: _pulseController,
                ),
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: _MinimalNavBar(
          currentIndex: _currentIndex,
          onIndexChanged: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LOADING SCREEN (extracted widget)
// ─────────────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  final AnimationController pulseController;

  const _LoadingScreen({super.key, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.95 + (pulseController.value * 0.05),
            child: child,
          );
        },
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
                    AppTheme.primaryGold.withValues(alpha: 0.4),
                    AppTheme.primaryGold.withValues(alpha: 0.1),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MINIMAL NAV BAR (extracted widget)
// ─────────────────────────────────────────────────────────────

class _MinimalNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _MinimalNavBar({
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final strings = Strings.of(context);

    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppTheme.richBlack.withValues(alpha: 0.8),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: strings.accueil,
            isActive: currentIndex == 0,
            onTap: () => onIndexChanged(0),
          ),
          _NavItem(
            icon: Icons.phone_rounded,
            label: strings.contact1,
            isActive: currentIndex == 1,
            onTap: () => onIndexChanged(1),
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            label: strings.parametres,
            isActive: currentIndex == 2,
            onTap: () => onIndexChanged(2),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NAV ITEM (extracted widget)
// ─────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.primaryGoldGradient : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.richBlack : AppTheme.offWhite,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.richBlack,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MODERN CAROUSEL HOME
// ─────────────────────────────────────────────────────────────

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
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      final newIndex = page.round();
      if (newIndex != _currentPage) {
        setState(() => _currentPage = newIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<ServiceData> _buildServices(Strings strings) {
    return [
      ServiceData(
        title: strings.quickServiceTitle,
        subtitle: strings.quickServiceSubtitle,
        description: 'Book a ride in seconds',
        imagePath: 'assets/intro/mise_a_disposition.jpg',
        icon: Icons.flash_on_rounded,
        color: AppTheme.luxuryGold,
        destination: const QuickServicePage(),
      ),
      ServiceData(
        title: strings.faireUneCommande1,
        subtitle: 'Book Your Ride',
        description: 'Premium transport at your fingertips',
        imagePath: 'assets/intro/mise_a_disposition.jpg',
        icon: Icons.directions_car_rounded,
        color: AppTheme.primaryGold,
        destination: const ServiceSelectionPage(),
      ),
      ServiceData(
        title: strings.miseADisposition1,
        subtitle: 'Car Disposal',
        description: 'Luxury vehicle at your disposal',
        imagePath: 'assets/intro/tourisem_transport.jpg',
        icon: Icons.calendar_today_rounded,
        color: AppTheme.accentGold,
        destination: const RoutePage(),
      ),
      ServiceData(
        title: strings.nosServices1,
        subtitle: 'All Services',
        description: 'Explore our premium offerings',
        imagePath: 'assets/intro/Atob.jpg',
        icon: Icons.star_rounded,
        color: AppTheme.darkGold,
        destination: const ServicesPage(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final services = _buildServices(Strings.of(context));

    return SafeArea(
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _fadeController,
          curve: Curves.easeOut,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final cardHeightFactor = availableHeight > 600 ? 0.60 : 0.55;

            return Column(
              children: [
                const _ModernHeader(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: services.length,
                    onPageChanged: (_) => HapticFeedback.selectionClick(),
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = (_pageController.page ?? 0) - index;
                            value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                            value =
                                Curves.easeOut.transform(value).clamp(0.75, 1.0);
                          }
                          return Center(
                            child: SizedBox(
                              height: availableHeight * cardHeightFactor * value,
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
                _PageIndicator(
                  length: services.length,
                  currentPage: _currentPage,
                ),
                const SizedBox(height: 70),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MODERN HEADER (extracted widget)
// ─────────────────────────────────────────────────────────────

class _ModernHeader extends StatelessWidget {
  const _ModernHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGoldGradient.createShader(bounds),
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
                  color: AppTheme.offWhite.withValues(alpha: 0.6),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGoldGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGold.withValues(alpha: 0.4),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PAGE INDICATOR (extracted widget)
// ─────────────────────────────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  final int length;
  final int currentPage;

  const _PageIndicator({
    required this.length,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            gradient:
                currentPage == index ? AppTheme.primaryGoldGradient : null,
            color: currentPage == index
                ? null
                : AppTheme.offWhite.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CAROUSEL 3D CARD (already a separate widget, kept as-is)
// ─────────────────────────────────────────────────────────────

class Carousel3DCard extends StatefulWidget {
  final ServiceData service;
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
      duration: const Duration(milliseconds: 2500),
    );
    if (widget.isActive) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Carousel3DCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _shimmerController.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _shimmerController.stop();
      _shimmerController.reset();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _navigateToService() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.service.destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
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
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _navigateToService,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        curve: Curves.easeOutCubic,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.service.color.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 20),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
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
              clipBehavior: Clip.hardEdge,
              children: [
                // Background image
                Image.asset(
                  widget.service.imagePath,
                  fit: BoxFit.cover,
                ),

                // Dark overlay
                const _CardDarkOverlay(),

                // Animated shimmer (only if active)
                if (widget.isActive)
                  _CardShimmer(controller: _shimmerController),

                // Content
                _CardContent(
                  service: widget.service,
                  isActive: widget.isActive,
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
//  CARD DARK OVERLAY (extracted widget)
// ─────────────────────────────────────────────────────────────

class _CardDarkOverlay extends StatelessWidget {
  const _CardDarkOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CARD SHIMMER (extracted widget)
// ─────────────────────────────────────────────────────────────

class _CardShimmer extends StatelessWidget {
  final AnimationController controller;

  const _CardShimmer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(-300 + (controller.value * 900), 0),
          child: Transform.rotate(
            angle: 0.4,
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CARD CONTENT (extracted widget)
// ─────────────────────────────────────────────────────────────

class _CardContent extends StatelessWidget {
  final ServiceData service;
  final bool isActive;

  const _CardContent({
    required this.service,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, cardConstraints) {
          final cardH = cardConstraints.maxHeight;
          final showIcon = cardH > 280;
          final showDescription = cardH > 240;

          return Padding(
            padding: EdgeInsets.all(cardH > 300 ? 24 : 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),

                if (showIcon) ...[
                  _CardIconBadge(color: service.color, icon: service.icon),
                  const SizedBox(height: 12),
                ],

                // Subtitle
                Text(
                  service.subtitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: service.color,
                    letterSpacing: 2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Title
                Text(
                  service.title,
                  style: TextStyle(
                    fontSize: cardH > 350 ? 24 : 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (showDescription) ...[
                  const SizedBox(height: 6),
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.offWhite.withValues(alpha: 0.8),
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                if (isActive)
                  _BookNowButton(color: service.color),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CARD ICON BADGE (extracted widget)
// ─────────────────────────────────────────────────────────────

class _CardIconBadge extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _CardIconBadge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: AppTheme.richBlack, size: 24),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOOK NOW BUTTON (extracted widget)
// ─────────────────────────────────────────────────────────────

class _BookNowButton extends StatelessWidget {
  final Color color;

  const _BookNowButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(width: 6),
          Icon(
            Icons.arrow_forward_rounded,
            color: AppTheme.richBlack,
            size: 16,
          ),
        ],
      ),
    );
  }
}
