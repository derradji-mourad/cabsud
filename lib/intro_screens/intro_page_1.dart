import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/string.dart';
import 'package:cabsudapp/reuse/theme.dart';

class IntroPage1 extends StatefulWidget {
  const IntroPage1({super.key});

  @override
  State<IntroPage1> createState() => _IntroPage1State();
}

class _IntroPage1State extends State<IntroPage1>
    with SingleTickerProviderStateMixin {
  bool _isLanguageLoaded = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLanguage();
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

  Future<void> _initializeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedLanguage = prefs.getString('language') ?? 'fr';

    if (!prefs.containsKey('language')) {
      await prefs.setString('language', selectedLanguage);
    }

    Strings.load(selectedLanguage);

    if (mounted) {
      setState(() => _isLanguageLoaded = true);
      _fadeController.forward();

      if (selectedLanguage == 'fr') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showLanguageDialog();
        });
      }
    }
  }

  Future<void> _showLanguageDialog() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Language Selection',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: _LanguageDialog(
              onLanguageSelected: (languageCode) async {
                HapticFeedback.mediumImpact();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('language', languageCode);
                Strings.load(languageCode);
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ),
        );
      },
    );
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
          imagePath: 'assets/intro/luxury-driver.jpeg',
          badge: 'PREMIUM SERVICE',
          title: Strings.of(context).appTitle,
          description: Strings.of(context).descriptionText,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CINEMATIC FULL-SCREEN LAYOUT (shared by all intro pages)
// ─────────────────────────────────────────────────────────────────────────────

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
        // ── Background image ──────────────────────────────────────────────────
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.card,
            child: const Center(
              child: Icon(Icons.directions_car_rounded,
                  size: 80, color: AppTheme.primaryGold),
            ),
          ),
        ),

        // ── Bottom gradient overlay ───────────────────────────────────────────
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

        // ── Top gradient (status bar legibility) ─────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          height: 110,
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

        // ── Top brand bar ─────────────────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
              child: Row(
                children: [
                  ShaderMask(
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
                ],
              ),
            ),
          ),
        ),

        // ── Bottom content ───────────────────────────────────────────────────
        Positioned(
          bottom: 160, // leave room for OnboardingScreen controls
          left: 28,
          right: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primaryGold.withValues(alpha: 0.5),
                  ),
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

              // Title
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

              // Description
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 15,
                  height: 1.65,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LANGUAGE DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageDialog extends StatefulWidget {
  final ValueChanged<String> onLanguageSelected;
  const _LanguageDialog({required this.onLanguageSelected});

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  String? _hoveredLanguage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryGold.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 60,
              offset: const Offset(0, 30),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold line accent
            Container(
              width: 36,
              height: 2,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: AppTheme.subtleGoldGradient,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            ShaderMask(
              shaderCallback: (b) =>
                  AppTheme.subtleGoldGradient.createShader(b),
              child: const Text(
                'CHOISIR LA LANGUE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your preferred language',
              style: TextStyle(
                color: AppTheme.foreground.withValues(alpha: 0.45),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            _buildLanguageOption('English', 'en', '🇬🇧'),
            const SizedBox(height: 12),
            _buildLanguageOption('Français', 'fr', '🇫🇷'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label, String code, String flag) {
    final isSelected = _hoveredLanguage == code;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredLanguage = code),
      onExit: (_) => setState(() => _hoveredLanguage = null),
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _hoveredLanguage = code);
        },
        onTap: () => widget.onLanguageSelected(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: isSelected
                ? AppTheme.subtleGoldGradient
                : LinearGradient(
                    colors: [
                      AppTheme.muted,
                      AppTheme.muted.withValues(alpha: 0.8),
                    ],
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryGold.withValues(alpha: 0.6)
                  : AppTheme.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : AppTheme.foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_rounded, color: Colors.black87, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOADING INDICATOR
// ─────────────────────────────────────────────────────────────────────────────

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
