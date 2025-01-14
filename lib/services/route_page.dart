import 'package:flutter/material.dart';
import 'package:cabsudapp/services/services_type_page.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  _RoutePageState createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Estimation'),
        backgroundColor: Colors.black,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SimpleInterface(),
      ),
      backgroundColor: Colors.black,
    );
  }
}

class SimpleInterface extends StatefulWidget {
  const SimpleInterface({super.key});

  @override
  _SimpleInterfaceState createState() => _SimpleInterfaceState();
}

class _SimpleInterfaceState extends State<SimpleInterface> {
  String departureAddress = '';
  int duration = 1;
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section with gradient text effect
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Color(0xFFAEB625),
                Color(0xFFF7EF8A),
                Color(0xFFD2AC47),
                Color(0xFFEDC967),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'Plan Your Trip',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Text color is white to show gradient
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Departure Address Input
          buildCard(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Departure Address',
                labelStyle: const TextStyle(
                  color: Colors.white, // White label
                ),
                prefixIcon: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Color(0xFFAEB625),
                      Color(0xFFF7EF8A),
                      Color(0xFFD2AC47),
                      Color(0xFFEDC967),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Icon(Icons.location_on, color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(
                color: Colors.white, // Text color inside the field
              ),
              onChanged: (value) {
                setState(() => departureAddress = value);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Duration Dropdown
          buildCard(
            child: DropdownButtonFormField<int>(
              value: duration,
              decoration: InputDecoration(
                labelText: 'Duration (Hours)',
                labelStyle: const TextStyle(
                  color: Colors.white, // White label
                ),
                prefixIcon: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Color(0xFFAEB625),
                      Color(0xFFF7EF8A),
                      Color(0xFFD2AC47),
                      Color(0xFFEDC967),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Icon(Icons.timer, color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
              onChanged: (value) => setState(() => duration = value ?? 1),
              items: List.generate(24, (index) => index + 1)
                  .map(
                    (hour) => DropdownMenuItem(
                  value: hour,
                  child: Text(
                    '$hour Hour${hour > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Date Picker
          buildCard(
            child: ListTile(
              leading: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Color(0xFFAEB625),
                    Color(0xFFF7EF8A),
                    Color(0xFFD2AC47),
                    Color(0xFFEDC967),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Icon(Icons.calendar_today, color: Colors.white),
              ),
              title: Text(
                'Selected Date: ${_formatDate(selectedDate)}',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  setState(() => selectedDate = pickedDate);
                }
              },
            ),
          ),

          const SizedBox(height: 20),

          // Estimate Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServiceSelectionPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Color(0xFFAEB625),
                  Color(0xFFF7EF8A),
                  Color(0xFFD2AC47),
                  Color(0xFFEDC967),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Estimate',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard({required Widget child}) {
    return Card(
      color: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: child,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
