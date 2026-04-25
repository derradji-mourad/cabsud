import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cabsudapp/reuse/theme.dart';
import '../localization/string.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _loadingNotifier = ValueNotifier<bool>(false);
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _loadingNotifier.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  Future<void> _handleEmailLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    _loadingNotifier.value = true;

    try {
      final response = await _supabase.auth
          .signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
          .timeout(const Duration(seconds: 15));

      final session = response.session;
      final user = response.user;

      if (session != null && user != null) {
        final userData = await _supabase
            .from('users')
            .select('id, role')
            .eq('id', user.id)
            .single()
            .timeout(const Duration(seconds: 10));

        if (userData['role'] != 'user') {
          throw Exception('Invalid account type');
        }

        final prefs = await SharedPreferences.getInstance();
        await Future.wait([
          prefs.setString('jwt_token', session.accessToken),
          if (session.refreshToken != null)
            prefs.setString('refresh_token', session.refreshToken!),
          prefs.setString('user_id', user.id),
        ]);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (!mounted) return;
        _showErrorSnackBar(Strings.of(context).loginFailed);
      }
    } on TimeoutException {
      if (!mounted) return;
      _showErrorSnackBar('Connection timed out. Please try again.');
    } catch (error) {
      debugPrint('Login error: $error');
      if (!mounted) return;
      _showErrorSnackBar(Strings.of(context).loginFailed);
    } finally {
      if (mounted) _loadingNotifier.value = false;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: AppTheme.luxuryBackgroundGradient,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
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
          const SizedBox(height: 48),

          // ── Welcome text ─────────────────────────────────────────────────
          _buildWelcomeText(),
          const SizedBox(height: 36),

          // ── Form ─────────────────────────────────────────────────────────
          Form(
            key: _formKey,
            child: Column(
              children: [
                _PremiumTextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  hintText: strings.emailHint,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) return strings.emailRequired;
                    if (!_isValidEmail(value)) return strings.emailInvalid;
                    return null;
                  },
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                _PremiumTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  hintText: strings.passwordHint,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) return strings.passwordRequired;
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleEmailLogin(),
                ),
                const SizedBox(height: 32),

                // ── Login button ──────────────────────────────────────────
                ValueListenableBuilder<bool>(
                  valueListenable: _loadingNotifier,
                  builder: (context, isLoading, _) {
                    return _GoldButton(
                      onPressed: isLoading ? null : _handleEmailLogin,
                      isLoading: isLoading,
                      label: strings.loginButton,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Sign-up prompt ───────────────────────────────────────────────
          _buildSignUpPrompt(strings),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        // Logo with subtle glow
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryGold.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                blurRadius: 32,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipOval(
            child: Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/logo/logo4-.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.directions_car_rounded,
                  size: 40,
                  color: AppTheme.primaryGold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (b) => AppTheme.subtleGoldGradient.createShader(b),
          child: const Text(
            'CABSUD',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'CHAUFFEUR PRIVÉ',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 3.5,
            color: AppTheme.foreground.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bienvenue',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Connectez-vous à votre compte',
          style: TextStyle(
            color: AppTheme.foreground.withValues(alpha: 0.5),
            fontSize: 15,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 20),
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

  Widget _buildSignUpPrompt(Strings strings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          strings.signUpText,
          style: TextStyle(
            color: AppTheme.foreground.withValues(alpha: 0.55),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/signin'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryGold,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            strings.signUpButton,
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

// ─────────────────────────────────────────────────────────────────────────────
//  PREMIUM TEXT FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumTextField extends StatefulWidget {
  const _PremiumTextField({
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.prefixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  late final ValueNotifier<bool> _isFocused;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _isFocused = ValueNotifier(false);
    _obscureText = widget.obscureText;
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    _isFocused.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    _isFocused.value = widget.focusNode?.hasFocus ?? false;
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
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.obscureText && _obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: isFocused
                          ? AppTheme.primaryGold
                          : Colors.white.withValues(alpha: 0.35),
                      size: 20,
                    )
                  : null,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white.withValues(alpha: 0.35),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFE57373),
                fontSize: 12,
              ),
            ),
            validator: widget.validator,
            onFieldSubmitted: widget.onFieldSubmitted,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  GOLD BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _GoldButton extends StatefulWidget {
  const _GoldButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
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
      onTapUp: isEnabled ? (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      } : null,
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
