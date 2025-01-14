import 'package:flutter/material.dart';

class IntroPage1 extends StatelessWidget {
  const IntroPage1({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    final imageWidth = screenSize.width * 0.5; // 50% of screen width
    final fontSizeTitle = screenSize.width * 0.07; // 7% of screen width
    final fontSizeDescription = screenSize.width * 0.045; // 4.5% of screen width

    return Scaffold(
      body: Stack(
        children: [
          // Solid black background
          Container(
            color: Colors.black,
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Adaptive image size with gold gradient border
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
                                Color(0xFFAEB625), // Gold #AEB625
                                Color(0xFFF7EF8A), // Gold #F7EF8A
                                Color(0xFFD2AC47), // Gold #D2AC47
                                Color(0xFFEDC967), // Gold #EDC967
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
                          padding: const EdgeInsets.all(3), // Border thickness
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: Image.asset(
                              'assets/intro/intro.jpg', // Replace with your image path
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
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: screenSize.height * 0.04), // 4% of screen height

                  // Adaptive title text
                  Text(
                    'Bienvenue sur Cab-Sud',
                    style: TextStyle(
                      fontSize: fontSizeTitle,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.03), // 3% of screen height

                  // Description with gold gradient border
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFAEB625), // Gold #AEB625
                            Color(0xFFF7EF8A), // Gold #F7EF8A
                            Color(0xFFD2AC47), // Gold #D2AC47
                            Color(0xFFEDC967), // Gold #EDC967
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
                      padding: const EdgeInsets.all(3), // Border thickness
                      child: Container(
                        padding: EdgeInsets.all(screenSize.width * 0.05),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black, // Inner container background
                        ),
                        child: Text(
                          'Cab-Sud est une entreprise spécialisée dans le transport de personnes sur Marseille et la région.',
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
