import 'package:flutter/material.dart';
import 'package:cabsudapp/commande/type_of_paiment.dart';
import 'package:cabsudapp/commande/succed.dart'; // Add this if not already imported

class CommandePage extends StatelessWidget {
  final String origin; // Accept origin parameter: 'route' or 'distance'

  CommandePage({Key? key, required this.origin}) : super(key: key);

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
              buildTextField(
                label: 'First Name*',
                controller: firstNameController,
                validator: (value) => value == null || value.isEmpty ? 'Please enter your first name' : null,
              ),
              buildTextField(
                label: 'Last Name*',
                controller: lastNameController,
                validator: (value) => value == null || value.isEmpty ? 'Please enter your last name' : null,
              ),
              buildTextField(
                label: 'Company Name (optional)',
                controller: companyNameController,
              ),
              buildTextField(
                label: 'Country/Region*',
                controller: countryController,
                validator: (value) => value == null || value.isEmpty ? 'Please enter your country/region' : null,
              ),
              buildTextField(
                label: 'Street Address*',
                controller: addressController,
                validator: (value) => value == null || value.isEmpty ? 'Please enter your street address' : null,
              ),
              buildTextField(
                label: 'Town/City*',
                controller: cityController,
                validator: (value) => value == null || value.isEmpty ? 'Please enter your town/city' : null,
              ),
              buildTextField(
                label: 'Postcode/ZIP*',
                controller: postcodeController,
                validator: (value) => value == null || value.isEmpty ? 'Please enter your postcode/ZIP' : null,
              ),
              buildTextField(
                label: 'Phone*',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Please enter your phone number' : null,
              ),
              buildTextField(
                label: 'Email Address*',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value == null || value.isEmpty || !value.contains('@') ? 'Please enter a valid email address' : null,
              ),
              buildTextField(
                label: 'Additional Information',
                controller: additionalInfoController,
                maxLines: 3,
              ),
              buildTextField(
                label: 'Nombre de Passager(s)*',
                controller: passengersController,
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Please enter the number of passengers' : null,
              ),
              buildTextField(
                label: 'Nombre de Bagage(s)*',
                controller: bagsController,
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Please enter the number of bags' : null,
              ),
              buildTextField(
                label: 'Information Complémentaire (optional)',
                controller: extraInfoController,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (origin == 'route') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SuccessPage()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TypeOfPaimentPage()),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required fields')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
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
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
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
