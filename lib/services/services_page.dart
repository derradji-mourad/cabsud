import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cabsudapp/localization/string.dart';
import '../custom_page_route.dart';
import '../home_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  ServicesPageState createState() => ServicesPageState();
}

class ServicesPageState extends State<ServicesPage> {
  bool _isLanguageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? selectedLanguage = prefs.getString('language') ?? 'fr';
    await prefs.setString('language', selectedLanguage);
    Strings.load(selectedLanguage);

    setState(() {
      _isLanguageLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<_ServiceItem> services = [
      _ServiceItem(Strings.of(context).chauffeurTitle, Strings.of(context).chauffeurDesc, Icons.directions_car),
      _ServiceItem(Strings.of(context).prixFixesTitle, Strings.of(context).prixFixesDesc, Icons.attach_money),
      _ServiceItem(Strings.of(context).vehiculesTitle, Strings.of(context).vehiculesDesc, Icons.car_repair),
      _ServiceItem(Strings.of(context).wifiTitle, Strings.of(context).wifiDesc, Icons.wifi),
      _ServiceItem(Strings.of(context).enfantsTitle, Strings.of(context).enfantsDesc, Icons.child_care),
      _ServiceItem(Strings.of(context).paiementTitle, Strings.of(context).paiementDesc, Icons.payment),
      _ServiceItem(Strings.of(context).paiementSecuTitle, Strings.of(context).paiementSecuDesc, Icons.credit_card),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.of(context).servicesTitle),
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 2,
      ),
      body: Container(
        color: Colors.black,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: services.length + 1,
          itemBuilder: (context, index) {
            if (index < services.length) {
              final service = services[index];
              return ServiceCard(
                title: service.title,
                description: service.description,
                icon: service.icon,
              );
            } else {
              return const SizedBox(height: 30);
            }
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFAE8625),
                Color(0xFFF7EF8A),
                Color(0xFFD2AC47),
                Color(0xFFEDC967)
              ],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(CustomPageRoute(child: const HomePage()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(
              Strings.of(context).gotoHomeBtn,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final String description;
  final IconData icon;

  const _ServiceItem(this.title, this.description, this.icon);
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  static const _gradient = LinearGradient(
    colors: [Color(0xFFAE8625), Color(0xFFF7EF8A), Color(0xFFD2AC47), Color(0xFFEDC967)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: _gradient,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 30, color: Colors.black),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF7EF8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFEDC967),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
