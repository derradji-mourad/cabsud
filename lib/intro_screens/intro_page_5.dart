import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/string.dart';
import 'package:cabsudapp/reuse/theme.dart';

class IntroPage5 extends StatefulWidget {
  const IntroPage5({super.key});

  @override
  State<IntroPage5> createState() => _IntroPage5State();
}

class _IntroPage5State extends State<IntroPage5>
    with SingleTickerProviderStateMixin {
  bool _isLanguageLoaded = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadLanguage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadLanguage() async {
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

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: _LuxuryLoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _CinematicIntroLayout(
          imagePath: 'assets/intro/tourisem_transport.jpg',
          badge: 'TOURISME',
          title: Strings.of(context).introTitle5,
          description: Strings.of(context).introDescription5,
        ),
      ),
    );
  }
}

class _CinematicIntroLayout extends StatelessWidget {
  final String imagePath;
  final String badge;
  final String title;
  final String description;

  const _CinematicIntroLayout({
    required this.imagePath,
    required this.badge,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.card,
            child: const Center(
              child: Icon(Icons.map_rounded, size: 80, color: AppTheme.primaryGold),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          height: screenH * 0.65,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.background.withValues(alpha: 0.72),
                  AppTheme.background.withValues(alpha: 0.94),
                  AppTheme.background,
                ],
                stops: const [0.0, 0.3, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0, height: 110,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
              child: ShaderMask(
                shaderCallback: (b) =>
                    AppTheme.subtleGoldGradient.createShader(b),
                child: const Text(
                  'CABSUD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 160,
          left: 28,
          right: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenW * 0.072,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 15,
                  height: 1.65,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LuxuryLoadingIndicator extends StatelessWidget {
  const _LuxuryLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryGold.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'CHARGEMENT...',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: AppTheme.primaryGold.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
