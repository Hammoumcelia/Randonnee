import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/models/hike.dart';
import 'package:randonnee/services/hike_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class Position3D {
  final double latitude;
  final double longitude;
  final double altitude;

  Position3D(this.latitude, this.longitude, this.altitude);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _currentPosition;
  double? _distanceToHike;
  double? _elevationGain;
  Hike? _selectedHike;
  bool _isTracking = false;
  final List<Position3D> _pathPoints = [];
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _startLocationTracking();
    }
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (_selectedHike != null && _isTracking) {
        _updateDistance(position);
        _recordPath(position);
      }
      setState(() => _currentPosition = position);
    });
  }

  void _updateDistance(Position position) {
    if (_selectedHike == null || _selectedHike?.coordinates == null) return;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _selectedHike!.coordinates!.latitude,
      _selectedHike!.coordinates!.longitude,
    );
    setState(() => _distanceToHike = distance);
  }

  void _recordPath(Position position) {
    setState(() {
      _pathPoints.add(
        Position3D(position.latitude, position.longitude, position.altitude),
      );
      if (_pathPoints.length >= 2) {
        _calculateElevationGain();
      }
    });
  }

  void _calculateElevationGain() {
    double gain = 0;
    for (int i = 1; i < _pathPoints.length; i++) {
      final diff = _pathPoints[i].altitude - _pathPoints[i - 1].altitude;
      if (diff > 0) gain += diff;
    }
    setState(() => _elevationGain = gain);
  }

  void _selectHike(Hike hike) {
    setState(() {
      _selectedHike = hike;
      _isTracking = true;
      _pathPoints.clear();
      _elevationGain = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hikes = Provider.of<HikeService>(context).hikes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des randonnées - Algérie'),
        actions: [
          if (_selectedHike != null)
            IconButton(
              icon: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
              onPressed: () => setState(() => _isTracking = !_isTracking),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(28.0339, 1.6596),
              initialZoom: 5.5,
              onTap: (_, __) => setState(() => _selectedHike = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  ...hikes.map(
                    (hike) => Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(
                        hike.coordinates!.latitude,
                        hike.coordinates!.longitude,
                      ),
                      child: GestureDetector(
                        onTap: () => _selectHike(hike),
                        child: Icon(
                          Icons.location_pin,
                          color:
                              _selectedHike == hike ? Colors.blue : Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  if (_currentPosition != null)
                    Marker(
                      width: 45,
                      height: 45,
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.green,
                        size: 45,
                      ),
                    ),
                ],
              ),
              if (_pathPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points:
                          _pathPoints
                              .map((p) => LatLng(p.latitude, p.longitude))
                              .toList(),
                      color: Colors.blue.withOpacity(0.7),
                      strokeWidth: 4,
                    ),
                  ],
                ),
            ],
          ),
          if (_selectedHike != null || _currentPosition != null)
            Positioned(
              bottom: 20,
              left: 20,
              child: Card(
                color: Colors.white.withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentPosition != null) ...[
                        Text(
                          'Position: ${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                        ),
                        Text(
                          'Altitude: ${_currentPosition!.altitude.toStringAsFixed(1)} m',
                        ),
                      ],
                      if (_selectedHike != null) ...[
                        const Divider(),
                        Text('Destination: ${_selectedHike!.title}'),
                        if (_distanceToHike != null)
                          Text(
                            'Distance: ${(_distanceToHike! / 1000).toStringAsFixed(2)} km',
                          ),
                        if (_elevationGain != null)
                          Text(
                            'Dénivelé: ${_elevationGain!.toStringAsFixed(1)} m',
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          _selectedHike != null
              ? FloatingActionButton(
                onPressed:
                    () => setState(() {
                      _selectedHike = null;
                      _isTracking = false;
                    }),
                child: const Icon(Icons.clear),
              )
              : null,
    );
  }
}
