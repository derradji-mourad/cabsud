import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cabsudapp/reuse/theme.dart';
import '../localization/string.dart';

const String _whatsAppNumber = '33652384770';

/// Ultra-premium contact page with smooth animations and luxury design
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  ContactPageState createState() => ContactPageState();
}

class ContactPageState extends State<ContactPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLanguageLoaded = false;
  bool _isSending = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _loadLanguage();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? selectedLanguage = prefs.getString('language') ?? 'fr';
    await prefs.setString('language', selectedLanguage);
    Strings.load(selectedLanguage);

    if (mounted) {
      setState(() => _isLanguageLoaded = true);
      _animController.forward();
    }
  }

  Future<void> _sendEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final message = _messageController.text.trim();

    const resendApiKey = 're_QugU9YR4_HipbLA7qUKDMBZgpW8GFYSP9';
    const resendEndpoint = 'https://api.resend.com/emails';

    final emailBody = '''
New contact message from CABSUD app:

Name: $name
Phone: $phone
Email: $email

Message:
$message
''';

    try {
      final response = await http.post(
        Uri.parse(resendEndpoint),
        headers: {
          'Authorization': 'Bearer $resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "from": "CABSUD Contact <onboarding@resend.dev>",
          "to": ["cabsudderradji@gmail.com"],
          "subject": "New Contact from CABSUD App",
          "text": emailBody,
        }),
      );

      if (mounted) {
        setState(() => _isSending = false);

        if (response.statusCode == 200 || response.statusCode == 201) {
          HapticFeedback.heavyImpact();
          _showSuccessDialog();
          _formKey.currentState?.reset();
          _nameController.clear();
          _phoneController.clear();
          _emailController.clear();
          _messageController.clear();
        } else {
          _showErrorSnackbar('Failed to send message. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _showErrorSnackbar('Network error. Please check your connection.');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGold, AppTheme.accentGold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.richBlack.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: AppTheme.richBlack,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                Strings.of(context).emailSentSuccess,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.richBlack,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We\'ll get back to you soon!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.richBlack,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.richBlack,
                    foregroundColor: AppTheme.primaryGold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'GOT IT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse('https://wa.me/$_whatsAppNumber');
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showErrorSnackbar('Could not open WhatsApp.');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLanguageLoaded) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.luxuryBackgroundGradient,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: AppTheme.luxuryBackgroundGradient,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _ContactHeader(
                    title: Strings.of(context).contactTitle,
                    subtitle: Strings.of(context).contactSubtitle,
                  )),
                  // Form
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildLuxuryField(
                              controller: _nameController,
                              label: Strings.of(context).fullNameLabel,
                              hint: Strings.of(context).fullNameHint,
                              icon: Icons.person_rounded,
                              delay: 0,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? Strings.of(context).nameValidation
                                      : null,
                            ),
                            const SizedBox(height: 20),
                            _buildLuxuryField(
                              controller: _phoneController,
                              label: Strings.of(context).phoneLabel,
                              hint: Strings.of(context).phoneHint,
                              icon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              delay: 100,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? Strings.of(context).phoneValidation
                                      : null,
                            ),
                            const SizedBox(height: 20),
                            _buildLuxuryField(
                              controller: _emailController,
                              label: Strings.of(context).emailLabel,
                              hint: Strings.of(context).emailHint2,
                              icon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              delay: 200,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return Strings.of(context).emailValidation;
                                }
                                if (!RegExp(
                                        r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$")
                                    .hasMatch(value)) {
                                  return Strings.of(context)
                                      .emailFormatValidation;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildLuxuryField(
                              controller: _messageController,
                              label: Strings.of(context).messageLabel,
                              hint: Strings.of(context).messageHint,
                              icon: Icons.message_rounded,
                              keyboardType: TextInputType.multiline,
                              maxLines: 5,
                              delay: 300,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? Strings.of(context).messageValidation
                                      : null,
                            ),
                            const SizedBox(height: 32),
                            _SubmitButton(
                              isSending: _isSending,
                              onSend: _sendEmail,
                              buttonText: Strings.of(context).submitButton,
                            ),
                            const SizedBox(height: 20),
                            _WhatsAppButton(onTap: _openWhatsApp),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildLuxuryField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppTheme.charcoal.withValues(alpha: 0.6),
              AppTheme.deepCharcoal.withValues(alpha: 0.4),
            ],
          ),
          border: Border.all(
            color: AppTheme.primaryGold.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          style: const TextStyle(
            color: AppTheme.softWhite,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          cursorColor: AppTheme.primaryGold,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: AppTheme.offWhite.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            floatingLabelStyle: const TextStyle(
              color: AppTheme.primaryGold,
              fontWeight: FontWeight.w600,
            ),
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTheme.offWhite.withValues(alpha: 0.4),
              fontSize: 15,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                icon,
                color: AppTheme.primaryGold,
                size: 24,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
          validator: validator,
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────
//  EXTRACTED WIDGETS
// ─────────────────────────────────────────────────────────────

class _ContactHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ContactHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGold, AppTheme.accentGold],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGold.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.mail_rounded,
              size: 40,
              color: AppTheme.richBlack,
            ),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.lightGold, AppTheme.primaryGold],
            ).createShader(bounds),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.offWhite.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WhatsAppButton({required this.onTap});

  static const Color _whatsAppGreen = Color(0xFF25D366);
  static const Color _whatsAppDarkGreen = Color(0xFF128C7E);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [_whatsAppGreen, _whatsAppDarkGreen],
        ),
        boxShadow: [
          BoxShadow(
            color: _whatsAppGreen.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'WHATSAPP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSending;
  final VoidCallback onSend;
  final String buttonText;
  const _SubmitButton({
    required this.isSending,
    required this.onSend,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: child,
          ),
        );
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [AppTheme.primaryGold, AppTheme.accentGold],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSending ? null : onSend,
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: isSending
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.richBlack,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'SENDING...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.richBlack,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.send_rounded,
                          color: AppTheme.richBlack,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          buttonText.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.richBlack,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
