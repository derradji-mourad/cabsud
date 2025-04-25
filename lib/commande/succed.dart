import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home_page.dart';
import '../localization/string.dart'; // Ensure this points to your Strings class

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  bool _isLanguageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? selectedLanguage = prefs.getString('language');

    if (selectedLanguage == null) {
      selectedLanguage = 'fr'; // default to French
      await prefs.setString('language', 'fr');
    }

    Strings.load(selectedLanguage);
    setState(() {
      _isLanguageLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [
        Color(0xFFAE8625),
        Color(0xFFF7EF8A),
        Color(0xFFD2AC47),
        Color(0xFFEDC967),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    if (!_isLanguageLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    final strings = Strings.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Lottie animation
              SizedBox(
                height: 150,
                child: Lottie.asset('assets/animation/success.json'),
              ),

              const SizedBox(height: 30),

              // ✅ Localized Gradient Text
              ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Text(
                  strings.commandSuccessMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Masked by ShaderMask
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ✅ Gradient Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    strings.backToHome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
