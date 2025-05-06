import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/screens/profile.dart';
import 'package:randonnee/screens/map.dart';
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

  final List<Widget> _screens = [
    const MyHikesScreen(), // Remplace HikeListScreen
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
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Mes Randonnées',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Carte'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class MyHikesScreen extends StatelessWidget {
  const MyHikesScreen({super.key});

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
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => await hikeService.getHikes(),
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
                      builder: (context) => MapScreen(initialHike: hike),
                    ),
                  );
                },
                showSaveButton: false, // Pas de bouton Enregistrer ici
              );
            },
          ),
        );
      },
    );
  }
}
