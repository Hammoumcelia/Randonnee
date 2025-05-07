import 'package:flutter/material.dart';
import 'package:randonnee/models/hike.dart';
import 'package:randonnee/services/weather_service.dart';

class HikeCard extends StatelessWidget {
  final Hike hike;
  final VoidCallback onTap;

  const HikeCard({super.key, required this.hike, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hike.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      hike.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Text(
                hike.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hike.location,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text('${hike.distance} km'),
                    backgroundColor: Colors.green[100],
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${hike.duration} h'),
                    backgroundColor: Colors.blue[100],
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(hike.difficulty),
                    backgroundColor: _getDifficultyColor(hike.difficulty),
                  ),
                  const Spacer(),
                  _buildWeatherBadge(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherBadge(BuildContext context) {
    // 1. Vérification explicite des coordonnées
    if (hike.coordinates == null) {
      return _buildWeatherPlaceholder(
        icon: Icons.location_off,
        message: 'Pas de position',
        color: Colors.red,
      );
    }

    // 2. Vérification des coordonnées valides (0,0 est souvent une valeur par défaut invalide)
    if (hike.coordinates!.latitude == 0 && hike.coordinates!.longitude == 0) {
      return _buildWeatherPlaceholder(
        icon: Icons.warning,
        message: 'Position invalide',
        color: Colors.orange,
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      // Modifier l'appel dans le FutureBuilder
// Modifiez le FutureBuilder
future: WeatherService.getWeather(
  hike.coordinates!.latitude,
  hike.coordinates!.longitude,
),
      builder: (context, snapshot) {
        // 3. Gestion des états de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildWeatherPlaceholder(
            icon: Icons.refresh,
            message: 'Chargement...',
            color: Colors.blue,
            isLoading: true,
          );
        }

        // 4. Gestion des erreurs
        if (snapshot.hasError) {
          debugPrint('Erreur météo: ${snapshot.error}');
          return _buildWeatherPlaceholder(
            icon: Icons.error_outline,
            message: 'Erreur API',
            color: Colors.orange,
          );
        }

        // 5. Vérification des données reçues
        if (!snapshot.hasData || snapshot.data!['weather'] == null) {
          return _buildWeatherPlaceholder(
            icon: Icons.cloud_off,
            message: 'Données manquantes',
            color: Colors.grey,
          );
        }

        // 6. Affichage des données météo
        final weather = snapshot.data!['weather'][0];
        final main = snapshot.data!['main'];
        final temp = main['temp'].round();

        return Tooltip(
          message: '${weather['description']}\nTempérature: $temp°C',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
               Text(
  WeatherService.getWeatherIcon(weather['main']),
  style: const TextStyle(fontSize: 16),
),
                const SizedBox(width: 4),
                Text(
                  '$temp°C',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Méthode helper pour les états spéciaux
  Widget _buildWeatherPlaceholder({
    required IconData icon,
    required String message,
    required Color color,
    bool isLoading = false,
  }) {
    return Tooltip(
      message: message,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              message.split(' ').first,
              style: TextStyle(
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return Colors.green[100];
      case 'moyen':
        return Colors.orange[100];
      case 'difficile':
        return Colors.red[100];
      default:
        return Colors.grey[100];
    }
  }
}