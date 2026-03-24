import 'package:cabsudapp/commande/succed.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:cabsudapp/reuse/isolate_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cabsudapp/reuse/theme.dart';

class PaymentScreen extends StatefulWidget {
  final String requestId;

  const PaymentScreen({super.key, required this.requestId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  CardFieldInputDetails? _card;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  double? _price;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    _loadPrice();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPrice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _price = prefs.getDouble('price');
    });
  }

  Future<void> _processStripePayment() async {
    if (_card == null || !_card!.complete) {
      _showSnackBar('Please enter complete card details.', isError: true);
      return;
    }

    if (_emailController.text.isEmpty || _nameController.text.isEmpty) {
      _showSnackBar('Please fill in all fields.', isError: true);
      return;
    }

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    try {
      final prefs = await SharedPreferences.getInstance();
      final double? price = prefs.getDouble('price');

      if (price == null) {
        throw Exception('Total fare not found.');
      }

      final int amountInCents = (price * 100).toInt();

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['STRIPE_SECRET_KEY']}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amountInCents.toString(),
          'currency': 'eur',
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create PaymentIntent.');
      }

      final data = await parseJsonMap(response.body);
      final clientSecret = data['client_secret'];

      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              email: _emailController.text,
              name: _nameController.text,
            ),
          ),
        ),
      );

      if (!mounted) return;
      HapticFeedback.heavyImpact();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SuccessPage()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Payment failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.primaryGold,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              AppTheme.lightGold,
              AppTheme.primaryGold,
              AppTheme.accentGold,
            ],
          ).createShader(bounds),
          child: const Text(
            'Secure Payment',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.luxuryBackgroundGradient,
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AmountCard(price: _price),
                  const SizedBox(height: 24),
                  _buildPaymentForm(),
                  const SizedBox(height: 32),
                  _buildPayButton(),
                  const SizedBox(height: 24),
                  const _SecurityBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      decoration: AppTheme.premiumCardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Email Address', icon: Icons.email_outlined),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailController,
            hint: 'your@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Card Details', icon: Icons.credit_card_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.deepCharcoal,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryGold.withValues(alpha: 0.3),
              ),
            ),
            child: Theme(
              data: ThemeData(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.primaryGold,
                  onSurface: AppTheme.softWhite,
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  border: InputBorder.none,
                ),
              ),
              child: CardField(
                onCardChanged: (card) => setState(() => _card = card),
                style: const TextStyle(
                  color: AppTheme.softWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: AppTheme.primaryGold,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Cardholder Name', icon: Icons.person_outline),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _nameController,
            hint: 'John Doe',
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: AppTheme.softWhite,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppTheme.offWhite.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: AppTheme.deepCharcoal,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.primaryGold.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.primaryGold.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.primaryGold,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return GestureDetector(
      onTap: _loading ? null : _processStripePayment,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _loading
              ? LinearGradient(
                  colors: [Colors.grey.shade700, Colors.grey.shade600],
                )
              : AppTheme.primaryGoldGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _loading
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryGold.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else ...[
              const Icon(
                Icons.lock_rounded,
                color: AppTheme.richBlack,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Pay €${_price?.toStringAsFixed(2) ?? '...'}',
                style: const TextStyle(
                  color: AppTheme.richBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EXTRACTED WIDGETS
// ─────────────────────────────────────────────────────────────

class _AmountCard extends StatelessWidget {
  final double? price;
  const _AmountCard({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGoldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              color: AppTheme.richBlack,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            price != null ? '€${price!.toStringAsFixed(2)}' : '...',
            style: const TextStyle(
              color: AppTheme.richBlack,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.softWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: AppTheme.primaryGold.withValues(alpha: 0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Secured by Stripe',
            style: TextStyle(
              color: AppTheme.offWhite.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
