import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/services/auth_service.dart';
import 'package:randonnee/services/database_service.dart';
import 'package:randonnee/widgets/messagerie_widget.dart';

class NewConversationDialog extends StatefulWidget {
  const NewConversationDialog({super.key});

  @override
  State<NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<NewConversationDialog> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _loadUsers() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = int.parse(authService.currentUser?.id ?? '0');

      debugPrint('Chargement des utilisateurs (sauf ID $currentUserId)');

      final users = await DatabaseService().getAllUsersExcept(currentUserId);

      if (mounted) {
        setState(() {
          _users = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des utilisateurs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de chargement des utilisateurs';
        });
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers =
          _users.where((user) {
            return user['name'].toString().toLowerCase().contains(query) ||
                user['email'].toString().toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle conversation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Text(_errorMessage!, style: const TextStyle(color: Colors.red))
          else if (_filteredUsers.isEmpty)
            const Text('Aucun utilisateur trouvé')
          else
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return _buildUserListItem(context, user);
                },
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  Widget _buildUserListItem(BuildContext context, Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            user['name'].toString().isNotEmpty
                ? user['name'][0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(user['name']?.toString() ?? 'Utilisateur inconnu'),
        subtitle: Text(user['email']?.toString() ?? ''),
        onTap: () => _startConversation(context, user),
      ),
    );
  }

  Future<void> _startConversation(
    BuildContext context,
    Map<String, dynamic> user,
  ) async {
    try {
      if (user['id'] == null) {
        throw Exception('ID utilisateur invalide');
      }

      debugPrint('Début de conversation avec ${user['id']}');

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = int.parse(authService.currentUser?.id ?? '0');
      final dbService = DatabaseService();

      final conversationId = await dbService.getOrCreateConversation(
        currentUserId,
        user['id'],
      );

      debugPrint('Conversation créée avec ID: $conversationId');

      if (!mounted) return;

      Navigator.pop(context); // Ferme le dialogue

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => MessagerieWidget(
                conversationId: conversationId,
                otherUserId: user['id'],
                otherUserName: user['name']?.toString() ?? 'Utilisateur',
              ),
        ),
      );
    } catch (e) {
      debugPrint('Erreur création conversation: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
