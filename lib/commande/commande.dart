import 'package:flutter/material.dart';

class CommandePage extends StatelessWidget {
  CommandePage({Key? key}) : super(key: key);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController postcodeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController additionalInfoController = TextEditingController();
  final TextEditingController passengersController = TextEditingController();
  final TextEditingController bagsController = TextEditingController();
  final TextEditingController extraInfoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commande'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // First Name
              buildTextField(
                label: 'First Name*',
                controller: firstNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              // Last Name
              buildTextField(
                label: 'Last Name*',
                controller: lastNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              // Company Name (optional)
              buildTextField(
                label: 'Company Name (optional)',
                controller: companyNameController,
              ),
              // Country/Region
              buildTextField(
                label: 'Country/Region*',
                controller: countryController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your country/region';
                  }
                  return null;
                },
              ),
              // Street Address
              buildTextField(
                label: 'Street Address*',
                controller: addressController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your street address';
                  }
                  return null;
                },
              ),
              // Town/City
              buildTextField(
                label: 'Town/City*',
                controller: cityController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your town/city';
                  }
                  return null;
                },
              ),
              // Postcode/ZIP
              buildTextField(
                label: 'Postcode/ZIP*',
                controller: postcodeController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your postcode/ZIP';
                  }
                  return null;
                },
              ),
              // Phone
              buildTextField(
                label: 'Phone*',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              // Email Address
              buildTextField(
                label: 'Email Address*',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              // Additional Information
              buildTextField(
                label: 'Additional Information',
                controller: additionalInfoController,
                maxLines: 3,
              ),
              // Number of Passengers
              buildTextField(
                label: 'Nombre de Passager(s)*',
                controller: passengersController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of passengers';
                  }
                  return null;
                },
              ),
              // Number of Bags
              buildTextField(
                label: 'Nombre de Bagage(s)*',
                controller: bagsController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of bags';
                  }
                  return null;
                },
              ),
              // Extra Information (optional)
              buildTextField(
                label: 'Information Complémentaire (optional)',
                controller: extraInfoController,
                maxLines: 3,
              ),
              // Submit Button
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Handle form submission
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Commande Submitted!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFFD4AF37), width: 2), // Gold border
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build TextFields
  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5), // Gold border
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2), // Gold border
            borderRadius: BorderRadius.circular(8),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
