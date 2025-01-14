import 'package:flutter/material.dart';
import 'package:cabsudapp/services/services_type_page.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Prestations'),
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 2,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Service Cards
            const ServiceCard(
              title: 'Chauffeur',
              description: 'Des chauffeurs professionnels, ponctuels et discrets.',
              icon: Icons.directions_car,
            ),
            const ServiceCard(
              title: 'Prix fixes',
              description: 'Tous nos prix sont fixes et connus à l\'avance.',
              icon: Icons.attach_money,
            ),
            const ServiceCard(
              title: 'Véhicules',
              description: 'Voitures récentes, spacieuses et tout confort.',
              icon: Icons.car_repair,
            ),
            const ServiceCard(
              title: 'Wifi',
              description: 'Tous nos véhicules proposent un wifi à bord.',
              icon: Icons.wifi,
            ),
            const ServiceCard(
              title: 'Enfants',
              description: 'Siège bébé ou rehausseur gratuit : à la demande.',
              icon: Icons.child_care,
            ),
            const ServiceCard(
              title: 'Paiement',
              description: 'Paiement en ligne ou à bord du véhicule.',
              icon: Icons.payment,
            ),
            const ServiceCard(
              title: 'Paiement en ligne sécurisé',
              description: 'Carte bancaire, American Express.',
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 30),

            // Navigate to Home Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ServiceSelectionPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                ),
                child: const Text(
                  'Aller à la page d\'accueil',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const ServiceCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFAE8625), Color(0xFFF7EF8A), Color(0xFFD2AC47), Color(0xFFEDC967)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(3), // Border thickness
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black, // Inner card background color
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Circle with Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFAE8625), Color(0xFFF7EF8A), Color(0xFFD2AC47), Color(0xFFEDC967)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  icon,
                  size: 30,
                  color: Colors.black, // Icon color to contrast gradient
                ),
              ),
              const SizedBox(width: 20),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF7EF8A), // Text color
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFEDC967), // Description text color
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
