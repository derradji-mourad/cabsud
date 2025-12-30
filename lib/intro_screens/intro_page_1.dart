import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/string.dart';

/// Luxury color palette
class _LuxuryColors {
  static const goldLight = Color(0xFFF7EF8A);
  static const goldMedium = Color(0xFFD4AF37);
  static const goldDark = Color(0xFFAE8625);
  static const goldAccent = Color(0xFFEDC967);
  static const backgroundDark = Color(0xFF0A0A0A);
  static const backgroundMedium = Color(0xFF121212);
}

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
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
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
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: _LanguageDialog(
              onLanguageSelected: (languageCode) async {
                HapticFeedback.mediumImpact();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('language', languageCode);
                Strings.load(languageCode);
                if (mounted) {
                  Navigator.of(context).pop();
                  setState(() {});
                }
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
      return Scaffold(
        backgroundColor: _LuxuryColors.backgroundDark,
        body: const Center(child: _LuxuryLoadingIndicator()),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final imageSize = screenSize.width * 0.55;
    final titleFontSize = screenSize.width * 0.068;
    final descriptionFontSize = screenSize.width * 0.042;

    return Scaffold(
      backgroundColor: _LuxuryColors.backgroundDark,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _LuxuryColors.backgroundDark,
                _LuxuryColors.backgroundMedium,
                _LuxuryColors.backgroundDark,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.05,
                  vertical: screenSize.height * 0.03,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LuxuryImageCard(
                      imagePath: 'assets/intro/intro.jpg',
                      size: imageSize,
                      cacheSize: (imageSize * devicePixelRatio).round(),
                    ),
                    SizedBox(height: screenSize.height * 0.05),
                    _LuxuryTitle(
                      text: Strings.of(context).appTitle,
                      fontSize: titleFontSize,
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                    _LuxuryDescriptionCard(
                      text: Strings.of(context).descriptionText,
                      fontSize: descriptionFontSize,
                      horizontalPadding: screenSize.width * 0.08,
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
            valueColor: AlwaysStoppedAnimation<Color>(_LuxuryColors.goldMedium),
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_LuxuryColors.goldDark, _LuxuryColors.goldLight],
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

class _LuxuryImageCard extends StatelessWidget {
  final String imagePath;
  final double size;
  final int cacheSize;

  const _LuxuryImageCard({
    required this.imagePath,
    required this.size,
    required this.cacheSize,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FutureBuilder(
        future: precacheImage(AssetImage(imagePath), context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    _LuxuryColors.goldDark,
                    _LuxuryColors.goldLight,
                    _LuxuryColors.goldMedium,
                    _LuxuryColors.goldAccent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _LuxuryColors.goldMedium.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                    spreadRadius: -8,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3.5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.5),
                child: Image.asset(
                  imagePath,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  cacheWidth: cacheSize,
                  cacheHeight: cacheSize,
                ),
              ),
            );
          }
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _LuxuryColors.backgroundMedium,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_LuxuryColors.goldLight),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LuxuryTitle extends StatelessWidget {
  final String text;
  final double fontSize;

  const _LuxuryTitle({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          _LuxuryColors.goldLight,
          _LuxuryColors.goldAccent,
          _LuxuryColors.goldMedium,
        ],
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1.2,
          height: 1.3,
        ),
      ),
    );
  }
}

class _LuxuryDescriptionCard extends StatelessWidget {
  final String text;
  final double fontSize;
  final double horizontalPadding;

  const _LuxuryDescriptionCard({
    required this.text,
    required this.fontSize,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              _LuxuryColors.goldDark,
              _LuxuryColors.goldLight,
              _LuxuryColors.goldMedium,
              _LuxuryColors.goldAccent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _LuxuryColors.goldMedium.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
          ],
        ),
        padding: const EdgeInsets.all(3.5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.5),
            color: _LuxuryColors.backgroundDark,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

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
          color: _LuxuryColors.backgroundMedium,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _LuxuryColors.goldMedium.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _LuxuryColors.goldMedium.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_LuxuryColors.goldDark, _LuxuryColors.goldLight],
              ).createShader(bounds),
              child: const Text(
                'CHOISIR LA LANGUE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),
            _buildLanguageButton('English', 'en', '🇬🇧'),
            const SizedBox(height: 16),
            _buildLanguageButton('Français', 'fr', '🇫🇷'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String label, String languageCode, String icon) {
    final isHovered = _hoveredLanguage == languageCode;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredLanguage = languageCode),
      onExit: (_) => setState(() => _hoveredLanguage = null),
      child: GestureDetector(
        onTapDown: (_) => HapticFeedback.lightImpact(),
        onTap: () => widget.onLanguageSelected(languageCode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHovered
                  ? [
                _LuxuryColors.goldDark,
                _LuxuryColors.goldLight,
                _LuxuryColors.goldAccent,
              ]
                  : [
                _LuxuryColors.goldDark.withOpacity(0.8),
                _LuxuryColors.goldLight.withOpacity(0.8),
                _LuxuryColors.goldAccent.withOpacity(0.8),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isHovered
                ? [
              BoxShadow(
                color: _LuxuryColors.goldMedium.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
