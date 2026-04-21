import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for the booking form. Holds text controllers + focus nodes,
/// exposes per-step validation so the UI can gate progress to the next step,
/// and (optionally) prefills values the user entered in a previous session.
class FormController extends ChangeNotifier {
  // One FormState per step, so each step can be validated in isolation.
  final contactFormKey = GlobalKey<FormState>();
  final addressFormKey = GlobalKey<FormState>();
  final paymentFormKey = GlobalKey<FormState>();

  // Text controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final companyNameController = TextEditingController();
  final countryController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final postcodeController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final additionalInfoController = TextEditingController();
  final extraInfoController = TextEditingController();

  // Focus nodes — let the keyboard "next" button advance the user.
  final firstNameFocus = FocusNode();
  final lastNameFocus = FocusNode();
  final companyFocus = FocusNode();
  final phoneFocus = FocusNode();
  final emailFocus = FocusNode();
  final countryFocus = FocusNode();
  final addressFocus = FocusNode();
  final cityFocus = FocusNode();
  final postcodeFocus = FocusNode();
  final additionalInfoFocus = FocusNode();
  final extraInfoFocus = FocusNode();

  String _selectedPayment = 'Paiement sur place';
  String get selectedPayment => _selectedPayment;

  void updatePaymentMethod(String value) {
    _selectedPayment = value;
    notifyListeners();
  }

  bool validateContact() => contactFormKey.currentState?.validate() ?? false;
  bool validateAddress() => addressFormKey.currentState?.validate() ?? false;
  bool validatePayment() => paymentFormKey.currentState?.validate() ?? true;

  /// Prefill fields from any previously saved values so returning customers
  /// don't retype the same info.
  Future<void> prefillFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    firstNameController.text = prefs.getString('firstName') ?? '';
    lastNameController.text = prefs.getString('lastName') ?? '';
    companyNameController.text = prefs.getString('companyName') ?? '';
    phoneController.text = prefs.getString('phone') ?? '';
    emailController.text = prefs.getString('email') ?? '';
    countryController.text = prefs.getString('region') ?? '';
    addressController.text = prefs.getString('address') ?? '';
    cityController.text = prefs.getString('city') ?? '';
    postcodeController.text = prefs.getString('zipcode') ?? '';
  }

  /// Persist contact/address fields so the next booking prefills them.
  Future<void> persistToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', firstNameController.text);
    await prefs.setString('lastName', lastNameController.text);
    await prefs.setString('companyName', companyNameController.text);
    await prefs.setString('phone', phoneController.text);
    await prefs.setString('email', emailController.text);
    await prefs.setString('region', countryController.text);
    await prefs.setString('address', addressController.text);
    await prefs.setString('city', cityController.text);
    await prefs.setString('zipcode', postcodeController.text);
  }

  Map<String, dynamic> getTripDetails(String origin) {
    return {
      'firstName': firstNameController.text.trim(),
      'lastName': lastNameController.text.trim(),
      'companyName': companyNameController.text.trim(),
      'region': countryController.text.trim(),
      'address': addressController.text.trim(),
      'city': cityController.text.trim(),
      'zipcode': postcodeController.text.trim(),
      'phone': phoneController.text.trim(),
      'email': emailController.text.trim(),
      'additionalInfo': additionalInfoController.text.trim(),
      'extraInfo': extraInfoController.text.trim(),
      'origin': origin,
      'is_cash': _selectedPayment == 'Paiement sur place',
    };
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    companyNameController.dispose();
    countryController.dispose();
    addressController.dispose();
    cityController.dispose();
    postcodeController.dispose();
    phoneController.dispose();
    emailController.dispose();
    additionalInfoController.dispose();
    extraInfoController.dispose();

    firstNameFocus.dispose();
    lastNameFocus.dispose();
    companyFocus.dispose();
    phoneFocus.dispose();
    emailFocus.dispose();
    countryFocus.dispose();
    addressFocus.dispose();
    cityFocus.dispose();
    postcodeFocus.dispose();
    additionalInfoFocus.dispose();
    extraInfoFocus.dispose();
    super.dispose();
  }
}
