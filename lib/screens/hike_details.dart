import 'package:flutter/material.dart';
import 'package:randonnee/models/hike.dart';

class HikeDetailsScreen extends StatelessWidget {
  final Hike hike;

  const HikeDetailsScreen({super.key, required this.hike});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hike.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hike.imageUrl != null) Image.network(hike.imageUrl!),
            const SizedBox(height: 16),
            Text(
              hike.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Text(hike.location),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.straighten, size: 16),
                const SizedBox(width: 4),
                Text('${hike.distance} km'),
                const SizedBox(width: 16),
                const Icon(Icons.timer, size: 16),
                const SizedBox(width: 4),
                Text('${hike.duration} heures'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(hike.description),
            const SizedBox(height: 16),
            const Text(
              'Difficulté',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(hike.difficulty),
          ],
        ),
      ),
    );
  }
}
