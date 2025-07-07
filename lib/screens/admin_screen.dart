import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/services/auth_service.dart';
import 'package:randonnee/services/database_service.dart';
import 'package:randonnee/screens/create_hike.dart';
import 'package:randonnee/screens/stats_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Gérer les utilisateurs'),
            leading: const Icon(Icons.people),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementScreen(),
                  ),
                ),
          ),
          ListTile(
            title: const Text('Créer une randonnée'),
            leading: const Icon(Icons.add),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateHikeScreen(),
                  ),
                ),
          ),
          ListTile(
            title: const Text('Gérer les randonnées'), // Nouvelle option
            leading: const Icon(Icons.terrain),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HikeManagementScreen(),
                  ),
                ),
          ),
          ListTile(
            title: const Text('Statistiques'),
            leading: const Icon(Icons.analytics),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatsScreen()),
                ),
          ),
        ],
      ),
    );
  }
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final currentUser = Provider.of<AuthService>(context).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des utilisateurs')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbService.getAllUsersExcept(int.parse(currentUser!.id)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user['name']),
                subtitle: Text(user['email']),
                trailing: Chip(
                  label: Text(user['role'] ?? 'user'),
                  backgroundColor:
                      user['role'] == 'admin'
                          ? Colors.blue[100]
                          : Colors.grey[200],
                ),
                onTap: () => _showUserOptions(context, user),
              );
            },
          );
        },
      ),
    );
  }

  void _showUserOptions(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Définir comme ${user['role'] == 'admin' ? 'utilisateur' : 'admin'}',
                ),
                leading: const Icon(Icons.admin_panel_settings),
                onTap: () async {
                  Navigator.pop(context);
                  await _toggleAdminStatus(user);
                },
              ),
              ListTile(
                title: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
                leading: const Icon(Icons.delete, color: Colors.red),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteUser(context, user);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _toggleAdminStatus(Map<String, dynamic> user) async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final newRole = user['role'] == 'admin' ? 'user' : 'admin';

      await dbService.db.then(
        (db) => db.update(
          'users',
          {'role': newRole},
          where: 'id = ?',
          whereArgs: [user['id']],
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rôle mis à jour pour ${user['name']}')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    Map<String, dynamic> user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text('Supprimer définitivement ${user['name']} ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _deleteUser(user);
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      await dbService.db.then(
        (db) => db.delete('users', where: 'id = ?', whereArgs: [user['id']]),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${user['name']} supprimé')));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }
}

class HikeManagementScreen extends StatefulWidget {
  const HikeManagementScreen({super.key});

  @override
  State<HikeManagementScreen> createState() => _HikeManagementScreenState();
}

class _HikeManagementScreenState extends State<HikeManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des randonnées')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbService.getAllHikes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final hikes = snapshot.data!;
          return ListView.builder(
            itemCount: hikes.length,
            itemBuilder: (context, index) {
              final hike = hikes[index];
              return ListTile(
                title: Text(hike['title']),
                subtitle: Text(hike['location']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteHike(context, hike),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteHike(
    BuildContext context,
    Map<String, dynamic> hike,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text('Supprimer définitivement "${hike['title']}" ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _deleteHike(hike);
    }
  }

  Future<void> _deleteHike(Map<String, dynamic> hike) async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      await dbService.db.then(
        (db) => db.delete('hikes', where: 'id = ?', whereArgs: [hike['id']]),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${hike['title']}" supprimée')));
      setState(() {}); // Rafraîchit la liste
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }
}
