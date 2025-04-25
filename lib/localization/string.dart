import 'package:flutter/cupertino.dart';

import '../localization/strings_en.dart'; // English strings
import '../localization/strings_fr.dart'; // French strings

class Strings {
  static late Map<String, String> _currentStrings;

  // Load strings based on selected language
  static void load(String languageCode) {
    if (languageCode == 'fr') {
      _currentStrings = StringsFr().getStrings();
    } else {
      _currentStrings = StringsEn().getStrings();
    }
  }

  static Strings of(BuildContext context) {
    return Strings();
  }

  // General
  String get appTitle => _currentStrings['appTitle'] ?? '';
  String get descriptionText => _currentStrings['descriptionText'] ?? '';
  String get appTitle2 => _currentStrings['appTitle2'] ?? '';
  String get descriptionText2 => _currentStrings['descriptionText'] ?? '';

  // Intro & Service Screens
  String get airportTransferTitle => _currentStrings['airport_transfer_title'] ?? '';
  String get airportTransferDescription => _currentStrings['airport_transfer_description'] ?? '';
  String get cruiseTransferTitle => _currentStrings['cruiseTransferTitle'] ?? '';
  String get cruiseTransferDescription => _currentStrings['cruiseTransferDescription'] ?? '';
  String get trainTransferTitle => _currentStrings['trainTransferTitle'] ?? '';
  String get trainTransferDescription => _currentStrings['trainTransferDescription'] ?? '';
  String get introTitle5 => _currentStrings['introTitle5'] ?? '';
  String get introDescription5 => _currentStrings['introDescription5'] ?? '';
  String get introTitle6 => _currentStrings['introTitle6'] ?? '';
  String get introDescription6 => _currentStrings['introDescription6'] ?? '';

  // Buttons
  String get skipButton => _currentStrings['skipButton'] ?? '';
  String get nextButton => _currentStrings['nextButton'] ?? '';
  String get getStartedButton => _currentStrings['getStartedButton'] ?? '';
  String get loginButton => _currentStrings['loginButton'] ?? '';
  String get signUpButton => _currentStrings['signUpButton'] ?? '';
  String get googleSignUp => _currentStrings['googleSignUp'] ?? '';
  String get cancel => _currentStrings['cancel'] ?? '';
  String get agree => _currentStrings['agree'] ?? '';

  // Auth
  String get loginTitle => _currentStrings['loginTitle'] ?? '';
  String get signUpText => _currentStrings['signUpText'] ?? '';
  String get alreadyHaveAccount => _currentStrings['alreadyHaveAccount'] ?? '';
  String get login => _currentStrings['login'] ?? '';
  String get signUp => _currentStrings['signUp'] ?? '';

  // Input hints
  String get emailHint => _currentStrings['emailHint'] ?? '';
  String get passwordHint => _currentStrings['passwordHint'] ?? '';
  String get email => _currentStrings['email'] ?? '';
  String get password => _currentStrings['password'] ?? '';
  String get confirmPassword => _currentStrings['confirmPassword'] ?? '';

  // Validation & Errors
  String get loginFailed => _currentStrings['loginFailed'] ?? '';
  String get emailRequired => _currentStrings['emailRequired'] ?? '';
  String get passwordRequired => _currentStrings['passwordRequired'] ?? '';
  String get emailRequired2 => _currentStrings['emailRequired2'] ?? '';
  String get passwordRequired2 => _currentStrings['passwordRequired2'] ?? '';
  String get confirmPasswordRequired => _currentStrings['confirmPasswordRequired'] ?? '';
  String get passwordMismatch => _currentStrings['passwordMismatch'] ?? '';
  String get passwordStrength => _currentStrings['passwordStrength'] ?? '';
  String get emailInvalid => _currentStrings['emailInvalid'] ?? '';
  String get signUpSuccess => _currentStrings['signUpSuccess'] ?? '';
  String get signUpFailed => _currentStrings['signUpFailed'] ?? '';
  String get googleSignInFailed => _currentStrings['googleSignInFailed'] ?? '';

  // Legal
  String get termsOfService => _currentStrings['termsOfService'] ?? '';
  String get termsOfServiceContent => _currentStrings['termsOfServiceContent'] ?? '';

  // === Services Screen ===
  String get servicesTitle => _currentStrings['servicesTitle']!;
  String get chauffeurTitle => _currentStrings['chauffeurTitle']!;
  String get chauffeurDesc => _currentStrings['chauffeurDesc']!;
  String get prixFixesTitle => _currentStrings['prixFixesTitle']!;
  String get prixFixesDesc => _currentStrings['prixFixesDesc']!;
  String get vehiculesTitle => _currentStrings['vehiculesTitle']!;
  String get vehiculesDesc => _currentStrings['vehiculesDesc']!;
  String get wifiTitle => _currentStrings['wifiTitle']!;
  String get wifiDesc => _currentStrings['wifiDesc']!;
  String get enfantsTitle => _currentStrings['enfantsTitle']!;
  String get enfantsDesc => _currentStrings['enfantsDesc']!;
  String get paiementTitle => _currentStrings['paiementTitle']!;
  String get paiementDesc => _currentStrings['paiementDesc']!;
  String get paiementSecuTitle => _currentStrings['paiementSecuTitle']!;
  String get paiementSecuDesc => _currentStrings['paiementSecuDesc']!;
  String get gotoHomeBtn => _currentStrings['gotoHomeBtn']!;

  String get contactTitle => _currentStrings['contactTitle'] ?? '';
  String get contactSubtitle => _currentStrings['contactSubtitle'] ?? '';
  String get fullNameLabel => _currentStrings['fullNameLabel'] ?? '';
  String get fullNameHint => _currentStrings['fullNameHint'] ?? '';
  String get phoneLabel => _currentStrings['phoneLabel'] ?? '';
  String get phoneHint => _currentStrings['phoneHint'] ?? '';
  String get emailLabel => _currentStrings['emailLabel'] ?? '';
  String get emailHint2 => _currentStrings['emailHint2'] ?? '';
  String get submitButton => _currentStrings['submitButton'] ?? '';
  String get successMessage => _currentStrings['successMessage'] ?? '';
  String get nameValidation => _currentStrings['nameValidation'] ?? '';
  String get phoneValidation => _currentStrings['phoneValidation'] ?? '';
  String get emailValidation => _currentStrings['emailValidation'] ?? '';
  String get emailFormatValidation => _currentStrings['emailFormatValidation'] ?? '';

  String get vehicleSelectionTitle => _currentStrings['vehicleSelectionTitle'] ?? '';
  String get vehicleTypeEco => _currentStrings['vehicleTypeEco'] ?? '';
  String get vehicleTypeBerline => _currentStrings['vehicleTypeBerline'] ?? '';
  String get vehicleTypeVan => _currentStrings['vehicleTypeVan'] ?? '';
  String get vehicleDescEco => _currentStrings['vehicleDescEco'] ?? '';
  String get vehicleDescBerline => _currentStrings['vehicleDescBerline'] ?? '';
  String get vehicleDescVan => _currentStrings['vehicleDescVan'] ?? '';
  String get vehiclePassengers => _currentStrings['vehiclePassengers'] ?? '';
  String get vehicleBags => _currentStrings['vehicleBags'] ?? '';
  String get vehiclePrice => _currentStrings['vehiclePrice'] ?? '';
  String get vehicleFixedPrice => _currentStrings['vehicleFixedPrice'] ?? '';
  String get continueButton => _currentStrings['continueButton'] ?? '';

  String get appointmentTitle => _currentStrings['appointmentTitle'] ?? '';
  String get appointmentSubtitle => _currentStrings['appointmentSubtitle'] ?? '';
  String get selectDate => _currentStrings['selectDate'] ?? '';
  String get selectTime => _currentStrings['selectTime'] ?? '';
  String get confirmAppointment => _currentStrings['confirmAppointment'] ?? '';
  String get appointmentSuccess => _currentStrings['appointmentSuccess'] ?? '';
  String get appointmentError => _currentStrings['appointmentError'] ?? '';
  String get dateRequired => _currentStrings['dateRequired'] ?? '';
  String get timeRequired => _currentStrings['timeRequired'] ?? '';

  String get faireUneCommande => _currentStrings['faireUneCommande'] ?? '';
  String get miseADisposition => _currentStrings['miseADisposition'] ?? '';
  String get nosServices => _currentStrings['nosServices'] ?? '';
  String get home => _currentStrings['home'] ?? '';
  String get contact => _currentStrings['contact'] ?? '';
  String get settings => _currentStrings['settings'] ?? '';
  String get adresseDePickup => _currentStrings['adresseDePickup'] ?? '';
  String get adresseDeDestination => _currentStrings['adresseDeDestination'] ?? '';
  String get distance => _currentStrings['distance'] ?? '';
  String get duree => _currentStrings['duree'] ?? '';
  String get saisissezVotreAdresse => _currentStrings['saisissezVotreAdresse'] ?? '';
  String get calculerLaDistance => _currentStrings['calculerLaDistance'] ?? '';

  String get accueil => _currentStrings['accueil'] ?? '';
  String get contact1 => _currentStrings['contact'] ?? '';
  String get parametres => _currentStrings['parametres'] ?? '';
  String get faireUneCommande1 => _currentStrings['faireUneCommande'] ?? '';
  String get miseADisposition1 => _currentStrings['miseADisposition'] ?? '';
  String get nosServices1 => _currentStrings['nosServices'] ?? '';

  String get nosServices2 => _currentStrings['nosServices'] ?? '';
  String get selectService => _currentStrings['selectService'] ?? '';
  String get airportTransport => _currentStrings['airportTransport'] ?? '';
  String get cruiseTransport => _currentStrings['cruiseTransport'] ?? '';
  String get trainStationTransport => _currentStrings['trainStationTransport'] ?? '';
  String get carAtDisposal => _currentStrings['carAtDisposal'] ?? '';
  String get tourism => _currentStrings['tourism'] ?? '';
  String get selected => _currentStrings['selected'] ?? '';
  String get continueButton1 => _currentStrings['continueButton'] ?? '';

  String get infoTitle => _currentStrings['infoTitle'] ?? '';
  String get infoDescription => _currentStrings['infoDescription'] ?? '';
  String get understood => _currentStrings['understood'] ?? '';
  String get planJourney => _currentStrings['planJourney'] ?? '';
  String get departureAddress => _currentStrings['departureAddress'] ?? '';
  String get durationLabel => _currentStrings['durationLabel'] ?? '';
  String get hour => _currentStrings['hour'] ?? '';
  String get hours => _currentStrings['hours'] ?? '';
  String get continueButton2 => _currentStrings['continue'] ?? '';

  String get commandSuccessMessage => _currentStrings['commandSuccessMessage'] ?? '';
  String get backToHome => _currentStrings['backToHome'] ?? '';


}
