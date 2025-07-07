import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:randonnee/models/hike.dart';
import 'package:randonnee/services/hike_service.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/services/auth_service.dart';

class CreateHikeScreen extends StatefulWidget {
  const CreateHikeScreen({super.key});

  @override
  _CreateHikeScreenState createState() => _CreateHikeScreenState();
}

class _CreateHikeScreenState extends State<CreateHikeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _wilayaController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  String _difficulty = 'Facile';

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _wilayaController.dispose();
    _descriptionController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final hike = Hike(
        title: _titleController.text,
        location: _locationController.text,
        wilaya: _wilayaController.text,
        coordinates: LatLng(
          double.parse(_latitudeController.text),
          double.parse(_longitudeController.text),
        ),
        description: _descriptionController.text,
        distance: double.parse(_distanceController.text),
        duration: double.parse(_durationController.text),
        difficulty: _difficulty,
        imageUrl: 'assets/images/default_hike.jpg',
      );

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = int.parse(authService.currentUser!.id);

        final hikeMap = hike.toMap();
        hikeMap['creator_id'] = userId;
        await Provider.of<HikeService>(context, listen: false).addHike(hike);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isAuthenticated || !authService.currentUser!.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accès refusé')),
        body: const Center(
          child: Text(
            'Vous devez être administrateur pour créer une randonnée',
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle randonnée')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Lieu'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un lieu';
                  }
                  return null;
                },
              ),
              // Champ Latitude
              TextFormField(
                controller: _latitudeController,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis';
                  final lat = double.tryParse(value);
                  if (lat == null || lat < -90 || lat > 90) {
                    return 'Entre -90 et 90';
                  }
                  return null;
                },
              ),

              // Champ Longitude
              TextFormField(
                controller: _longitudeController,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Obligatoire';
                  final lng = double.tryParse(value);
                  if (lng == null || lng < -180 || lng > 180) {
                    return 'Entre -180 et 180';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(labelText: 'Distance (km)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une distance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Durée (heures)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une durée';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _difficulty,
                items:
                    ['Facile', 'Moyen', 'Difficile']
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _difficulty = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Difficulté'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Créer la randonnée'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
