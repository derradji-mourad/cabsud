import 'package:cabsudapp/commande/succed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentScreen extends StatefulWidget {
  final String requestId;

  const PaymentScreen({super.key, required this.requestId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  CardFieldInputDetails? _card;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  }

  Future<void> _processStripePayment() async {
    if (_card == null || !_card!.complete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete card details.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final double? price = prefs.getDouble('price');

      if (price == null) {
        throw Exception('Total fare not found in SharedPreferences.');
      }

      final int amountInCents = (price * 100).toInt();

      // WARNING: Using Stripe Secret Key on the client side is insecure.
      // This should be moved to a backend server (e.g., Supabase Edge Functions).
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization':
          'Bearer ${dotenv.env['STRIPE_SECRET_KEY']}',
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

      final data = json.decode(response.body);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful!')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SuccessPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7EF8A), Color(0xFFD2AC47), Color(0xFFEDC967)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: const Text(
        'Stripe Payment',
        style: TextStyle(color: Colors.black), // Black title
      ),
      iconTheme: const IconThemeData(color: Colors.black), // Black icons
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildGradientAppBar(),
      backgroundColor: Colors.black,
      body: Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Email', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'test@example.com',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Card Information',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
              child: CardField(
                onCardChanged: (card) => setState(() => _card = card),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Name on Card', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Zhang San',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : ElevatedButton.icon(
              icon: const Icon(Icons.lock, color: Colors.white),
              label: const Text('Pay', style: TextStyle(color: Colors.white)),
              onPressed: _processStripePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[850],
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
