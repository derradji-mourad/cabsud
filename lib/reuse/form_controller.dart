import 'package:flutter/material.dart';

class FormController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

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
  final passengersController = TextEditingController();
  final bagsController = TextEditingController();
  final extraInfoController = TextEditingController();

  String _selectedPayment = 'Paiement sur place';
  String get selectedPayment => _selectedPayment;

  void updatePaymentMethod(String value) {
    _selectedPayment = value;
    notifyListeners();
  }

  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  Map<String, dynamic> getTripDetails(String origin) {
    return {
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'companyName': companyNameController.text,
      'region': countryController.text,
      'address': addressController.text,
      'city': cityController.text,
      'zipcode': postcodeController.text,
      'phone': phoneController.text,
      'email': emailController.text,
      'additionalInfo': additionalInfoController.text,
      'passengers': passengersController.text,
      'bags': bagsController.text,
      'extraInfo': extraInfoController.text,
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
    passengersController.dispose();
    bagsController.dispose();
    extraInfoController.dispose();
    super.dispose();
  }
}
