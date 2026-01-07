import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cabsudapp/commande/trip_summary.dart';
import 'package:cabsudapp/custom_page_route.dart';
import 'package:cabsudapp/reuse/theme.dart';
import 'package:cabsudapp/reuse/form_controller.dart';
import 'package:cabsudapp/reuse/luxury_text_field.dart';
import 'package:cabsudapp/reuse/luxury_dropdown.dart';

// Removed _LuxuryColors class as we now use AppTheme

class CommandePage extends StatefulWidget {
  final String origin;

  const CommandePage({super.key, required this.origin});

  @override
  State<CommandePage> createState() => _CommandePageState();
}

class _CommandePageState extends State<CommandePage>
    with SingleTickerProviderStateMixin {
  late final FormController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = FormController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

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
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: AppTheme.softWhite,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppTheme.softWhite,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFD32F2F) : AppTheme.primaryGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildLuxuryAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: AppTheme.luxuryBackgroundGradient,
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _controller.formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceL,
                      vertical: AppTheme.spaceXL,
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildWelcomeHeader(),
                      const SizedBox(height: AppTheme.spaceXL),
                      _buildSectionHeader(
                          'Personal Information', Icons.person_outline),
                      _buildPersonalInfoSection(),
                      const SizedBox(height: AppTheme.spaceXL),
                      _buildSectionHeader(
                          'Address Details', Icons.location_on_outlined),
                      _buildAddressSection(),
                      const SizedBox(height: AppTheme.spaceXL),
                      _buildSectionHeader(
                          'Trip Information', Icons.flight_outlined),
                      _buildTripInfoSection(),
                      const SizedBox(height: AppTheme.spaceXL),
                      _buildSectionHeader(
                          'Payment Method', Icons.payment_outlined),
                      _buildPaymentSection(),
                      const SizedBox(height: AppTheme.spaceXL * 2),
                      _buildSubmitButton(),
                      const SizedBox(height: AppTheme.spaceL),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildLuxuryAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primary),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            AppTheme.secondary,
            AppTheme.primary,
            AppTheme.primary,
          ],
        ).createShader(bounds),
        child: const Text(
          'Book Your Ride',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.background,
              AppTheme.card.withValues(alpha: 0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGold.withValues(alpha: 0.15),
            AppTheme.accentGold.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGold, AppTheme.accentGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: AppTheme.richBlack,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Experience',
                      style: TextStyle(
                        color: AppTheme.softWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Complete your details for a luxury journey',
                      style: TextStyle(
                        color: AppTheme.offWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGold, AppTheme.accentGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGold.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppTheme.richBlack,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.softWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGold, Colors.transparent],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
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
                  color: AppTheme.primaryGold,
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
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        LuxuryTextField(
          label: 'Street Address*',
          controller: _controller.addressController,
          prefixIcon: const Icon(
            Icons.home_outlined,
            color: AppTheme.primaryGold,
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
                style: TextStyle(color: AppTheme.offWhite),
              ),
            ),
            DropdownMenuItem(
              value: 'Paiement sur l\'application',
              child: Text(
                'Pay via App',
                style: TextStyle(color: AppTheme.offWhite),
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
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              AppTheme.darkGold,
              AppTheme.primaryGold,
              AppTheme.accentGold,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: AppTheme.accentGold.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
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
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.richBlack),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: AppTheme.richBlack,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceM),
                    const Text(
                      'Continue to Summary',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.richBlack,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceS),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 22,
                      color: AppTheme.richBlack,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
