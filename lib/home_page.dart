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
//  ROOT
// ─────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isLanguageLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLanguage();
      _precacheImages();
    });
  }

  Future<void> _initializeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'fr';
    if (!prefs.containsKey('language')) await prefs.setString('language', lang);
    Strings.load(lang);
    if (mounted) setState(() => _isLanguageLoaded = true);
  }

  void _precacheImages() {
    for (final path in [
      'assets/intro/hero-car.jpg',
      'assets/intro/disposition-luxury.jpg',
      'assets/intro/tourism-luxury.jpg',
      'assets/intro/Atob.jpg',
    ]) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isLanguageLoaded
            ? IndexedStack(
                key: const ValueKey('content'),
                index: _currentIndex,
                children: const [
                  _HomeContent(),
                  ContactPage(),
                  SettingsPage(),
                ],
              )
            : const _LoadingScreen(key: ValueKey('loading')),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: _FloatingNavBar(
          currentIndex: _currentIndex,
          onIndexChanged: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LOADING
// ─────────────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.luxuryBackgroundGradient,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation(
                    AppTheme.primaryGold.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            ShaderMask(
              shaderCallback: (b) =>
                  AppTheme.subtleGoldGradient.createShader(b),
              child: const Text(
                'CABSUD',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 7,
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
//  FLOATING NAV BAR
// ─────────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final strings = Strings.of(context);

    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 14 + bottom),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F18),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 32,
            offset: const Offset(0, 12),
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
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.subtleGoldGradient : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGold.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppTheme.richBlack
                  : AppTheme.offWhite.withValues(alpha: 0.35),
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.richBlack,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.2,
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
//  HOME CONTENT
// ─────────────────────────────────────────────────────────────

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  void _go(Widget page) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 460),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final strings = Strings.of(context);
    return Stack(
      children: [
        // Static background gold bloom — top-right warmth
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryGold.withValues(alpha: 0.055),
                  AppTheme.primaryGold.withValues(alpha: 0.015),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildHero(strings)),
                  const SliverToBoxAdapter(child: _SectionDivider()),
                  SliverToBoxAdapter(child: _buildGrid(strings)),
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Header ──────────────────────────────────────────────────

  Widget _buildHeader() {
    final h = DateTime.now().hour;
    final greeting =
        h < 12 ? 'Bonjour' : h < 18 ? 'Bon après-midi' : 'Bonsoir';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.offWhite.withValues(alpha: 0.38),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (b) =>
                      AppTheme.primaryGoldGradient.createShader(b),
                  child: const Text(
                    'CABSUD',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppTheme.subtleGoldGradient.createShader(b),
                      child: Container(
                        width: 24,
                        height: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CHAUFFEUR PRIVÉ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGold.withValues(alpha: 0.55),
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bell — gold gradient fill for premium look
          Container(
            margin: const EdgeInsets.only(left: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.subtleGoldGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGold.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: AppTheme.richBlack,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero card ────────────────────────────────────────────────

  Widget _buildHero(Strings strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: _Tappable(
        onTap: () => _go(const QuickServicePage()),
        radius: 24,
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withValues(alpha: 0.22),
                blurRadius: 32,
                offset: const Offset(0, 14),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.asset(
                  'assets/intro/hero-car.jpg',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
                // Dark veil
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.12),
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                // Gold ambient glow — top-right
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        colors: [
                          AppTheme.primaryGold.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Gold top border stripe
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGoldGradient,
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryGold.withValues(alpha: 0.28),
                              AppTheme.primaryGold.withValues(alpha: 0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryGold.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flash_on_rounded,
                              color: AppTheme.primaryGold,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'EXPRESS',
                              style: TextStyle(
                                color: AppTheme.primaryGold,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Title
                      Text(
                        strings.quickServiceTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Réservez votre chauffeur en quelques secondes',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 18),
                      // CTA
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGoldGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryGold.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'RÉSERVER MAINTENANT',
                              style: TextStyle(
                                color: AppTheme.richBlack,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.8,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: AppTheme.richBlack,
                              size: 14,
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

  // ─── Service grid ─────────────────────────────────────────────

  Widget _buildGrid(Strings strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CinematicTile(
                    imagePath: 'assets/intro/disposition-luxury.jpg',
                    icon: Icons.directions_car_rounded,
                    badge: 'PREMIUM',
                    title: strings.faireUneCommande1,
                    subtitle: 'Transport sur mesure',
                    onTap: () => _go(const ServiceSelectionPage()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CinematicTile(
                    imagePath: 'assets/intro/tourism-luxury.jpg',
                    icon: Icons.calendar_today_rounded,
                    badge: 'DÉDIÉ',
                    title: strings.miseADisposition1,
                    subtitle: 'Véhicule à disposition',
                    onTap: () => _go(const RoutePage()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _WideServiceTile(
            icon: Icons.star_rounded,
            title: strings.nosServices1,
            subtitle: 'Toutes nos prestations premium',
            onTap: () => _go(const ServicesPage()),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION DIVIDER
// ─────────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) =>
                AppTheme.subtleGoldGradient.createShader(b),
            child: Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'NOS SERVICES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.offWhite.withValues(alpha: 0.55),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGold.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CINEMATIC TILE (compact, 2-column, image background)
// ─────────────────────────────────────────────────────────────

class _CinematicTile extends StatefulWidget {
  final String imagePath;
  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CinematicTile({
    required this.imagePath,
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_CinematicTile> createState() => _CinematicTileState();
}

class _CinematicTileState extends State<_CinematicTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          constraints: const BoxConstraints(minHeight: 162),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.asset(
                  widget.imagePath,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppTheme.card),
                ),
                // Dark gradient
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
                // Gold top stripe
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.subtleGoldGradient,
                    ),
                  ),
                ),
                // Content
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon + badge row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                gradient: AppTheme.subtleGoldGradient,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                widget.icon,
                                color: AppTheme.richBlack,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGold
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.primaryGold
                                      .withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.badge,
                                style: TextStyle(
                                  color: AppTheme.primaryGold,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.subtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (b) =>
                                  AppTheme.subtleGoldGradient.createShader(b),
                              child: const Icon(
                                Icons.arrow_outward_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
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
  }
}

// ─────────────────────────────────────────────────────────────
//  WIDE SERVICE TILE (full-width, horizontal)
// ─────────────────────────────────────────────────────────────

class _WideServiceTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WideServiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_WideServiceTile> createState() => _WideServiceTileState();
}

class _WideServiceTileState extends State<_WideServiceTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGold.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Gold left accent bar
              Container(
                width: 4,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppTheme.subtleGoldGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Icon with gold gradient
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.subtleGoldGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppTheme.richBlack,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppTheme.softWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: AppTheme.offWhite.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow with gold gradient
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.subtleGoldGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.richBlack,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TAPPABLE WRAPPER
// ─────────────────────────────────────────────────────────────

class _Tappable extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double radius;

  const _Tappable({
    required this.onTap,
    required this.child,
    this.radius = 18,
  });

  @override
  State<_Tappable> createState() => _TappableState();
}

class _TappableState extends State<_Tappable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
