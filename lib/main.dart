import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cabsudapp/authentification/log_in.dart';
import 'package:cabsudapp/authentification/sing_up.dart';
import 'package:cabsudapp/home_page.dart';
import 'package:cabsudapp/spalsh_screen.dart';
import 'package:cabsudapp/reuse/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/string.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Set Stripe key (synchronous, fast)
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;

  // Initialize language (synchronous, fast)
  Strings.load('fr');

  // Initialize Supabase (required before runApp for auth state)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Launch app immediately — heavy operations happen AFTER first frame
  runApp(const MyApp());
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Defer heavy operations to after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    bool isLoggedIn = false;

    try {
      // Run Stripe settings and session restore concurrently
      // Stripe failure should NOT block the app
      final results = await Future.wait([
        Stripe.instance.applySettings().catchError((e) {
          debugPrint('Stripe init failed (non-fatal): $e');
          return null;
        }),
        _tryRestoreSession(),
      ]);

      isLoggedIn = results[1] as bool;
    } catch (e) {
      debugPrint('App initialization error: $e');
      // Default to not logged in — user will see login screen
    }

    // Listen for auth state changes (useful for OAuth logins)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? newSession = data.session;

      if (event == AuthChangeEvent.signedIn && newSession != null) {
        navigatorKey.currentState?.pushReplacementNamed('/home');
      }
    });

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: _isInitialized
          ? (_isLoggedIn ? const HomePage() : const SplashScreen())
          : const _AppLoadingScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginScreen(),
        '/signin': (context) => const SignUpScreen(),
      },
    );
  }
}

/// Minimal loading screen shown while Stripe + session init complete
class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.luxuryBackgroundGradient,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryGold.withValues(alpha: 0.4),
                      AppTheme.primaryGold.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  size: 50,
                  color: AppTheme.primaryGold,
                ),
              ),
              const SizedBox(height: 32),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.lightGold, AppTheme.primaryGold],
                ).createShader(bounds),
                child: const Text(
                  'CABSUD',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
