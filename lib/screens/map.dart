import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/models/hike.dart';
import 'package:randonnee/services/hike_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class Position3D {
  final double latitude;
  final double longitude;
  final double altitude;
  Position3D(this.latitude, this.longitude, this.altitude);
}

class MapScreen extends StatefulWidget {
  final Hike? initialHike;
  final bool showOnlySelectedHike;

  const MapScreen({
    super.key,
    this.initialHike,
    this.showOnlySelectedHike = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  double? _distanceToHike;
  double? _elevationGain;
  Hike? _selectedHike;
  bool _isTracking = false;
  bool _isLoadingRoute = false;
  final List<Position3D> _pathPoints = [];
  List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission().then((_) {
      _startLocationTracking();
      if (widget.initialHike != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _selectHike(widget.initialHike!);
          _mapController.move(
            LatLng(
              widget.initialHike!.coordinates!.latitude,
              widget.initialHike!.coordinates!.longitude,
            ),
            14,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) {
        throw Exception('Permission de localisation non accordée');
      }
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

  Future<List<LatLng>> _getRoutePoints(LatLng start, LatLng end) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://router.project-osrm.org/route/v1/foot/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}?overview=full&geometries=geojson',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] == null || data['routes'].isEmpty) {
          throw Exception('Aucun itinéraire trouvé');
        }
        final geometry = data['routes'][0]['geometry']['coordinates'];
        return geometry
            .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
            .toList();
      } else {
        throw Exception('Erreur de serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<void> _selectHike(Hike hike) async {
    if (_currentPosition == null) return;

    setState(() {
      _selectedHike = hike;
      _isLoadingRoute = true;
      _isTracking = true;
    });

    try {
      final route = await _getRoutePoints(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(hike.coordinates!.latitude, hike.coordinates!.longitude),
      );

      setState(() {
        _routePoints = route;
        _pathPoints.clear();
        _elevationGain = null;
      });

      _mapController.move(
        LatLng(hike.coordinates!.latitude, hike.coordinates!.longitude),
        14,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de calcul d'itinéraire: $e")),
      );
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  void _zoomIn() {
    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(currentCenter, currentZoom + 0.5);
  }

  void _zoomOut() {
    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(currentCenter, currentZoom - 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final hikeService = Provider.of<HikeService>(context);
    final hikes =
        widget.showOnlySelectedHike
            ? (widget.initialHike != null ? [widget.initialHike!] : [])
            : hikeService.availableHikes;

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
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  widget.initialHike?.coordinates ??
                  const LatLng(28.0339, 1.6596),
              initialZoom: widget.initialHike != null ? 14 : 5.5,
              interactionOptions: const InteractionOptions(
                flags:
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom,
              ),
              maxZoom: 18,
              minZoom: 3,
              onTap:
                  (_, __) => setState(() {
                    _selectedHike = null;
                    _routePoints = [];
                  }),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.green,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  ...hikes
                      .where((h) => h.coordinates != null)
                      .map(
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
                                  _selectedHike == hike
                                      ? Colors.blue
                                      : Colors.red,
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
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
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
          if (_isLoadingRoute) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton:
          _selectedHike != null
              ? FloatingActionButton(
                onPressed:
                    () => setState(() {
                      _selectedHike = null;
                      _isTracking = false;
                      _routePoints = [];
                    }),
                child: const Icon(Icons.clear),
              )
              : null,
    );
  }
}
