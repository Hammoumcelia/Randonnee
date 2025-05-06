import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/services/auth_service.dart';
import 'package:randonnee/services/hike_service.dart';
import 'package:randonnee/widgets/hike_card.dart';
import 'package:randonnee/models/hike.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Hike> _displayedHikes = [];

  @override
  void initState() {
    super.initState();
    final hikeService = Provider.of<HikeService>(context, listen: false);
    _displayedHikes = hikeService.availableHikes;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final hikeService = Provider.of<HikeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          authService.isAuthenticated
              ? IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => _showProfileOptions(context),
              )
              : TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text(
                  'Connexion',
                  style: TextStyle(color: Colors.white),
                ),
              ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par wilaya (ex: Tizi Ouzou)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _displayedHikes =
                      value.isEmpty
                          ? hikeService.availableHikes
                          : hikeService.searchHikes(value);
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _displayedHikes.length,
              itemBuilder: (context, index) {
                final hike = _displayedHikes[index];
                return HikeCard(
                  hike: hike,
                  showSaveButton: true,
                  onSave: () {
                    hikeService.saveHike(hike);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${hike.title} enregistrée !')),
                    );
                  },
                  onTap:
                      () =>
                          Navigator.pushNamed(context, '/map', arguments: hike),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Mon profil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.hiking),
                title: const Text('Mes randonnées'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/my-hikes');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Déconnexion'),
                onTap: () {
                  Provider.of<AuthService>(context, listen: false).logout();
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                },
              ),
            ],
          ),
    );
  }
}
