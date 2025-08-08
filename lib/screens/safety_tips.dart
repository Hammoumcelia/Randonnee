import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:randonnee/services/sos_service.dart';
import 'package:provider/provider.dart';

class SafetyTipsScreen extends StatefulWidget {
  const SafetyTipsScreen({super.key});

  @override
  State<SafetyTipsScreen> createState() => _SafetyTipsScreenState();
}

class _SafetyTipsScreenState extends State<SafetyTipsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.microphone,
    ].request();
  }

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
              child: Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.emergency),
                    label: const Text('Envoyer SOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => _showSOSOptions(context),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Utilisez en cas d\'urgence extrême',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSOSOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.message, color: Colors.red),
                title: const Text('Envoyer message de détresse'),
                subtitle: const Text('Via connexion directe'),
                onTap: () async {
                  Navigator.pop(context);
                  await _sendSOSMessage(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic, color: Colors.red),
                title: const Text('Envoyer message vocal'),
                subtitle: const Text('10 secondes d\'enregistrement'),
                onTap: () async {
                  Navigator.pop(context);
                  await _sendVoiceSOS(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.call, color: Colors.red),
                title: const Text('Appeler les secours (112)'),
                onTap: () async {
                  Navigator.pop(context);
                  await _callEmergency(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendSOSMessage(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final sosService = Provider.of<SOSService>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            title: Text('Recherche de secours à proximité'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Recherche de personnes à proximité...'),
              ],
            ),
          ),
    );

    try {
      final success = await sosService.sendSOSMessage(context);
      navigator.pop();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Message SOS envoyé avec succès !'
                : 'Échec de l\'envoi du SOS',
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendVoiceSOS(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final sosService = Provider.of<SOSService>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            title: Text('Enregistrement vocal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Enregistrement en cours... Parlez maintenant'),
              ],
            ),
          ),
    );

    try {
      final success = await sosService.sendVoiceSOS(context);
      navigator.pop();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Message vocal envoyé avec succès !'
                : 'Échec de l\'envoi vocal',
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erreur vocale: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _callEmergency(BuildContext context) async {
    try {
      await Provider.of<SOSService>(
        context,
        listen: false,
      ).callEmergency(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur appel: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
