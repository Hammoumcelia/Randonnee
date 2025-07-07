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
    _loadHikes();
  }

  Future<void> _loadHikes() async {
    try {
      final hikeService = Provider.of<HikeService>(context, listen: false);
      final hikes = await hikeService.availableHikes;
      setState(() {
        _displayedHikes = hikes;
      });
    } catch (e) {
      print('❌ Erreur lors du chargement des randonnées : $e');
    }
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
                onPressed: _showProfileOptions,
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
              onChanged: (value) async {
                final hikeService = Provider.of<HikeService>(
                  context,
                  listen: false,
                );
                final hikes =
                    value.isEmpty
                        ? await hikeService.availableHikes
                        : await hikeService.searchHikes(value);
                setState(() {
                  _displayedHikes = hikes;
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
                  onTap: () {
                    // Navigation vers les détails
                    Navigator.pushNamed(
                      context,
                      '/hike-details',
                      arguments: hike,
                    );
                  },
                  onMapTap: () {
                    // Navigation vers la carte
                    Navigator.pushNamed(context, '/map', arguments: hike);
                  },
                  onSave: () {
                    final userId = int.parse(
                      authService.currentUser?.id ?? '0',
                    );
                    hikeService.saveHike(userId, hike);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${hike.title} enregistrée !')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileOptions() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAdmin = authService.currentUser?.isAdmin ?? false;
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Administration'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin');
                  },
                ),
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
