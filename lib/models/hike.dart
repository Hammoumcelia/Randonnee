import 'package:latlong2/latlong.dart';


class Hike {
  final String id;
  final String title;
  final String location;
  final LatLng? coordinates;
  final String description;
  final double distance;
  final double duration;
  final String difficulty;
  final String? imageUrl;

  Hike({
    required this.title,
    required this.location,
    required this.coordinates,
    required this.description,
    required this.distance,
    required this.duration,
    required this.difficulty,
    this.imageUrl,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'latitude': coordinates?.latitude, // Nouveau
      'longitude': coordinates?.longitude, // Nouveau
      'description': description,
      'distance': distance,
      'duration': duration,
      'difficulty': difficulty,
      'imageUrl': imageUrl,
    };
  }

  factory Hike.fromMap(Map<String, dynamic> map) {
    return Hike(
      id: map['id'],
      title: map['title'],
      location: map['location'],
      coordinates:
          map['coordinates'] != null
              ? LatLng(
                map['coordinates']['latitude']?.toDouble() ?? 0.0,
                map['coordinates']['longitude']?.toDouble() ?? 0.0,
              )
              : const LatLng(0, 0),
      description: map['description'],
      distance: map['distance']?.toDouble() ?? 0.0,
      duration: map['duration']?.toDouble() ?? 0.0,
      difficulty: map['difficulty'],
      imageUrl: map['imageUrl'],
    );
  }
}
