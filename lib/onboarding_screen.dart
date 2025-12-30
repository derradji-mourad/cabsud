import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cabsudapp/authentification/sing_up.dart';
import 'package:cabsudapp/intro_screens/intro_page_1.dart';
import 'package:cabsudapp/intro_screens/intro_page_2.dart';
import 'package:cabsudapp/intro_screens/intro_page_3.dart';
import 'package:cabsudapp/intro_screens/intro_page_4.dart';
import 'package:cabsudapp/intro_screens/intro_page_5.dart';
import 'package:cabsudapp/intro_screens/intro_page_6.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cabsudapp/localization/string.dart';

/// Luxury color palette
class _LuxuryColors {
  static const goldLight = Color(0xFFF7EF8A);
  static const goldMedium = Color(0xFFD4AF37);
  static const goldDark = Color(0xFFAE8625);
  static const goldAccent = Color(0xFFEDC967);
  static const backgroundDark = Color(0xFF0A0A0A);
  static const backgroundMedium = Color(0xFF121212);
}

/// Premium onboarding screen with luxury animations and micro-interactions.
///
/// Features:
/// - Smooth page transitions with custom physics
/// - Animated controls with fade effects
/// - Luxury-styled page indicators
/// - Haptic feedback on interactions
/// - Optimized performance with proper disposal
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _controlsAnimationController;
  late final Animation<double> _controlsFadeAnimation;

  int _currentPageIndex = 0;
  bool _isOnLastPage = false;

  static const int _totalPages = 6;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controlsAnimationController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _pageController = PageController();
    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _initializeAnimations() {
    _controlsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Start controls animation after a brief delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _controlsAnimationController.forward();
      }
    });
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      _currentPageIndex = pageIndex;
      _isOnLastPage = (pageIndex == _totalPages - 1);
    });

    // Subtle haptic feedback on page change
    HapticFeedback.selectionClick();
  }

  void _navigateToNextPage() {
    HapticFeedback.lightImpact();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _skipToLastPage() {
    HapticFeedback.mediumImpact();
    _pageController.animateToPage(
      _totalPages - 1,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  void _navigateToSignUp() {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          final tween = Tween(begin: begin, end: end);
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return FadeTransition(
            opacity: tween.animate(curvedAnimation),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LuxuryColors.backgroundDark,
      body: Stack(
        children: [
          // Page view with custom physics
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: const [
              IntroPage1(),
              IntroPage2(),
              IntroPage3(),
              IntroPage4(),
              IntroPage5(),
              IntroPage6(),
            ],
          ),

          // Animated bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _controlsFadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                _LuxuryColors.backgroundDark.withOpacity(0.7),
                _LuxuryColors.backgroundDark,
              ],
            ),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 32,
            top: 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPageIndicator(),
              const SizedBox(height: 32),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return RepaintBoundary(
      child: SmoothPageIndicator(
        controller: _pageController,
        count: _totalPages,
        effect: ExpandingDotsEffect(
          activeDotColor: _LuxuryColors.goldLight,
          dotColor: _LuxuryColors.goldMedium.withOpacity(0.3),
          dotHeight: 10,
          dotWidth: 10,
          expansionFactor: 4,
          spacing: 8,
          paintStyle: PaintingStyle.fill,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        // Skip button - only shows when not on last page
        if (!_isOnLastPage)
          Flexible(
            child: _LuxuryTextButton(
              label: Strings.of(context).skipButton,
              onPressed: _skipToLastPage,
            ),
          ),

        // Spacer to push buttons apart when both are visible
        if (!_isOnLastPage) const SizedBox(width: 16),

        // Action button - expands to fill space on last page
        Expanded(
          child: _LuxuryPrimaryButton(
            label: _isOnLastPage
                ? Strings.of(context).getStartedButton
                : Strings.of(context).nextButton,
            onPressed: _isOnLastPage ? _navigateToSignUp : _navigateToNextPage,
            isExpanded: _isOnLastPage,
          ),
        ),
      ],
    );
  }
}

/// Luxury text button for secondary actions
class _LuxuryTextButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;

  const _LuxuryTextButton({
    required this.label,
    this.onPressed,
  });

  @override
  State<_LuxuryTextButton> createState() => _LuxuryTextButtonState();
}

class _LuxuryTextButtonState extends State<_LuxuryTextButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      } : null,
      onTapUp: widget.onPressed != null ? (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      } : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isPressed
              ? _LuxuryColors.goldMedium.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isPressed
                ? _LuxuryColors.goldMedium.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: _isPressed
                ? _LuxuryColors.goldLight
                : Colors.white.withOpacity(0.7),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Premium primary button with gradient and animations
class _LuxuryPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isExpanded;

  const _LuxuryPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isExpanded = false,
  });

  @override
  State<_LuxuryPrimaryButton> createState() => _LuxuryPrimaryButtonState();
}

class _LuxuryPrimaryButtonState extends State<_LuxuryPrimaryButton> {
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
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                _LuxuryColors.goldDark,
                _LuxuryColors.goldLight,
                _LuxuryColors.goldAccent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isPressed
                ? [
              BoxShadow(
                color: _LuxuryColors.goldMedium.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ]
                : [
              BoxShadow(
                color: _LuxuryColors.goldMedium.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black87,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
