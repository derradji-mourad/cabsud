import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cabsudapp/commande/trip_summary.dart';
import 'package:cabsudapp/custom_page_route.dart';
import 'package:cabsudapp/reuse/theme.dart';
import 'package:cabsudapp/reuse/form_controller.dart';
import 'package:cabsudapp/reuse/luxury_text_field.dart';

/// Three-step booking form.
///
/// Passengers/bags are intentionally not collected here — they are already
/// chosen on the vehicle selection screen and persisted to SharedPreferences;
/// TripSummaryPage reads them from prefs as a fallback.
class CommandePage extends StatefulWidget {
  final String origin;

  const CommandePage({super.key, required this.origin});

  @override
  State<CommandePage> createState() => _CommandePageState();
}

class _CommandePageState extends State<CommandePage>
    with SingleTickerProviderStateMixin {
  static const int _totalSteps = 3;
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$",
  );

  late final FormController _controller;
  late final PageController _pageController;
  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = FormController();
    _pageController = PageController();
    _controller.prefillFromPrefs().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _controller.validateContact();
      case 1:
        return _controller.validateAddress();
      case 2:
        return _controller.validatePayment();
      default:
        return false;
    }
  }

  void _goNext() {
    FocusScope.of(context).unfocus();
    if (!_validateCurrentStep()) {
      HapticFeedback.heavyImpact();
      _showSnackBar('Please complete the required fields', isError: true);
      return;
    }
    HapticFeedback.lightImpact();
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _handleSubmit();
    }
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final isCash = _controller.selectedPayment == 'Paiement sur place';
      await prefs.setBool('is_cash', isCash);
      await _controller.persistToPrefs();

      final tripDetails = _controller.getTripDetails(widget.origin);

      if (!mounted) return;

      await Navigator.of(context).push(
        CustomPageRoute(child: TripSummaryPage(tripData: tripDetails)),
      );
    } catch (_) {
      _showSnackBar('An error occurred. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

  // ─── BUILD ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _LuxuryAppBar(
        title: 'Book Your Ride',
        onBack: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: AppTheme.luxuryBackgroundGradient,
          child: SafeArea(
            child: Column(
              children: [
                _StepProgressBar(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  labels: const ['Contact', 'Address', 'Payment'],
                ),
                Expanded(
                  child: AutofillGroup(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ContactStep(controller: _controller),
                        _AddressStep(controller: _controller),
                        _PaymentStep(controller: _controller),
                      ],
                    ),
                  ),
                ),
                _StepNavBar(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  isSubmitting: _isSubmitting,
                  onBack: _goBack,
                  onNext: _goNext,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  STEP 1 — CONTACT
// ═════════════════════════════════════════════════════════════════════════

class _ContactStep extends StatelessWidget {
  final FormController controller;
  const _ContactStep({required this.controller});

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!_CommandePageState._emailRegex.hasMatch(v.trim())) {
      return 'Invalid email';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.contactFormKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceL,
          AppTheme.spaceL,
          AppTheme.spaceL,
          AppTheme.spaceXL,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          const _StepHeader(
            icon: Icons.person_outline_rounded,
            title: 'Who is travelling?',
            subtitle: 'Your contact details for the driver',
          ),
          const SizedBox(height: AppTheme.spaceL),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LuxuryTextField(
                  label: 'First name',
                  controller: controller.firstNameController,
                  focusNode: controller.firstNameFocus,
                  autofillHints: const [AutofillHints.givenName],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      controller.lastNameFocus.requestFocus(),
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppTheme.primaryGold),
                  validator: _requiredValidator,
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: LuxuryTextField(
                  label: 'Last name',
                  controller: controller.lastNameController,
                  focusNode: controller.lastNameFocus,
                  autofillHints: const [AutofillHints.familyName],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      controller.phoneFocus.requestFocus(),
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppTheme.primaryGold),
                  validator: _requiredValidator,
                ),
              ),
            ],
          ),
          LuxuryTextField(
            label: 'Phone',
            hintText: '+33 6 12 34 56 78',
            controller: controller.phoneController,
            focusNode: controller.phoneFocus,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
            ],
            onFieldSubmitted: (_) => controller.emailFocus.requestFocus(),
            prefixIcon:
                const Icon(Icons.phone_outlined, color: AppTheme.primaryGold),
            validator: _requiredValidator,
          ),
          LuxuryTextField(
            label: 'Email',
            hintText: 'you@example.com',
            controller: controller.emailController,
            focusNode: controller.emailFocus,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => controller.companyFocus.requestFocus(),
            prefixIcon:
                const Icon(Icons.email_outlined, color: AppTheme.primaryGold),
            validator: _emailValidator,
          ),
          LuxuryTextField(
            label: 'Company (optional)',
            controller: controller.companyNameController,
            focusNode: controller.companyFocus,
            autofillHints: const [AutofillHints.organizationName],
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.business_outlined,
                color: AppTheme.primaryGold),
          ),
          const _StepHint(
            text:
                'We only use these details to confirm your booking and contact your driver.',
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  STEP 2 — ADDRESS
// ═════════════════════════════════════════════════════════════════════════

class _AddressStep extends StatelessWidget {
  final FormController controller;
  const _AddressStep({required this.controller});

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.addressFormKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceL,
          AppTheme.spaceL,
          AppTheme.spaceL,
          AppTheme.spaceXL,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          const _StepHeader(
            icon: Icons.location_on_outlined,
            title: 'Billing address',
            subtitle: 'Where should we send your invoice?',
          ),
          const SizedBox(height: AppTheme.spaceL),
          LuxuryTextField(
            label: 'Country / Region',
            hintText: 'France',
            controller: controller.countryController,
            focusNode: controller.countryFocus,
            autofillHints: const [AutofillHints.countryName],
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => controller.addressFocus.requestFocus(),
            prefixIcon:
                const Icon(Icons.public_outlined, color: AppTheme.primaryGold),
            validator: _requiredValidator,
          ),
          LuxuryTextField(
            label: 'Street address',
            controller: controller.addressController,
            focusNode: controller.addressFocus,
            autofillHints: const [AutofillHints.streetAddressLine1],
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => controller.cityFocus.requestFocus(),
            prefixIcon:
                const Icon(Icons.home_outlined, color: AppTheme.primaryGold),
            validator: _requiredValidator,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: LuxuryTextField(
                  label: 'City',
                  controller: controller.cityController,
                  focusNode: controller.cityFocus,
                  autofillHints: const [AutofillHints.addressCity],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      controller.postcodeFocus.requestFocus(),
                  prefixIcon: const Icon(Icons.location_city_outlined,
                      color: AppTheme.primaryGold),
                  validator: _requiredValidator,
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                flex: 2,
                child: LuxuryTextField(
                  label: 'Postcode',
                  controller: controller.postcodeController,
                  focusNode: controller.postcodeFocus,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.postalCode],
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onFieldSubmitted: (_) =>
                      controller.additionalInfoFocus.requestFocus(),
                  prefixIcon: const Icon(Icons.mail_outline,
                      color: AppTheme.primaryGold),
                  validator: _requiredValidator,
                ),
              ),
            ],
          ),
          LuxuryTextField(
            label: 'Delivery notes (optional)',
            hintText: 'Building, floor, gate code...',
            controller: controller.additionalInfoController,
            focusNode: controller.additionalInfoFocus,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            prefixIcon:
                const Icon(Icons.notes_outlined, color: AppTheme.primaryGold),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  STEP 3 — PAYMENT
// ═════════════════════════════════════════════════════════════════════════

class _PaymentStep extends StatelessWidget {
  final FormController controller;
  const _PaymentStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.paymentFormKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceL,
          AppTheme.spaceL,
          AppTheme.spaceL,
          AppTheme.spaceXL,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          const _StepHeader(
            icon: Icons.payment_outlined,
            title: 'Payment method',
            subtitle: 'Choose how you want to pay',
          ),
          const SizedBox(height: AppTheme.spaceL),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return Column(
                children: [
                  _PaymentOptionTile(
                    icon: Icons.phone_iphone_rounded,
                    title: 'Pay in the app',
                    subtitle: 'Secure card payment powered by Stripe',
                    selected: controller.selectedPayment ==
                        "Paiement sur l'application",
                    onTap: () => controller
                        .updatePaymentMethod("Paiement sur l'application"),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _PaymentOptionTile(
                    icon: Icons.payments_outlined,
                    title: 'Pay on arrival',
                    subtitle: 'Cash or card directly with your driver',
                    selected:
                        controller.selectedPayment == 'Paiement sur place',
                    onTap: () =>
                        controller.updatePaymentMethod('Paiement sur place'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.spaceL),
          LuxuryTextField(
            label: 'Anything else we should know? (optional)',
            hintText: 'Flight number, luggage, child seat...',
            controller: controller.extraInfoController,
            focusNode: controller.extraInfoFocus,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            prefixIcon:
                const Icon(Icons.info_outline, color: AppTheme.primaryGold),
          ),
          const _StepHint(
            text:
                'You can review the full price and details on the next screen before confirming.',
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════

class _LuxuryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;
  const _LuxuryAppBar({required this.title, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primary),
        onPressed: onBack,
      ),
      title: ShaderMask(
        shaderCallback: (bounds) =>
            AppTheme.subtleGoldGradient.createShader(bounds),
        child: Text(
          title,
          style: const TextStyle(
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
        ),
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;
  const _StepProgressBar({
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceL,
        AppTheme.spaceM,
        AppTheme.spaceL,
        AppTheme.spaceS,
      ),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          final isLast = i == totalSteps - 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : AppTheme.spaceS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: (isActive || isDone)
                          ? const LinearGradient(colors: [
                              AppTheme.secondary,
                              AppTheme.primary,
                            ])
                          : null,
                      color: (isActive || isDone)
                          ? null
                          : AppTheme.primaryGold.withValues(alpha: 0.15),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryGold
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${i + 1}. ${labels[i]}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppTheme.primaryGold
                          : (isDone
                              ? AppTheme.softWhite.withValues(alpha: 0.85)
                              : AppTheme.offWhite.withValues(alpha: 0.45)),
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGold, AppTheme.accentGold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.richBlack, size: 22),
        ),
        const SizedBox(width: AppTheme.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.softWhite,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.offWhite.withValues(alpha: 0.7),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepHint extends StatelessWidget {
  final String text;
  const _StepHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spaceS),
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppTheme.primaryGold,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppTheme.offWhite.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryGold.withValues(alpha: 0.18),
                    AppTheme.accentGold.withValues(alpha: 0.08),
                  ],
                )
              : null,
          color: selected ? null : AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTheme.primaryGold
                : AppTheme.primaryGold.withValues(alpha: 0.15),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGold.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryGold.withValues(alpha: 0.2)
                    : AppTheme.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryGold, size: 22),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.softWhite,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.offWhite.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppTheme.primaryGold : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppTheme.primaryGold
                      : AppTheme.offWhite.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check,
                      size: 14, color: AppTheme.richBlack)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepNavBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _StepNavBar({
    required this.currentStep,
    required this.totalSteps,
    required this.isSubmitting,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceL,
        AppTheme.spaceS,
        AppTheme.spaceL,
        AppTheme.spaceL,
      ),
      child: Row(
        children: [
          _SecondaryButton(
            icon: Icons.arrow_back_ios_new_rounded,
            label: currentStep == 0 ? 'Cancel' : 'Back',
            onPressed: isSubmitting ? null : onBack,
          ),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: _PrimaryButton(
              label: isLast ? 'Continue to summary' : 'Next',
              icon: isLast
                  ? Icons.check_circle_outline_rounded
                  : Icons.arrow_forward_rounded,
              isLoading: isSubmitting,
              onPressed: isSubmitting ? null : onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryGold.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryGold),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.softWhite,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
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
              color: AppTheme.primaryGold.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.richBlack),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.richBlack,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(icon, size: 20, color: AppTheme.richBlack),
                  ],
                ),
        ),
      ),
    );
  }
}
