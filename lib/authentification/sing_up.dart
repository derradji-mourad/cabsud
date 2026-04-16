import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/string.dart';
import 'package:cabsudapp/reuse/theme.dart';

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

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
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
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
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
      if (mounted) {
        _languageLoadedNotifier.value = true;
        _fadeController.forward();
      }
    }
  }

  Future<void> _handleEmailSignUp() async {
    HapticFeedback.lightImpact();
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      _showSnackbar(Strings.of(context).passwordMismatch, isError: true);
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
          createdAt.isAfter(
              preRequestTime.subtract(const Duration(seconds: 2)));

      if (!isNewUser || user == null) {
        if (!mounted) return;
        _showSnackbar(Strings.of(context).loginFailed, isError: true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
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
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      }
    } on AuthException catch (error) {
      debugPrint('AuthException: $error');
      if (mounted) _showSnackbar(Strings.of(context).signUpFailed, isError: true);
    } catch (error) {
      debugPrint('Unexpected error: $error');
      if (mounted) _showSnackbar(Strings.of(context).signUpFailed, isError: true);
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
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? const Color(0xFF2A1A1A) : AppTheme.muted,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError
                ? Colors.red.withValues(alpha: 0.3)
                : AppTheme.primaryGold.withValues(alpha: 0.3),
          ),
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
          barrierColor: Colors.black.withValues(alpha: 0.85),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SizedBox.shrink(),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
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
      backgroundColor: AppTheme.background,
      body: ValueListenableBuilder<bool>(
        valueListenable: _languageLoadedNotifier,
        builder: (context, isLoaded, _) {
          if (!isLoaded) {
            return Container(
              decoration: AppTheme.luxuryBackgroundGradient,
              child: const Center(child: _LuxuryLoadingIndicator()),
            );
          }

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Container(
              decoration: AppTheme.luxuryBackgroundGradient,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildContent(context),
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

  Widget _buildContent(BuildContext context) {
    final strings = Strings.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // ── Branding ──────────────────────────────────────────────────────
          _buildBranding(),
          const SizedBox(height: 36),

          // ── Header ────────────────────────────────────────────────────────
          _buildSectionHeader(strings),
          const SizedBox(height: 28),

          // ── Form ─────────────────────────────────────────────────────────
          Form(
            key: _formKey,
            child: Column(
              children: [
                _LuxuryTextField(
                  controller: _emailController,
                  hintText: strings.email,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) return strings.emailRequired;
                    if (!_emailRegex.hasMatch(value)) return strings.emailInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _PasswordField(
                  controller: _passwordController,
                  hintText: strings.password,
                  visibilityNotifier: _passwordVisibilityNotifier,
                  passwordRegex: _passwordRegex,
                  passwordRequired: strings.passwordRequired,
                  passwordStrength: strings.passwordStrength,
                ),
                const SizedBox(height: 16),
                _ConfirmPasswordField(
                  controller: _confirmPasswordController,
                  passwordController: _passwordController,
                  hintText: strings.confirmPassword,
                  visibilityNotifier: _confirmPasswordVisibilityNotifier,
                  confirmPasswordRequired: strings.confirmPasswordRequired,
                  passwordMismatch: strings.passwordMismatch,
                ),
                const SizedBox(height: 28),
                ValueListenableBuilder<bool>(
                  valueListenable: _loadingNotifier,
                  builder: (context, isLoading, _) {
                    return _GoldButton(
                      label: strings.signUp,
                      onPressed: isLoading ? null : _handleEmailSignUp,
                      isLoading: isLoading,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const _Divider(),
          const SizedBox(height: 24),

          // ── Google button ─────────────────────────────────────────────────
          _GoogleButton(
            label: strings.googleSignUp,
            icon: 'assets/authnfication/google.png',
            onPressed: _handleGoogleSignUp,
          ),
          const SizedBox(height: 28),

          // ── Login prompt ──────────────────────────────────────────────────
          _LoginPrompt(
            alreadyHaveAccount: strings.alreadyHaveAccount,
            login: strings.login,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryGold.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                blurRadius: 28,
              ),
            ],
          ),
          child: ClipOval(
            child: Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/logo/logo4--.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.directions_car_rounded,
                  size: 36,
                  color: AppTheme.primaryGold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback: (b) => AppTheme.subtleGoldGradient.createShader(b),
          child: const Text(
            'CABSUD',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(Strings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.signUp,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Créez votre compte luxe',
          style: TextStyle(
            color: AppTheme.foreground.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGold.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

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
    _focusNode.addListener(() => _isFocused.value = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _isFocused.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isFocused,
      builder: (context, isFocused, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? AppTheme.primaryGold.withValues(alpha: 0.7)
                  : AppTheme.border,
              width: isFocused ? 1.5 : 1,
            ),
            color: AppTheme.muted,
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.08),
                      blurRadius: 20,
                    ),
                  ]
                : [],
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
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: isFocused
                    ? AppTheme.primaryGold
                    : Colors.white.withValues(alpha: 0.35),
                size: 20,
              ),
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              errorStyle: const TextStyle(
                color: Color(0xFFE57373),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}

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
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: !isVisible,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppTheme.primaryGold.withValues(alpha: 0.6),
              size: 20,
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
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: !isVisible,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppTheme.primaryGold.withValues(alpha: 0.6),
              size: 20,
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
                  AppTheme.border,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OU',
            style: TextStyle(
              color: AppTheme.foreground.withValues(alpha: 0.35),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.border,
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
            color: AppTheme.foreground.withValues(alpha: 0.55),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pushReplacementNamed(context, '/login');
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryGold,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            login,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _LuxuryLoadingIndicator extends StatelessWidget {
  const _LuxuryLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryGold.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'LOADING...',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: AppTheme.primaryGold.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _GoldButton extends StatefulWidget {
  const _GoldButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<_GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<_GoldButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: isEnabled
                ? AppTheme.subtleGoldGradient
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.white.withValues(alpha: 0.08),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black87),
                        ),
                      )
                    : Text(
                        widget.label.toUpperCase(),
                        style: TextStyle(
                          color: isEnabled ? Colors.black87 : Colors.white30,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
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
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                height: 22,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.login, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryGold.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.1),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 60,
              offset: const Offset(0, 30),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Accent line
            Container(
              width: 36,
              height: 2,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                gradient: AppTheme.subtleGoldGradient,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            ShaderMask(
              shaderCallback: (b) =>
                  AppTheme.subtleGoldGradient.createShader(b),
              child: Text(
                Strings.of(context).termsOfService.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.muted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    Strings.of(context).termsOfServiceContent,
                    style: TextStyle(
                      color: AppTheme.foreground.withValues(alpha: 0.8),
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'J\'ACCEPTE',
                    isPrimary: true,
                    onPressed: onAccept,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'ANNULER',
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
        gradient: isPrimary ? AppTheme.subtleGoldGradient : null,
        color: isPrimary ? null : AppTheme.muted,
        borderRadius: BorderRadius.circular(12),
        border: !isPrimary
            ? Border.all(color: AppTheme.border)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.black87 : AppTheme.foreground,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
