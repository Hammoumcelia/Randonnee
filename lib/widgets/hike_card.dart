import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/models/hike.dart';
import 'package:randonnee/services/review_service.dart';

class HikeCard extends StatelessWidget {
  final Hike hike;
  final VoidCallback onTap;
  final VoidCallback? onMapTap;
  final bool showSaveButton;
  final VoidCallback? onSave;

  const HikeCard({
    super.key,
    required this.hike,
    required this.onTap,
    this.onMapTap,
    this.showSaveButton = false,
    this.onSave,
  });

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
                    child: Image.asset(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                  // Bouton de localisation
                  if (onMapTap != null)
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
                      onPressed: onMapTap,
                      tooltip: 'Voir sur la carte',
                    ),
                ],
              ),

              const SizedBox(height: 8),
              FutureBuilder<Map<String, dynamic>>(
                future: Provider.of<ReviewService>(
                  context,
                  listen: false,
                ).getHikeRatingSummary(hike.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 20,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox();
                  }

                  final avgRating = snapshot.data!['average'] ?? 0.0;
                  final reviewCount = snapshot.data!['count'] ?? 0;

                  if (avgRating == 0.0 || reviewCount == 0) {
                    return const SizedBox();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($reviewCount avis)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (showSaveButton && onSave != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bookmark_add, size: 18),
                      label: const Text('Enregistrer'),
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
