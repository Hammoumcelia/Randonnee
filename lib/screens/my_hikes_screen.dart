import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/widgets/hike_card.dart';
import 'package:randonnee/services/hike_service.dart';
import 'package:randonnee/screens/map.dart';
import 'package:randonnee/models/hike.dart';
import 'package:randonnee/services/auth_service.dart';

class MyHikesScreen extends StatelessWidget {
  const MyHikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final hikeService = Provider.of<HikeService>(context);
    final userId = int.parse(authService.currentUser?.id ?? '0');

    return FutureBuilder<List<Hike>>(
      future: Provider.of<HikeService>(context).getSavedHikes(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final hikes = snapshot.data ?? [];

        return ListView.builder(
          itemCount: hikes.length,
          itemBuilder:
              (context, index) => HikeCard(
                hike: hikes[index],
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MapScreen(initialHike: hikes[index]),
                      ),
                    ),
              ),
        );
      },
    );
  }
}
