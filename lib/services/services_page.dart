import 'package:flutter/material.dart';
import 'package:cabsudapp/services/services_type_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cabsudapp/localization/string.dart'; // Assuming your Strings.dart file is properly imported

class ServicesPage extends StatefulWidget {
  const ServicesPage({Key? key}) : super(key: key);

  @override
  _ServicesPageState createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
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
      // Default to French if no language was selected yet
      selectedLanguage = 'fr';
      await prefs.setString('language', 'fr');
    }

    Strings.load(selectedLanguage);

    setState(() {
      _isLanguageLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.of(context).servicesTitle),
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 2,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Service Cards
            ServiceCard(
              title: Strings.of(context).chauffeurTitle,
              description: Strings.of(context).chauffeurDesc,
              icon: Icons.directions_car,
            ),
            ServiceCard(
              title: Strings.of(context).prixFixesTitle,
              description: Strings.of(context).prixFixesDesc,
              icon: Icons.attach_money,
            ),
            ServiceCard(
              title: Strings.of(context).vehiculesTitle,
              description: Strings.of(context).vehiculesDesc,
              icon: Icons.car_repair,
            ),
            ServiceCard(
              title: Strings.of(context).wifiTitle,
              description: Strings.of(context).wifiDesc,
              icon: Icons.wifi,
            ),
            ServiceCard(
              title: Strings.of(context).enfantsTitle,
              description: Strings.of(context).enfantsDesc,
              icon: Icons.child_care,
            ),
            ServiceCard(
              title: Strings.of(context).paiementTitle,
              description: Strings.of(context).paiementDesc,
              icon: Icons.payment,
            ),
            ServiceCard(
              title: Strings.of(context).paiementSecuTitle,
              description: Strings.of(context).paiementSecuDesc,
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 30),

            // Navigate to Home Button with Gradient
            Center(
              child: Container(
                decoration: BoxDecoration(
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
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ServiceSelectionPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  ),
                  child: Text(
                    Strings.of(context).gotoHomeBtn,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black, // Text color to contrast with gradient
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const ServiceCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFAE8625), Color(0xFFF7EF8A), Color(0xFFD2AC47), Color(0xFFEDC967)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(3), // Border thickness
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black, // Inner card background color
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Circle with Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFAE8625), Color(0xFFF7EF8A), Color(0xFFD2AC47), Color(0xFFEDC967)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  icon,
                  size: 30,
                  color: Colors.black, // Icon color to contrast gradient
                ),
              ),
              const SizedBox(width: 20),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF7EF8A), // Text color
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFEDC967), // Description text color
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
