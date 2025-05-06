import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/widgets/hike_card.dart';
import 'package:randonnee/services/hike_service.dart';
import 'package:randonnee/screens/map.dart'; // Assurez-vous d'importer MapScreen

class MyHikesScreen extends StatelessWidget {
  const MyHikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hikeService = Provider.of<HikeService>(context);
    final savedHikes = hikeService.savedHikes;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Randonnées')),
      body:
          savedHikes.isEmpty
              ? const Center(child: Text('Aucune randonnée enregistrée'))
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: savedHikes.length,
                itemBuilder: (context, index) {
                  final hike = savedHikes[index];
                  return HikeCard(
                    hike: hike,
                    showSaveButton: false,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => MapScreen(
                                  initialHike: hike,
                                  showOnlySelectedHike: true,
                                ),
                          ),
                        ),
                  );
                },
              ),
    );
  }
}
