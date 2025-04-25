import 'package:cabsudapp/authentification/sing_up.dart';
import 'package:cabsudapp/intro_screens/intro_page_1.dart';
import 'package:cabsudapp/intro_screens/intro_page_2.dart';
import 'package:cabsudapp/intro_screens/intro_page_3.dart';
import 'package:cabsudapp/intro_screens/intro_page_4.dart';
import 'package:cabsudapp/intro_screens/intro_page_5.dart';
import 'package:cabsudapp/intro_screens/intro_page_6.dart';
import 'package:cabsudapp/services/services_page.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cabsudapp/localization/string.dart'; // Import the Strings class

import 'commande/payment.dart';
import 'home_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool onLastPage = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView for onboarding screens
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                onLastPage = (index == 5);
              });
            },
            children: [
              IntroPage1(),
              IntroPage2(),
              IntroPage3(),
              IntroPage4(),
              IntroPage5(),
              IntroPage6(),
            ],
          ),

          // Bottom navigation controls
          Positioned(
            bottom: screenSize.height * 0.1,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Dot indicator
                SmoothPageIndicator(
                  controller: _controller,
                  count: 6,
                  effect: ExpandingDotsEffect(
                    activeDotColor: Colors.white,
                    dotColor: Colors.grey.shade700,
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.03),

                // Buttons: Skip, Next, Done
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Skip button
                    GestureDetector(
                      onTap: () {
                        _controller.jumpToPage(5);
                      },
                      child: Text(
                        Strings.of(context).skipButton, // Use the translated string
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Next or Done button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.1,
                          vertical: screenSize.height * 0.015,
                        ),
                      ),
                      onPressed: onLastPage
                          ? () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                              return SignUpScreen();
                            }));
                      }
                          : () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        onLastPage
                            ? Strings.of(context).getStartedButton // Use the translated string
                            : Strings.of(context).nextButton, // Use the translated string
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
