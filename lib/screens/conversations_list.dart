import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/services/auth_service.dart';
import 'package:randonnee/services/database_service.dart';
import 'package:randonnee/widgets/messagerie_widget.dart';
import 'package:randonnee/widgets/new_conversation_dialog.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUserId = int.parse(authService.currentUser?.id ?? '0');

    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseService().getUserConversations(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune conversation'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final conversation = snapshot.data![index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(conversation['other_user_name'][0]),
                ),
                title: Text(conversation['other_user_name']),
                subtitle: Text(
                  conversation['last_message'] ?? 'Démarrer la conversation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatDate(conversation['last_message_time']),
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () => _openConversation(context, conversation),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.message),
        onPressed: () => _showNewConversationDialog(context),
      ),
    );
  }

  void _openConversation(BuildContext context, Map<String, dynamic> conv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => MessagerieWidget(
              conversationId: conv['id'],
              otherUserId: conv['other_user_id'],
              otherUserName: conv['other_user_name'],
            ),
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const NewConversationDialog());
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';

    return '${date.day}/${date.month} ${date.hour}:${date.minute}';
  }
}
