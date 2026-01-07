import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cabsudapp/authentification/log_in.dart';
import 'package:cabsudapp/authentification/sing_up.dart';
import 'package:cabsudapp/home_page.dart';
import 'package:cabsudapp/spalsh_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/string.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Stripe
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  await Stripe.instance.applySettings();

  // Initialize language
  Strings.load('fr');

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Attempt to restore session
  final bool isLoggedIn = await _tryRestoreSession();

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

/// Attempts to restore a user session using stored refresh token
Future<bool> _tryRestoreSession() async {
  final supabase = Supabase.instance.client;

  // First check if there's already an active session
  Session? session = supabase.auth.currentSession;

  if (session != null) {
    // Session exists, update stored tokens
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', session.accessToken);
    if (session.refreshToken != null) {
      await prefs.setString('refresh_token', session.refreshToken!);
    }
    return true;
  }

  // No active session, try to recover using refresh token
  final prefs = await SharedPreferences.getInstance();
  final refreshToken = prefs.getString('refresh_token');

  if (refreshToken == null || refreshToken.isEmpty) {
    // No refresh token stored, user needs to login
    return false;
  }

  try {
    // Attempt to refresh the session using the stored refresh token
    final response = await supabase.auth.refreshSession(refreshToken);
    session = response.session;

    if (session != null) {
      // Successfully restored session, update stored tokens
      await prefs.setString('jwt_token', session.accessToken);
      if (session.refreshToken != null) {
        await prefs.setString('refresh_token', session.refreshToken!);
      }
      return true;
    }
  } catch (e) {
    debugPrint('Session recovery failed: $e');
    // Clear invalid tokens
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
  }

  return false;
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const HomePage() : const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginScreen(),
        '/signin': (context) => const SignUpScreen(),
      },
    );
  }
}
