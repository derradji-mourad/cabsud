import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cabsudapp/commande/trip_summary.dart';
import 'package:cabsudapp/custom_page_route.dart';
import 'package:cabsudapp/reuse/theme.dart';
import 'package:cabsudapp/reuse/form_controller.dart';
import 'package:cabsudapp/reuse/luxury_text_field.dart';
import 'package:cabsudapp/reuse/luxury_dropdown.dart';

class CommandePage extends StatefulWidget {
  final String origin;

  const CommandePage({super.key, required this.origin});

  @override
  State<CommandePage> createState() => _CommandePageState();
}

class _CommandePageState extends State<CommandePage> with SingleTickerProviderStateMixin {
  late final FormController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = FormController();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$",
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleSubmit() async {
    if (!_controller.validate()) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final isCash = _controller.selectedPayment == 'Paiement sur place';
      await prefs.setBool('is_cash', isCash);

      final tripDetails = _controller.getTripDetails(widget.origin);

      if (!mounted) return;

      await Navigator.of(context).push(
        CustomPageRoute(
          child: TripSummaryPage(tripData: tripDetails),
        ),
      );
    } catch (e) {
      _showSnackBar('An error occurred. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: AppTheme.softWhite,  // White text in snackbar
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : AppTheme.primaryGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          // Use the luxury gradient background from theme
          decoration: AppTheme.luxuryBackgroundGradient,
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _controller.formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: AppTheme.spaceM),
                    _buildSectionHeader('Personal Information'),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: AppTheme.spaceL),
                    _buildSectionHeader('Address Details'),
                    _buildAddressSection(),
                    const SizedBox(height: AppTheme.spaceL),
                    _buildSectionHeader('Trip Information'),
                    _buildTripInfoSection(),
                    const SizedBox(height: AppTheme.spaceL),
                    _buildSectionHeader('Payment Method'),
                    _buildPaymentSection(),
                    const SizedBox(height: AppTheme.spaceXL),
                    _buildSubmitButton(),
                    const SizedBox(height: AppTheme.spaceL),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Book Your Ride',
        style: TextStyle(
          color: AppTheme.richBlack,  // Black text on gold gradient
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkGold,
              AppTheme.lightGold,
              AppTheme.accentGold,
              AppTheme.primaryGold,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.richBlack),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Back',
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryGold,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGold.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceS),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.softWhite,  // White text for headers
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: LuxuryTextField(
                label: 'First Name*',
                controller: _controller.firstNameController,
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryGold,  // Gold icons
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: LuxuryTextField(
                label: 'Last Name*',
                controller: _controller.lastNameController,
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryGold,
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ],
        ),
        LuxuryTextField(
          label: 'Company Name (optional)',
          controller: _controller.companyNameController,
          prefixIcon: const Icon(
            Icons.business_outlined,
            color: AppTheme.primaryGold,
          ),
        ),
        LuxuryTextField(
          label: 'Phone*',
          controller: _controller.phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(
            Icons.phone_outlined,
            color: AppTheme.primaryGold,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) =>
          value?.isEmpty ?? true ? 'Required' : null,
        ),
        LuxuryTextField(
          label: 'Email Address*',
          controller: _controller.emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(
            Icons.email_outlined,
            color: AppTheme.primaryGold,
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Required';
            if (!_isValidEmail(value!)) return 'Invalid email';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      children: [
        LuxuryTextField(
          label: 'Country/Region*',
          controller: _controller.countryController,
          prefixIcon: const Icon(
            Icons.public_outlined,
            color: AppTheme.primaryGold,
          ),
          validator: (value) =>
          value?.isEmpty ?? true ? 'Required' : null,
        ),
        LuxuryTextField(
          label: 'Street Address*',
          controller: _controller.addressController,
          prefixIcon: const Icon(
            Icons.home_outlined,
            color: AppTheme.primaryGold,
          ),
          validator: (value) =>
          value?.isEmpty ?? true ? 'Required' : null,
        ),
        Row(
          children: [
            Expanded(
              child: LuxuryTextField(
                label: 'Town/City*',
                controller: _controller.cityController,
                prefixIcon: const Icon(
                  Icons.location_city_outlined,
                  color: AppTheme.primaryGold,
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: LuxuryTextField(
                label: 'Postcode*',
                controller: _controller.postcodeController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(
                  Icons.mail_outline,
                  color: AppTheme.primaryGold,
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ],
        ),
        LuxuryTextField(
          label: 'Additional Information',
          controller: _controller.additionalInfoController,
          maxLines: 3,
          prefixIcon: const Icon(
            Icons.notes_outlined,
            color: AppTheme.primaryGold,
          ),
        ),
      ],
    );
  }

  Widget _buildTripInfoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: LuxuryTextField(
                label: 'Passengers*',
                controller: _controller.passengersController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(
                  Icons.people_outline,
                  color: AppTheme.primaryGold,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: LuxuryTextField(
                label: 'Bags*',
                controller: _controller.bagsController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(
                  Icons.luggage_outlined,
                  color: AppTheme.primaryGold,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ],
        ),
        LuxuryTextField(
          label: 'Extra Information (optional)',
          controller: _controller.extraInfoController,
          maxLines: 3,
          prefixIcon: const Icon(
            Icons.info_outline,
            color: AppTheme.primaryGold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return LuxuryDropdown(
          label: 'Payment Method*',
          value: _controller.selectedPayment,
          items: const [
            DropdownMenuItem(
              value: 'Paiement sur place',
              child: Text(
                'Pay on Arrival',
                style: TextStyle(color: AppTheme.offWhite),  // White text
              ),
            ),
            DropdownMenuItem(
              value: 'Paiement sur l\'application',
              child: Text(
                'Pay via App',
                style: TextStyle(color: AppTheme.offWhite),  // White text
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              _controller.updatePaymentMethod(value);
            }
          },
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Hero(
      tag: 'submit_button',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          gradient: const LinearGradient(
            colors: [AppTheme.primaryGold, AppTheme.accentGold],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.richBlack),
            ),
          )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue to Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.richBlack,  // Black text on gold button
                ),
              ),
              SizedBox(width: AppTheme.spaceS),
              Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: AppTheme.richBlack,  // Black icon on gold button
              ),
            ],
          ),
        ),
      ),
    );
  }
}
