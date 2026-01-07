import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/string.dart';

/// Luxury color palette - extracted for consistency and reusability
abstract final class LuxuryColors {
  static const goldLight = Color(0xFFF7EF8A);
  static const goldMedium = Color(0xFFD4AF37);
  static const goldDark = Color(0xFFAE8625);
  static const goldAccent = Color(0xFFEDC967);
  static const backgroundDark = Color(0xFF0A0A0A);
  static const backgroundMedium = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1A1A1A);

  static const goldGradient = LinearGradient(
    colors: [goldDark, goldLight, goldMedium],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundDark, backgroundMedium, backgroundDark],
  );
}

/// Premium sign-up screen with Material 3 design and advanced optimizations
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  static final _supabase = Supabase.instance.client;

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _loadingNotifier = ValueNotifier<bool>(false);
  final _passwordVisibilityNotifier = ValueNotifier<bool>(false);
  final _confirmPasswordVisibilityNotifier = ValueNotifier<bool>(false);
  final _languageLoadedNotifier = ValueNotifier<bool>(false);

  // Email validation regex - cached as static const
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Strong password validation - requires uppercase, digit, special char, min 6 chars
  static final _passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,}$',
  );

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _loadLanguage();
  }

  void _initializeControllers() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _loadingNotifier.dispose();
    _passwordVisibilityNotifier.dispose();
    _confirmPasswordVisibilityNotifier.dispose();
    _languageLoadedNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedLanguage = prefs.getString('language') ?? 'fr';

      if (!prefs.containsKey('language')) {
        await prefs.setString('language', selectedLanguage);
      }

      Strings.load(selectedLanguage);

      if (mounted) {
        _languageLoadedNotifier.value = true;
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('Language load error: $e');
      // Fallback to default if loading fails
      if (mounted) {
        _languageLoadedNotifier.value = true;
        _fadeController.forward();
      }
    }
  }

  Future<void> _handleEmailSignUp() async {
    // Minimal haptic feedback - only on critical actions
    HapticFeedback.lightImpact();

    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      _showSnackbar(
        Strings.of(context).passwordMismatch,
        isError: true,
      );
      return;
    }

    final accepted = await _showTermsDialog();
    if (!accepted) return;

    _loadingNotifier.value = true;

    try {
      final preRequestTime = DateTime.now().toUtc();

      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = response.user;
      final createdAt = DateTime.tryParse(user?.createdAt ?? '');
      final isNewUser = createdAt != null &&
          createdAt
              .isAfter(preRequestTime.subtract(const Duration(seconds: 2)));

      if (!isNewUser || user == null) {
        if (!mounted) return;
        _showSnackbar(Strings.of(context).loginFailed, isError: true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      await _supabase.from('users').insert({
        'id': user.id,
        'email': _emailController.text.trim(),
        'role': 'user',
      });

      if (mounted) {
        _showSnackbar(Strings.of(context).signUpSuccess, isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } on AuthException catch (error) {
      debugPrint('AuthException: $error');
      if (mounted) {
        _showSnackbar(Strings.of(context).signUpFailed, isError: true);
      }
    } catch (error) {
      debugPrint('Unexpected error: $error');
      if (mounted) {
        _showSnackbar(Strings.of(context).signUpFailed, isError: true);
      }
    } finally {
      _loadingNotifier.value = false;
    }
  }

  Future<void> _handleGoogleSignUp() async {
    HapticFeedback.lightImpact();

    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        authScreenLaunchMode: LaunchMode.externalApplication,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } catch (error) {
      debugPrint('Google Sign-In failed: $error');
      if (mounted) {
        _showSnackbar(Strings.of(context).googleSignInFailed, isError: true);
      }
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade900 : LuxuryColors.goldDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _showTermsDialog() async {
    HapticFeedback.selectionClick();

    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: false,
          barrierLabel: 'Terms of Service',
          barrierColor: Colors.black87,
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SizedBox.shrink(),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity:
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                  CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic),
                ),
                child: _TermsDialog(
                  onAccept: () => Navigator.of(context).pop(true),
                  onCancel: () => Navigator.of(context).pop(false),
                ),
              ),
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxuryColors.backgroundDark,
      body: ValueListenableBuilder<bool>(
        valueListenable: _languageLoadedNotifier,
        builder: (context, isLoaded, _) {
          if (!isLoaded) {
            return const Center(child: _LuxuryLoadingIndicator());
          }

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LuxuryColors.backgroundGradient,
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth > 600;
                    final horizontalPadding = isTablet ? 48.0 : 24.0;

                    return Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 32,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildForm(context),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final strings = Strings.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Logo(),
          const SizedBox(height: 48),
          _WelcomeText(title: strings.signUp),
          const SizedBox(height: 32),
          _EmailField(
            controller: _emailController,
            hintText: strings.email,
            emailRegex: _emailRegex,
            emailRequired: strings.emailRequired,
            emailInvalid: strings.emailInvalid,
          ),
          const SizedBox(height: 20),
          _PasswordField(
            controller: _passwordController,
            hintText: strings.password,
            visibilityNotifier: _passwordVisibilityNotifier,
            passwordRegex: _passwordRegex,
            passwordRequired: strings.passwordRequired,
            passwordStrength: strings.passwordStrength,
          ),
          const SizedBox(height: 20),
          _ConfirmPasswordField(
            controller: _confirmPasswordController,
            passwordController: _passwordController,
            hintText: strings.confirmPassword,
            visibilityNotifier: _confirmPasswordVisibilityNotifier,
            confirmPasswordRequired: strings.confirmPasswordRequired,
            passwordMismatch: strings.passwordMismatch,
          ),
          const SizedBox(height: 32),
          ValueListenableBuilder<bool>(
            valueListenable: _loadingNotifier,
            builder: (context, isLoading, _) {
              return _LuxuryPrimaryButton(
                label: strings.signUp,
                onPressed: isLoading ? null : _handleEmailSignUp,
                isLoading: isLoading,
              );
            },
          ),
          const SizedBox(height: 24),
          const _Divider(),
          const SizedBox(height: 24),
          _LuxurySecondaryButton(
            label: strings.googleSignUp,
            icon: 'assets/authnfication/google.png',
            onPressed: _handleGoogleSignUp,
          ),
          const SizedBox(height: 32),
          _LoginPrompt(
            alreadyHaveAccount: strings.alreadyHaveAccount,
            login: strings.login,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXTRACTED WIDGETS FOR BETTER PERFORMANCE
// ============================================================================

/// Logo widget with Hero animation and error handling - UPDATED TO 320
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Hero(
        tag: 'app_logo',
        child: Container(
          height: 320, // INCREASED to 320 for consistency with login screen
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: LuxuryColors.goldMedium.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Image.asset(
            'assets/logo/logo4--.png',
            height: 320, // INCREASED to 320
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.business,
                size: 160, // INCREASED proportionally
                color: LuxuryColors.goldMedium,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Welcome text with gradient shader
class _WelcomeText extends StatelessWidget {
  const _WelcomeText({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [LuxuryColors.goldDark, LuxuryColors.goldLight],
          ).createShader(bounds),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your luxury account',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Email field with optimized validation
class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.hintText,
    required this.emailRegex,
    required this.emailRequired,
    required this.emailInvalid,
  });

  final TextEditingController controller;
  final String hintText;
  final RegExp emailRegex;
  final String emailRequired;
  final String emailInvalid;

  @override
  Widget build(BuildContext context) {
    return _LuxuryTextField(
      controller: controller,
      hintText: hintText,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) return emailRequired;
        if (!emailRegex.hasMatch(value)) return emailInvalid;
        return null;
      },
    );
  }
}

/// Password field with visibility toggle
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hintText,
    required this.visibilityNotifier,
    required this.passwordRegex,
    required this.passwordRequired,
    required this.passwordStrength,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueNotifier<bool> visibilityNotifier;
  final RegExp passwordRegex;
  final String passwordRequired;
  final String passwordStrength;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: visibilityNotifier,
      builder: (context, isVisible, _) {
        return _LuxuryTextField(
          controller: controller,
          hintText: hintText,
          prefixIcon: Icons.lock_outline,
          obscureText: !isVisible,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off : Icons.visibility,
              color: LuxuryColors.goldMedium.withValues(alpha: 0.7),
              size: 22,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              visibilityNotifier.value = !visibilityNotifier.value;
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return passwordRequired;
            if (!passwordRegex.hasMatch(value)) return passwordStrength;
            return null;
          },
        );
      },
    );
  }
}

/// Confirm password field
class _ConfirmPasswordField extends StatelessWidget {
  const _ConfirmPasswordField({
    required this.controller,
    required this.passwordController,
    required this.hintText,
    required this.visibilityNotifier,
    required this.confirmPasswordRequired,
    required this.passwordMismatch,
  });

  final TextEditingController controller;
  final TextEditingController passwordController;
  final String hintText;
  final ValueNotifier<bool> visibilityNotifier;
  final String confirmPasswordRequired;
  final String passwordMismatch;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: visibilityNotifier,
      builder: (context, isVisible, _) {
        return _LuxuryTextField(
          controller: controller,
          hintText: hintText,
          prefixIcon: Icons.lock_outline,
          obscureText: !isVisible,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off : Icons.visibility,
              color: LuxuryColors.goldMedium.withValues(alpha: 0.7),
              size: 22,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              visibilityNotifier.value = !visibilityNotifier.value;
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return confirmPasswordRequired;
            if (value != passwordController.text) return passwordMismatch;
            return null;
          },
        );
      },
    );
  }
}

/// Divider with gradient
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  LuxuryColors.goldMedium.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  LuxuryColors.goldMedium.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Login prompt
class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({
    required this.alreadyHaveAccount,
    required this.login,
  });

  final String alreadyHaveAccount;
  final String login;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          alreadyHaveAccount,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pushReplacementNamed(context, '/login');
          },
          style: TextButton.styleFrom(
            foregroundColor: LuxuryColors.goldLight,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            login,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Luxury loading indicator
class _LuxuryLoadingIndicator extends StatelessWidget {
  const _LuxuryLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              LuxuryColors.goldMedium,
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(
          'LOADING...',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
            color: LuxuryColors.goldMedium,
          ),
        ),
      ],
    );
  }
}

/// Premium text field with animated gradient border
class _LuxuryTextField extends StatefulWidget {
  const _LuxuryTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  @override
  State<_LuxuryTextField> createState() => _LuxuryTextFieldState();
}

class _LuxuryTextFieldState extends State<_LuxuryTextField> {
  late final FocusNode _focusNode;
  late final ValueNotifier<bool> _isFocused;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _isFocused = ValueNotifier(false);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _isFocused.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    _isFocused.value = _focusNode.hasFocus;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isFocused,
      builder: (context, isFocused, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LuxuryColors.goldGradient,
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: LuxuryColors.goldMedium.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: LuxuryColors.goldMedium.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              color: LuxuryColors.backgroundDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              validator: widget.validator,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  widget.prefixIcon,
                  color: isFocused
                      ? LuxuryColors.goldMedium
                      : LuxuryColors.goldMedium.withValues(alpha: 0.6),
                  size: 22,
                ),
                suffixIcon: widget.suffixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
                errorStyle: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Premium primary button using Material InkWell
class _LuxuryPrimaryButton extends StatelessWidget {
  const _LuxuryPrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? const LinearGradient(
                colors: [
                  LuxuryColors.goldDark,
                  LuxuryColors.goldLight,
                  LuxuryColors.goldAccent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : LinearGradient(
                colors: [Colors.grey.shade800, Colors.grey.shade700],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: LuxuryColors.goldMedium.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                    ),
                  )
                : Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: isEnabled ? Colors.black87 : Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Secondary button for social login
class _LuxurySecondaryButton extends StatelessWidget {
  const _LuxurySecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.black.withValues(alpha: 0.05),
          highlightColor: Colors.black.withValues(alpha: 0.03),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                icon,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.login, size: 24);
                },
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Terms of service dialog with optimized structure
class _TermsDialog extends StatelessWidget {
  const _TermsDialog({
    required this.onAccept,
    required this.onCancel,
  });

  final VoidCallback onAccept;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: LuxuryColors.backgroundMedium,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: LuxuryColors.goldMedium.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: LuxuryColors.goldMedium.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [LuxuryColors.goldDark, LuxuryColors.goldLight],
              ).createShader(bounds),
              child: Text(
                Strings.of(context).termsOfService.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: LuxuryColors.backgroundDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: LuxuryColors.goldMedium.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    Strings.of(context).termsOfServiceContent,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'I AGREE',
                    isPrimary: true,
                    onPressed: onAccept,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'CANCEL',
                    isPrimary: false,
                    onPressed: onCancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog button with InkWell instead of GestureDetector
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [LuxuryColors.goldDark, LuxuryColors.goldLight],
              )
            : null,
        color: isPrimary ? null : LuxuryColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: !isPrimary
            ? Border.all(
                color: LuxuryColors.goldMedium.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.black87 : LuxuryColors.goldLight,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
