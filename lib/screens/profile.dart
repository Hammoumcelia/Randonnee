import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              Text('Nom: ${user.name}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                'Email: ${user.email}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await authService.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Déconnexion'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
