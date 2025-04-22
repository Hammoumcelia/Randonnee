import 'package:geolocator/geolocator.dart';

class GPSService {
  // Suivi en temps réel
  static Stream<Position> get liveLocation {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10, // Metres
      ),
    );
  }

  // Calcul de distance
  static Future<double> calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Calcul de dénivelé
  static double calculateElevationGain(List<Position> points) {
    double totalGain = 0;
    for (int i = 1; i < points.length; i++) {
      final diff = points[i].altitude - points[i - 1].altitude;
      if (diff > 0) totalGain += diff;
    }
    return totalGain;
  }

  // Vérification des permissions
  static Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return true;
  }
}
