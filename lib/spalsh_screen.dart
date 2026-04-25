import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cabsudapp/onboarding_screen.dart';
import 'package:cabsudapp/reuse/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  // All driven by a single controller with Interval curves
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _brandOpacity;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _brandOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );
    _brandSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 600), _navigateToNext);
    });
  }

  void _navigateToNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const OnboardingScreen(),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Static ambient glow — no animation, no per-frame rebuild
          const _StaticGlow(),

          // All animated content driven by one controller
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => _SplashContent(
              logoScale: _logoScale.value,
              logoOpacity: _logoOpacity.value,
              brandOpacity: _brandOpacity.value,
              brandSlide: _brandSlide.value,
              taglineOpacity: _taglineOpacity.value,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Static glow — rendered once, zero per-frame cost ──────────────────────

class _StaticGlow extends StatelessWidget {
  const _StaticGlow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 320,
        height: 320,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.primaryGold.withValues(alpha: 0.07),
                AppTheme.primaryGold.withValues(alpha: 0.03),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Content widget — rebuilt by AnimatedBuilder ───────────────────────────

class _SplashContent extends StatelessWidget {
  final double logoScale;
  final double logoOpacity;
  final double brandOpacity;
  final Offset brandSlide;
  final double taglineOpacity;

  const _SplashContent({
    required this.logoScale,
    required this.logoOpacity,
    required this.brandOpacity,
    required this.brandSlide,
    required this.taglineOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        Transform.scale(
          scale: logoScale,
          child: Opacity(
            opacity: logoOpacity,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryGold.withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo/splach-logo.png',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.directions_car_rounded,
                    size: 48,
                    color: AppTheme.primaryGold,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 36),

        // Brand name
        FractionalTranslation(
          translation: brandSlide,
          child: Opacity(
            opacity: brandOpacity,
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.subtleGoldGradient.createShader(bounds),
              child: const Text(
                'CABSUD',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Tagline
        Opacity(
          opacity: taglineOpacity,
          child: Text(
            'CHAUFFEUR PRIVÉ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 4.5,
              color: AppTheme.foreground.withValues(alpha: 0.45),
            ),
          ),
        ),

        const SizedBox(height: 60),

        // Spinner — isolated in its own repaint boundary
        Opacity(
          opacity: taglineOpacity,
          child: const RepaintBoundary(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryGold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
