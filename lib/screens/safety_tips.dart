import 'package:flutter/material.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conseils de Sécurité')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Équipement essentiel'),
          _buildCheckItem('Eau (minimum 2L par personne)'),
          _buildCheckItem('Nourriture énergétique (barres, fruits secs)'),
          _buildCheckItem('Carte et boussole / GPS'),
          _buildCheckItem('Trousse de premiers soins'),
          _buildCheckItem('Vêtements adaptés (coupe-vent, couche chaude)'),
          _buildCheckItem('Chaussures de randonnée'),
          _buildCheckItem('Lampe frontale + piles de rechange'),
          _buildCheckItem('Téléphone portable chargé'),
          _buildCheckItem('Crème solaire et lunettes de soleil'),
          _buildCheckItem('Sifflet pour appeler à l\'aide'),

          const SizedBox(height: 24),
          _buildSectionTitle('Conseils avant le départ'),
          _buildTipItem('• Vérifiez la météo avant de partir'),
          _buildTipItem('• Informez quelqu\'un de votre itinéraire'),
          _buildTipItem('• Chargez complètement votre téléphone'),
          _buildTipItem('• Vérifiez votre équipement la veille'),

          const SizedBox(height: 24),
          _buildSectionTitle('Pendant la randonnée'),
          _buildTipItem('• Restez sur les sentiers balisés'),
          _buildTipItem('• Adaptez votre rythme à votre condition physique'),
          _buildTipItem('• Hydratez-vous régulièrement'),
          _buildTipItem('• Faites des pauses si nécessaire'),

          const SizedBox(height: 24),
          _buildEmergencySection(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const SizedBox(width: 4), Expanded(child: Text(text))],
      ),
    );
  }

  Widget _buildEmergencySection(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'En cas d\'urgence :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Composez le 112 (numéro d\'urgence européen)'),
            const Text('• Restez calme et ne paniquez pas'),
            const Text('• Donnez votre position précise'),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.emergency),
                label: const Text('Appeler les secours'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Implémenter l'appel d'urgence
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Composition du 112 simulée'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
