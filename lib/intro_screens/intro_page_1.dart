import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/string.dart'; // Import your Strings manager

class IntroPage1 extends StatefulWidget {
  const IntroPage1({super.key});

  @override
  State<IntroPage1> createState() => _IntroPage1State();
}

class _IntroPage1State extends State<IntroPage1> {
  bool _isLanguageLoaded = false;

  @override
  void initState() {
    super.initState();
    _initLanguage();
  }

  Future<void> _initLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedLanguage = prefs.getString('language');

    // Default to French if no language was set
    if (selectedLanguage == null) {
      selectedLanguage = 'fr';
      await prefs.setString('language', 'fr');
    }

    Strings.load(selectedLanguage);
    setState(() {
      _isLanguageLoaded = true;
    });

    // Only show language dialog if user hasn't picked one yet
    if (prefs.getString('language') == 'fr') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLanguageDialog(context);
      });
    }
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    showDialog(
      context: context,
      barrierDismissible: false, // Make sure user chooses a language
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black, // Set background to black
          title: const Text(
            'Choose Language',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGradientButton(
                'English',
                    () async {
                  await prefs.setString('language', 'en');
                  Strings.load('en');
                  Navigator.of(context).pop();
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              _buildGradientButton(
                'Français',
                    () async {
                  await prefs.setString('language', 'fr');
                  Strings.load('fr');
                  Navigator.of(context).pop();
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradientButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFAE8625),
              Color(0xFFF7EF8A),
              Color(0xFFD2AC47),
              Color(0xFFEDC967),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black, // Text color black
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final imageWidth = screenSize.width * 0.5;
    final fontSizeTitle = screenSize.width * 0.07;
    final fontSizeDescription = screenSize.width * 0.045;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.black),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FutureBuilder(
                    future: precacheImage(
                      const AssetImage('assets/intro/intro.jpg'),
                      context,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFAE8625),
                                Color(0xFFF7EF8A),
                                Color(0xFFD2AC47),
                                Color(0xFFEDC967)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: Image.asset(
                              'assets/intro/intro.jpg',
                              width: imageWidth,
                              height: imageWidth,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          width: imageWidth,
                          height: imageWidth,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: screenSize.height * 0.04),
                  Text(
                    Strings.of(context).appTitle,
                    style: TextStyle(
                      fontSize: fontSizeTitle,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.03),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFAE8625),
                            Color(0xFFF7EF8A),
                            Color(0xFFD2AC47),
                            Color(0xFFEDC967)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        padding: EdgeInsets.all(screenSize.width * 0.05),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black,
                        ),
                        child: Text(
                          Strings.of(context).descriptionText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSizeDescription,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
