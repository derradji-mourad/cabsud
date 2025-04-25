import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/string.dart'; // Import the localization manager

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$");
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    final RegExp passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,}$');
    return passwordRegex.hasMatch(password);
  }

  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.of(context).passwordMismatch)),
      );
      return;
    }

    // Show Terms Dialog first
    final accepted = await _showTermsDialog();
    if (!accepted) return;

    try {
      final preRequestTime = DateTime.now().toUtc();

      final AuthResponse response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = response.user;

      if (user == null) {
        throw AuthException('Sign-up failed. No user returned.');
      }

      final createdAt = DateTime.tryParse(user.createdAt ?? '');
      final isNewUser = createdAt != null &&
          createdAt.isAfter(preRequestTime.subtract(Duration(seconds: 2)));

      if (!isNewUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Strings.of(context).loginFailed),
          ),
        );
        await Future.delayed(Duration(seconds: 2));
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.of(context).signUpSuccess)),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } on AuthException catch (error) {
      print("AuthException: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.of(context).signUpFailed)),
      );
    } catch (error) {
      print("Unexpected Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.of(context).signUpFailed)),
      );
    }
  }

  Future<void> _handleGoogleSignUp() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        authScreenLaunchMode: LaunchMode.externalApplication,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } catch (error) {
      print("Google Sign-In Failed: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.of(context).googleSignInFailed)),
      );
    }
  }

  Future<bool> _showTermsDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFAE8625),
                  Color(0xFFF7EF8A),
                  Color(0xFFD2AC47),
                  Color(0xFFEDC967),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Strings.of(context).termsOfService,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  height: 200,
                  child: SingleChildScrollView(
                    child: Text(
                      Strings.of(context).termsOfServiceContent,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      child: Text("I Agree", style: TextStyle(color: Colors.amber)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      child: Text("Cancel", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // Wait until the language is loaded
    if (!_isLanguageLoaded) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo/logo4.png', height: 220),
                  SizedBox(height: 32),
                  _buildInputField(Strings.of(context).email, _emailController, false, (value) {
                    if (value == null || value.isEmpty) return Strings.of(context).emailRequired;
                    if (!_isValidEmail(value)) return Strings.of(context).emailInvalid;
                    return null;
                  }),
                  SizedBox(height: 16),
                  _buildInputField(Strings.of(context).password, _passwordController, true, (value) {
                    if (value == null || value.isEmpty) return Strings.of(context).passwordRequired;
                    if (!_isValidPassword(value)) {
                      return Strings.of(context).passwordStrength;
                    }
                    return null;
                  }),
                  SizedBox(height: 16),
                  _buildInputField(Strings.of(context).confirmPassword, _confirmPasswordController, true, (value) {
                    if (value == null || value.isEmpty) return Strings.of(context).confirmPasswordRequired;
                    if (value != _passwordController.text) return Strings.of(context).passwordMismatch;
                    return null;
                  }),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleEmailSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(Strings.of(context).signUp, style: TextStyle(color: Colors.black)),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleGoogleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/authnfication/google.png', height: 24),
                        SizedBox(width: 10),
                        Text(Strings.of(context).googleSignUp, style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(Strings.of(context).alreadyHaveAccount, style: TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          Strings.of(context).login,
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hintText, TextEditingController controller, bool isObscure, FormFieldValidator<String>? validator) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Color(0xFFAE8625), Color(0xFFF7EF8A), Color(0xFFD2AC47), Color(0xFFEDC967)],
        ),
      ),
      padding: EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: isObscure,
          validator: validator,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ),
    );
  }
}
