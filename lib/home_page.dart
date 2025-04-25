import 'package:cabsudapp/parametre.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cabsudapp/services/contact%20page.dart';
import 'package:cabsudapp/services/services_page.dart';
import 'package:cabsudapp/services/route_page.dart';
import 'package:cabsudapp/localization/string.dart';
import 'package:cabsudapp/services/services_type_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isLanguageLoaded = false;

  final List<Widget> _pages = [
    HomeScreen(),
    ContactPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? selectedLanguage = prefs.getString('language');

    if (selectedLanguage == null) {
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: Strings.of(context).accueil,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.phone),
            label: Strings.of(context).contact1,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: Strings.of(context).parametres,
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: _buildModernTile(
              context,
              imagePath: 'assets/intro/mise_a_disposition.jpg',
              label: Strings.of(context).faireUneCommande1,
              destination: ServiceSelectionPage(),
            ),
          ),
          Expanded(
            child: _buildModernTile(
              context,
              imagePath: 'assets/intro/tourisem_transport.jpg',
              label: Strings.of(context).miseADisposition1,
              destination: RoutePage(),
            ),
          ),
          Expanded(
            child: _buildModernTile(
              context,
              imagePath: 'assets/intro/Atob.jpg',
              label: Strings.of(context).nosServices1,
              destination: ServicesPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTile(BuildContext context,
      {required String imagePath,
        required String label,
        required Widget destination}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.3),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: Colors.white24,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => destination),
                  );
                },
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 4,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
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
