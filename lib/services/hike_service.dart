import 'package:flutter/foundation.dart';
import 'package:randonnee/models/hike.dart';
import 'package:latlong2/latlong.dart';

class HikeService with ChangeNotifier {
  final List<Hike> _hikes = [
    Hike(
      title: 'Tassili N\'Ajjer',
      location: 'Djanet, Algérie',
      coordinates: LatLng(24.8333, 9.5000), // Ajout des coordonnées
      description: 'Randonnée dans le désert',
      distance: 25.0,
      duration: 8.0,
      difficulty: 'Difficile',
      imageUrl: 'assets/images/tassili.jpg',
    ),
    Hike(
      title: 'Chréa',
      location: 'Blida, Algérie',
      coordinates: LatLng(36.4167, 2.8833), // Ajout des coordonnées
      description: 'Randonnée en montagne',
      distance: 12.0,
      duration: 4.0,
      difficulty: 'Moyen',
      imageUrl: 'assets/images/chrea.jpg',
    ),
  ];

  List<Hike> get hikes => _hikes;

  Future<List<Hike>> getHikes() async {
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulation de chargement
    return _hikes;
  }

  void addHike(Hike hike) async {
    _hikes.add(hike);
    notifyListeners();
  }
}
