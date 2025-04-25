import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/screens/hike_details.dart';
import 'package:randonnee/screens/profile.dart';
import 'package:randonnee/screens/map.dart';
import 'package:randonnee/screens/create_hike.dart';
import 'package:randonnee/screens/safety_tips.dart';
import 'package:randonnee/services/hike_service.dart';
import 'package:randonnee/widgets/hike_card.dart';
import 'package:randonnee/models/hike.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const HikeListScreen(),
    const MapScreen(),

    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _currentIndex == 0
              ? AppBar(
                title: const Text('Mes Randonnées'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.security),
                    tooltip: 'Conseils de sécurité',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SafetyTipsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              )
              : null,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Randonnées'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Carte'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0: // Page des randonnées
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateHikeScreen()),
            );
          },
          child: const Icon(Icons.add),
        );
      case 1: // Page de la carte
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SafetyTipsScreen()),
            );
          },
          child: const Icon(Icons.security),
          heroTag: 'safetyButton', // Important pour éviter les conflits
        );
      case 2: // Page de profil
        return null;
      default:
        return null;
    }
  }
}

class HikeListScreen extends StatelessWidget {
  const HikeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hikeService = Provider.of<HikeService>(context);

    return FutureBuilder<List<Hike>>(
      future: hikeService.getHikes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final hikes = snapshot.data ?? [];

        if (hikes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hiking, size: 50, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Aucune randonnée enregistrée',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateHikeScreen(),
                      ),
                    );
                  },
                  child: const Text('Ajouter une randonnée'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await hikeService.getHikes();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: hikes.length,
            itemBuilder: (context, index) {
              final hike = hikes[index];
              return HikeCard(
                hike: hike,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HikeDetailsScreen(hike: hike),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
