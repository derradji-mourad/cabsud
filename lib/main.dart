import 'package:cabsudapp/authentification/log_in.dart';
import 'package:cabsudapp/authentification/sing_up.dart';
import 'package:cabsudapp/home_page.dart';
import 'package:cabsudapp/spalsh_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/string.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize language
  Strings.load('fr'); // Pass the desired language code


  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://lvxcnjtkynedpemizcpu.supabase.co/', // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2eGNuanRreW5lZHBlbWl6Y3B1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgxNzk4MjEsImV4cCI6MjA1Mzc1NTgyMX0.500Id25TUBFuwxLtW4eMykngNjPDUFnCwvTKWs-WXKU', // Replace with your Supabase anon key
  );

  // Check if the user is already signed in
  final Session? session = Supabase.instance.client.auth.currentSession;
  final bool isLoggedIn = session != null;

  // Listen for auth state changes (useful for OAuth logins)
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    final Session? newSession = data.session;

    if (event == AuthChangeEvent.signedIn && newSession != null) {
      navigatorKey.currentState?.pushReplacementNamed('/home');
    }
  });

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? HomePage() : SplashScreen(), // Direct user based on login status
      routes: {
        '/home': (context) => HomePage(), // Home Page
        '/login': (context) =>  LoginScreen(),
        '/signin': (context) => SignUpScreen(),
      },
    );
  }
}