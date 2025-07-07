import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:randonnee/models/hike.dart';
import 'package:randonnee/services/hike_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:randonnee/services/database_service.dart';
import 'dart:math' show log, pi, pow, tan, cos;
import 'package:flutter/painting.dart';
import 'package:randonnee/screens/network_utils.dart';

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
  Position? _lastKnownPosition;
  double? _distanceToHike;
  double? _elevationGain;
  double? _currentBearing;
  Hike? _selectedHike;
  bool _isTracking = false;
  bool _isOffline = false;
  bool _isLoadingRoute = false;
  bool _isLoading = false;
  List<Position3D> _pathPoints = [];
  List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;

  bool get _isUsingLastKnownPosition {
    if (_currentPosition == null || _lastKnownPosition == null) return false;
    return _currentPosition!.latitude == _lastKnownPosition!.latitude &&
        _currentPosition!.longitude == _lastKnownPosition!.longitude;
  }

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    try {
      await _checkLocationPermission();
      _loadLastKnownPosition();
      _startLocationTracking();

      if (widget.initialHike != null) {
        // Attendre que la carte soit prête
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _mapController.move(
            LatLng(
              widget.initialHike!.coordinates!.latitude,
              widget.initialHike!.coordinates!.longitude,
            ),
            14,
          );
        }
      }
    } catch (e) {
      debugPrint('Map initialization error: $e');
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    _saveCurrentHikeData();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    try {
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
        if (!status.isGranted) {
          throw Exception('Location permission denied');
        }
      }
    } catch (e) {
      debugPrint('Permission error: $e');
      rethrow;
    }
  }

  Future<void> _loadLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        setState(() => _lastKnownPosition = position);
      }
    } catch (e) {
      debugPrint('Erreur dernier positionnement connu: $e');
    }
  }

  void _startLocationTracking() async {
    try {
      final isAvailable = await Geolocator.isLocationServiceEnabled();
      if (!isAvailable) {
        debugPrint('Location services are disabled');
        return;
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      ).listen(
        (Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _lastKnownPosition = position;

              if (_selectedHike != null && _isTracking) {
                _updateDistance(position);
                _recordPath(position);
              }
            });
          }
        },
        onError: (e) {
          debugPrint('Erreur GPS: $e');
          if (_lastKnownPosition != null && mounted) {
            setState(() => _currentPosition = _lastKnownPosition);
          }
        },
      );
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
    }
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
    });
  }

  Future<void> _downloadMapArea() async {
    if (_selectedHike == null || _selectedHike?.coordinates == null) return;

    final db = Provider.of<DatabaseService>(context, listen: false);
    final center = _selectedHike!.coordinates!;
    const zoomLevels = [10, 12, 13, 14, 15, 16, 17];
    const radiusInTiles = 12;

    setState(() => _isLoading = true);

    try {
      for (final zoom in zoomLevels) {
        final radius = zoom >= 15 ? 8 : (zoom >= 13 ? 10 : 12);
        await db.downloadMapArea(center, zoom, radiusInTiles);
        await Future.delayed(const Duration(milliseconds: 200));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carte téléchargée (jusqu\'au zoom 17)'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _precacheMapTiles(Hike hike) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final center = hike.coordinates!;
    const zoomLevels = [12, 13, 14, 15];
    const radius = 2;

    for (final zoom in zoomLevels) {
      for (int x = -radius; x <= radius; x++) {
        for (int y = -radius; y <= radius; y++) {
          final tileX =
              ((center.longitude + 180) / 360 * pow(2, zoom)).floor() + x;
          final tileY =
              ((1 -
                      log(
                            tan(center.latitude * pi / 180) +
                                1 / cos(center.latitude * pi / 180),
                          ) /
                          2 *
                          pow(2, zoom)))
                  .floor() +
              y;

          try {
            await dbService.cacheMapTile(
              tileX,
              tileY,
              zoom,
              'https://a.tile.openstreetmap.org/$zoom/$tileX/$tileY.png',
            );
          } catch (e) {
            debugPrint('Erreur pré-cache tuile: $e');
          }
        }
      }
    }
  }

  Future<void> _saveCurrentHikeData() async {
    if (_selectedHike != null && _pathPoints.isNotEmpty) {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      try {
        await dbService.saveHikePath(_selectedHike!.id, _pathPoints);
        if (_routePoints.isNotEmpty) {
          await dbService.saveRoute(_selectedHike!.id, _routePoints);
        }
        print('✅ Données de randonnée sauvegardées');
      } catch (e) {
        print('❌ Erreur sauvegarde: $e');
      }
    }
  }

  void _updatePosition(Position position) {
    if (_pathPoints.isNotEmpty) {
      final lastPoint = _pathPoints.last;
      _currentBearing = Geolocator.bearingBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        position.latitude,
        position.longitude,
      );
    }

    setState(() {
      _currentPosition = position;
      _pathPoints.add(
        Position3D(position.latitude, position.longitude, position.altitude),
      );
    });
  }

  void _updateConnectivityStatus(bool isOnline) {
    setState(() {
      _isOffline = !isOnline;

      if (_isOffline) {
        // Mode hors ligne - utilise la dernière position connue si disponible
        if (_currentPosition == null && _lastKnownPosition != null) {
          (_currentPosition?.latitude == _lastKnownPosition?.latitude &&
              _currentPosition?.longitude == _lastKnownPosition?.longitude);
        }
      } else {
        // Mode en ligne - réinitialise le statut
        if (_lastKnownPosition != null) {
          (_currentPosition?.latitude == _lastKnownPosition?.latitude &&
              _currentPosition?.longitude == _lastKnownPosition?.longitude);
        }
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
    final db = Provider.of<DatabaseService>(context, listen: false);
    final network = Provider.of<NetworkUtils>(context, listen: false);

    setState(() {
      _selectedHike = hike;
      _isLoading = true;
    });

    try {
      // Toujours charger depuis le cache d'abord
      final cachedRoute = await db.getRoute(hike.id);

      if (!network.forceOfflineMode && await network.isOnline) {
        // Mode en ligne - mettre à jour le cache
        try {
          final freshRoute = await _getRoutePoints(
            LatLng(
              _currentPosition?.latitude ?? hike.coordinates!.latitude,
              _currentPosition?.longitude ?? hike.coordinates!.longitude,
            ),
            hike.coordinates!,
          );
          await db.saveRoute(hike.id, freshRoute);
          setState(() => _routePoints = freshRoute);
        } catch (e) {
          // Si l'API échoue, utiliser le cache si disponible
          if (cachedRoute != null) {
            setState(() => _routePoints = cachedRoute);
          }
          debugPrint('API route error: $e');
        }
      } else if (cachedRoute != null) {
        // Mode hors ligne - utiliser le cache
        setState(() => _routePoints = cachedRoute);
      }

      // Précharger les tuiles autour de la randonnée
      if (hike.coordinates != null) {
        _precacheMapTiles(hike);
      }
    } catch (e) {
      debugPrint('Error loading route: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _zoomOut() {
    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(currentCenter, currentZoom - 0.5);
  }

  void _zoomIn() {
    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(currentCenter, currentZoom + 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final hikeService = Provider.of<HikeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des randonnées - Algérie'),
        actions: [
          if (_selectedHike != null) ...[
            // Bouton Play/Pause Tracking
            Tooltip(
              message: _isTracking ? 'Pause tracking' : 'Démarrer tracking',
              child: IconButton(
                icon:
                    _isTracking
                        ? const Icon(Icons.pause)
                        : const Icon(Icons.play_arrow),
                onPressed: () => setState(() => _isTracking = !_isTracking),
              ),
            ),

            const SizedBox(width: 8),

            // Bouton Téléchargement
            Tooltip(
              message: 'Télécharger la carte hors ligne',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _isLoading ? null : _downloadMapArea,
                  ),
                  if (_isLoading)
                    const Positioned(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),
          ],
        ],
      ),
      body: FutureBuilder<List<Hike>>(
        future:
            widget.initialHike != null
                ? Future.value([widget.initialHike!])
                : hikeService.availableHikes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hikes = snapshot.data ?? [];

          return Stack(
            children: [
              Positioned(
                top: 70,
                left: 10,
                child: Consumer<NetworkUtils>(
                  builder: (context, networkUtils, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            networkUtils.isOnline
                                ? Colors.green
                                : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            networkUtils.isOnline ? Icons.wifi : Icons.wifi_off,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            networkUtils.isOnline ? 'En ligne' : 'Hors ligne',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Nouvel indicateur GPS - Ajoutez-le juste ici
              Positioned(
                top: 70,
                right: 10, // Positionné à droite plutôt qu'à gauche
                child: Consumer<NetworkUtils>(
                  builder: (context, networkUtils, child) {
                    // networkUtils est disponible ici
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            networkUtils.isOnline
                                ? Colors.orange
                                : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isUsingLastKnownPosition
                                ? Icons.gps_not_fixed
                                : Icons.gps_fixed,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isUsingLastKnownPosition
                                ? 'GPS hors ligne'
                                : 'GPS actif',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

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
                  maxZoom: 17,
                  minZoom: 10,
                  onTap:
                      (_, __) => setState(() {
                        _selectedHike = null;
                        _routePoints = [];
                      }),
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(
                      const LatLng(18.0, -8.0), // Sud-Ouest de l'Algérie
                      const LatLng(38.0, 12.0), // Nord-Est de l'Algérie
                    ),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.randonnee',
                    tileProvider: _DatabaseTileProvider(
                      Provider.of<DatabaseService>(context),
                      Provider.of<NetworkUtils>(context).isOnline,
                    ),
                    tileBuilder: (context, tileWidget, tile) {
                      return FutureBuilder<Uint8List?>(
                        future: Provider.of<DatabaseService>(
                          context,
                        ).getMapTile(
                          tile.coordinates.x,
                          tile.coordinates.y,
                          tile.coordinates.z,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return Image.memory(snapshot.data!);
                          }
                          return Image.network(
                            'https://tile.openstreetmap.org/${tile.coordinates.z}/${tile.coordinates.x}/${tile.coordinates.y}.png',
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error_outline),
                                ),
                          );
                        },
                      );
                    },
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
                      // Marqueurs des randonnées (inchangé)
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

                      // Marqueur de position avec flèche de direction
                      if (_currentPosition != null)
                        Marker(
                          width: 60,
                          height: 60,
                          point: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Cercle de fond (vert comme avant)
                              TweenAnimationBuilder(
                                duration: const Duration(milliseconds: 500),
                                tween: Tween<double>(begin: 0.8, end: 1.0),
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: Icon(
                                      Icons.person_pin_circle,
                                      color:
                                          _isUsingLastKnownPosition
                                              ? Colors.orange
                                              : Colors.green,
                                      size: 45,
                                    ),
                                  );
                                },
                              ),

                              // Flèche de direction (seulement si bearing disponible)
                              if (_currentBearing != null)
                                Positioned(
                                  top: 0,
                                  child: Transform.rotate(
                                    angle: _currentBearing! * (pi / 180),
                                    child: Icon(
                                      Icons.navigation,
                                      color:
                                          _isUsingLastKnownPosition
                                              ? Colors.red
                                              : Colors.blue,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
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
                bottom: 160,
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
                    color: Colors.white.withValues(alpha: 0.8),
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
              if (_isLoadingRoute)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
      floatingActionButton:
          _selectedHike != null
              ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'saveButton',
                    onPressed: () async {
                      try {
                        final dbService = Provider.of<DatabaseService>(
                          context,
                          listen: false,
                        );
                        await dbService.saveHikePath(
                          _selectedHike!.id,
                          _pathPoints,
                        );
                        await dbService.saveRoute(
                          _selectedHike!.id,
                          _routePoints,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Itinéraire sauvegardé avec succès!'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur de sauvegarde: $e')),
                        );
                      }
                    },
                    child: const Icon(Icons.save),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: 'clearButton',
                    onPressed:
                        () => setState(() {
                          _selectedHike = null;
                          _isTracking = false;
                          _routePoints.clear();
                          _pathPoints.clear();
                        }),
                    child: const Icon(Icons.clear),
                  ),
                ],
              )
              : null,
    );
  }
}

class _DatabaseTileProvider extends TileProvider {
  final DatabaseService dbService;
  final bool isOnline;

  _DatabaseTileProvider(this.dbService, this.isOnline);

  @override
  ImageProvider getImage(TileCoordinates coords, TileLayer options) {
    if (!isOnline) {
      return _OfflineTileImage(coords, dbService);
    }
    return NetworkImage(
      options.urlTemplate!
          .replaceAll(
            '{s}',
            options.subdomains[coords.hashCode % options.subdomains.length],
          )
          .replaceAll('{z}', coords.z.toString())
          .replaceAll('{x}', coords.x.toString())
          .replaceAll('{y}', coords.y.toString()),
    );
  }
}

class _OfflineTileImage extends ImageProvider<_OfflineTileImage> {
  final TileCoordinates coords;
  final DatabaseService dbService;

  _OfflineTileImage(this.coords, this.dbService);

  @override
  ImageStreamCompleter loadImage(
    _OfflineTileImage key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(_loadOfflineTile());
  }

  Future<ImageInfo> _loadOfflineTile() async {
    try {
      // Essayer de charger uniquement depuis le cache local
      final tileData = await dbService.getMapTile(coords.x, coords.y, coords.z);
      if (tileData != null) {
        final codec = await ui.instantiateImageCodec(tileData);
        final frame = await codec.getNextFrame();
        return ImageInfo(image: frame.image);
      }

      // Si tuile non trouvée et hors ligne, ne rien afficher (laisser FlutterMap gérer)
      throw Exception('Tile not available offline');
    } catch (e) {
      debugPrint(
        'Failed to load offline tile at ${coords.z}/${coords.x}/${coords.y}: $e',
      );
      // Propager l'erreur pour que FlutterMap utilise son comportement par défaut
      rethrow;
    }
  }

  @override
  Future<_OfflineTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_OfflineTileImage>(this);
  }
}
