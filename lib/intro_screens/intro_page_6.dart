import 'package:flutter/material.dart';
import '../localization/string.dart';

class _LuxuryColors {
  static const goldLight = Color(0xFFF7EF8A);
  static const goldMedium = Color(0xFFD4AF37);
  static const goldDark = Color(0xFFAE8625);
  static const goldAccent = Color(0xFFEDC967);
  static const backgroundDark = Color(0xFF0A0A0A);
  static const backgroundMedium = Color(0xFF121212);
}

class IntroPage6 extends StatefulWidget {
  const IntroPage6({super.key});

  @override
  State<IntroPage6> createState() => _IntroPage6State();
}

class _IntroPage6State extends State<IntroPage6>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
    });
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

  @override
  Widget build(BuildContext context) {
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
                      imagePath: 'assets/intro/mise_a_disposition.jpg',
                      size: imageSize,
                      cacheSize: (imageSize * devicePixelRatio).round(),
                    ),
                    SizedBox(height: screenSize.height * 0.05),
                    _LuxuryTitle(
                      text: Strings.of(context).introTitle6,
                      fontSize: titleFontSize,
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                    _LuxuryDescriptionCard(
                      text: Strings.of(context).introDescription6,
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
