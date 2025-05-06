import 'package:flutter/foundation.dart';
import 'package:randonnee/models/hike.dart';
import 'package:latlong2/latlong.dart';

class HikeService with ChangeNotifier {
  final List<Hike> _availableHikes = [
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

  final List<Hike> _savedHikes = [];

  List<Hike> get availableHikes => _availableHikes;
  List<Hike> get savedHikes => _savedHikes;

  Future<List<Hike>> getHikes() async {
    await Future.delayed(const Duration(seconds: 1));
    return _availableHikes;
  }

  void addHike(Hike newHike) {
    _availableHikes.add(newHike);
    notifyListeners();
  }

  void saveHike(Hike hike) {
    if (!_savedHikes.contains(hike)) {
      _savedHikes.add(hike);
      notifyListeners();
    }
  }

  List<Hike> searchHikes(String query) {
    return _availableHikes
        .where(
          (hike) =>
              hike.wilaya.toLowerCase().contains(query.toLowerCase()) ||
              hike.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
