import 'package:flutter/foundation.dart';
import 'package:randonnee/models/hike.dart';
import 'package:latlong2/latlong.dart';
import 'package:randonnee/services/database_service.dart';

class HikeService with ChangeNotifier {
  List<Hike> _getDefaultHikes() {
    return [
      Hike(
        id: '1',
        title: 'Tassili N\'Ajjer',
        location: 'Djanet, Algérie',
        wilaya: 'Djanet',
        coordinates: LatLng(24.8333, 9.5000),
        description: 'Randonnée dans le désert',
        distance: 25.0,
        duration: 8.0,
        difficulty: 'Difficile',
        imageUrl: 'assets/images/tassili.jpg',
      ),
      Hike(
        id: '2',
        title: 'Chréa',
        location: 'Blida, Algérie',
        wilaya: 'Blida',
        coordinates: LatLng(36.4167, 2.8833),
        description: 'Randonnée en montagne dans le parc national de Chréa',
        distance: 12.0,
        duration: 4.0,
        difficulty: 'Moyen',
        imageUrl: 'assets/images/chrea.jpg',
      ),
      Hike(
        id: '3',
        title: 'Djurdjura',
        location: 'Tizi Ouzou, Algérie',
        wilaya: 'Tizi Ouzou',
        coordinates: LatLng(36.4667, 4.0667),
        description: 'Randonnée dans le massif du Djurdjura',
        distance: 15.0,
        duration: 6.0,
        difficulty: 'Difficile',
        imageUrl: 'assets/images/djurdjura.jpg',
      ),
      Hike(
        id: '4',
        title: 'Ghoufi',
        location: 'Batna, Algérie',
        wilaya: 'Batna',
        coordinates: LatLng(35.5833, 6.1833),
        description: 'Randonnée dans les gorges de Ghoufi',
        distance: 10.0,
        duration: 5.0,
        difficulty: 'Moyen',
        imageUrl: 'assets/images/ghoufi.jpg',
      ),
    ];
  }

  // Récupère toutes les randonnées (depuis la base ou les données par défaut)
  Future<List<Hike>> get availableHikes async {
    final dbService = DatabaseService();
    final hikesFromDb = await dbService.getAllHikes();

    if (hikesFromDb.isEmpty) {
      return _getDefaultHikes();
    }

    return hikesFromDb.map((map) => Hike.fromMap(map)).toList();
  }

  // Récupère les randonnées sauvegardées par un utilisateur
  Future<List<Hike>> getSavedHikes(int userId) async {
    final dbService = DatabaseService();
    final hikes = await dbService.getSavedHikes(userId);
    return hikes.map((map) => Hike.fromMap(map)).toList();
  }

  // Ajoute une nouvelle randonnée
  Future<void> addHike(Hike hike) async {
    final dbService = DatabaseService();
    await dbService.createHike(hike.toMap());
    notifyListeners();
  }

  // Sauvegarde une randonnée pour un utilisateur
  Future<void> saveHike(int userId, Hike hike) async {
    final dbService = DatabaseService();
    await dbService.saveHikeForUser(userId, hike.id);
    notifyListeners();
  }

  // Recherche des randonnées
  Future<List<Hike>> searchHikes(String query) async {
    final allHikes = await availableHikes;
    return allHikes
        .where(
          (hike) =>
              hike.title.toLowerCase().contains(query.toLowerCase()) ||
              hike.location.toLowerCase().contains(query.toLowerCase()) ||
              hike.wilaya.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
