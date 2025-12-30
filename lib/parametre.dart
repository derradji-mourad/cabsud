import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/string.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'fr';
  String _userName = '';
  String _userEmail = '';

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
    _fetchUserInfo();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'fr';
    });
  }

  Future<void> _fetchUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? '';
      });

      // Since the users table doesn't have a full_name column,
      // we'll use the email as the display name for now
      // You can add a full_name column to your users table if needed
      setState(() {
        _userName = user.email ?? 'User';
      });
    }
  }

  Future<void> _changeLanguage(String? newLang) async {
    if (newLang != null && newLang != _selectedLanguage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', newLang);
      Strings.load(newLang);
      setState(() {
        _selectedLanguage = newLang;
      });
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            gradient: _goldGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    Strings.of(context).termsOfServiceContent,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
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
                    child: const Text(
                      "I Agree",
                      style: TextStyle(color: Colors.amber),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
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
          color: Colors.white, // masked by shader
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          Strings.of(context).settingsTitle,
          style: const TextStyle(
            fontSize: 22,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _goldGradient,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            title: gradientText(Strings.of(context).userInfoTitle, fontSize: 18),
            subtitle: Text(
              'Name: $_userName\nEmail: $_userEmail',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const Divider(color: Colors.white),

          // Language selector
          ListTile(
            title: gradientText(Strings.of(context).languageTitle),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: _goldGradient.colors.first,
              items: const [
                DropdownMenuItem(
                  value: 'fr',
                  child: Text('Français', style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text('English', style: TextStyle(color: Colors.white)),
                ),
              ],
              onChanged: _changeLanguage,
            ),
          ),

          const Divider(color: Colors.white),

          // Terms and Privacy
          ListTile(
            title: gradientText(Strings.of(context).termsAndPrivacy, fontSize: 16),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onTap: _showTermsDialog,
          ),

          const Divider(color: Colors.white),

          // Logout
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
                child: Text(
                  Strings.of(context).logoutButton,
                  style: const TextStyle(
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
