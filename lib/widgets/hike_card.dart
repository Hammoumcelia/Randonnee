import 'package:flutter/material.dart';
import 'package:randonnee/models/hike.dart';

class HikeCard extends StatelessWidget {
  final Hike hike;
  final VoidCallback onTap;
  final bool showSaveButton;
  final VoidCallback? onSave;

  const HikeCard({
    super.key,
    required this.hike,
    required this.onTap,
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
                ],
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
