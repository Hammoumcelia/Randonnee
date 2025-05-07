import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math';

class CompassWidget extends StatelessWidget {
  const CompassWidget({super.key, required double heading});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }

        final heading = snapshot.data?.heading ?? 0;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Direction', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Transform.rotate(
                angle: heading * (pi / 180) * -1,
                child: const Icon(Icons.arrow_upward, 
                  size: 36, 
                  color: Colors.red),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${heading.toStringAsFixed(0)}°',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        );
      },
    );
  }
}