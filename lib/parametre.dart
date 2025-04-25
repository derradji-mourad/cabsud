import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/string.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'fr';

  final LinearGradient _goldGradient = const LinearGradient(
    colors: [
      Color(0xFFAE8625),
      Color(0xFFF7EF8A),
      Color(0xFFD2AC47),
      Color(0xFFEDC967),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'fr';
    });
  }

  Future<void> _changeLanguage(String? newLang) async {
    if (newLang != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', newLang);
      setState(() {
        _selectedLanguage = newLang;
      });

      Strings.load(newLang);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: _goldGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Strings.of(context).termsOfService,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: SingleChildScrollView(
                  child: Text(
                    Strings.of(context).termsOfServiceContent,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text("I Agree", style: TextStyle(color: Colors.amber)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget gradientText(String text, {double fontSize = 16}) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          _goldGradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white, // Masked by gradient
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: gradientText('Parameters', fontSize: 22),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            title: gradientText('User Info', fontSize: 18),
            subtitle: const Text(
              'Name: John Doe\nEmail: johndoe@example.com',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const Divider(color: Colors.white),

          ListTile(
            title: gradientText('Select Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: _goldGradient.colors.first,
              items: const [
                DropdownMenuItem(
                  child: Text('Français', style: TextStyle(color: Colors.white)),
                  value: 'fr',
                ),
                DropdownMenuItem(
                  child: Text('English', style: TextStyle(color: Colors.white)),
                  value: 'en',
                ),
              ],
              onChanged: _changeLanguage,
            ),
          ),

          const Divider(color: Colors.white),

          ListTile(
            title: gradientText('Terms & Conditions / Privacy Policy', fontSize: 16),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onTap: _showTermsDialog,
          ),

          const Divider(color: Colors.white),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
            child: GestureDetector(
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _goldGradient,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
