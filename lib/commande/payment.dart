import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedPaymentMethod = 1; // Default: 1 for online payment

  @override
  void initState() {
    super.initState();

    // Initialize Stripe with your publishable key
    Stripe.publishableKey = 'your-publishable-key'; // Replace with your actual key
  }

  void _processPayment() async {
    if (_selectedPaymentMethod == 1) {
      // Online payment using Stripe
      try {
        // Create PaymentIntent
        final paymentIntent = await createPaymentIntent();

        // Initialize the payment sheet
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntent['client_secret'],
            style: ThemeMode.light,
            merchantDisplayName: 'Your Company',
          ),
        );

        // Display the payment sheet
        await Stripe.instance.presentPaymentSheet();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment successful!')),
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.toString()}')),
        );
      }
    } else if (_selectedPaymentMethod == 2) {
      // Payment onboard logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You selected onboard payment.')),
      );
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent() async {
    // Replace this with your server-side call to create a PaymentIntent
    return {
      'client_secret': 'your-client-secret', // Replace with actual PaymentIntent secret
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Payment Method'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7EF8A), Color(0xFFD2AC47), Color(0xFFEDC967)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
              // Payment Option: Online
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: RadioListTile<int>(
                  value: 1,
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value ?? 1;
                    });
                  },
                  title: Text('Payment Online (Credit Card - Stripe)'),
                  subtitle: Text('Pay securely using your credit card.'),
                ),
              ),
              // Payment Option: Onboard
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: RadioListTile<int>(
                  value: 2,
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value ?? 2;
                    });
                  },
                  title: Text('Payment Onboard'),
                  subtitle: Text('Pay in cash or card during the trip.'),
                ),
              ),
              SizedBox(height: 30),
              // Proceed to Pay button
              Center(
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    'Proceed to Pay',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
