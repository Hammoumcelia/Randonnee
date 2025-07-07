import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/services/auth_service.dart';
import 'package:randonnee/services/database_service.dart';

class MessagerieWidget extends StatefulWidget {
  final int conversationId;
  final int otherUserId; // ID de l'utilisateur avec qui on discute
  final String otherUserName; // Nom de l'utilisateur

  const MessagerieWidget({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.conversationId,
  });

  @override
  State<MessagerieWidget> createState() => _MessagerieWidgetState();
}

class _MessagerieWidgetState extends State<MessagerieWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = int.parse(authService.currentUser?.id ?? '0');
      final dbService = DatabaseService();

      // Utilisez rawQuery directement pour plus de flexibilité
      final messages = await dbService.db.then(
        (db) => db.rawQuery(
          '''
      SELECT m.*, 
             CASE WHEN m.sender_id = ? THEN 1 ELSE 0 END as is_me
      FROM messages m
      WHERE m.conversation_id = ?
      ORDER BY m.sent_at DESC
    ''',
          [currentUserId, widget.conversationId],
        ),
      );

      setState(() {
        _messages =
            messages.map((msg) {
              return {
                'text': msg['content'],
                'sender':
                    msg['is_me'] == 1
                        ? authService.currentUser?.name
                        : widget.otherUserName,
                'isMe': msg['is_me'] == 1,
                'time':
                    msg['sent_at'] != null
                        ? DateTime.tryParse(msg['sent_at'].toString()) ??
                            DateTime.now()
                        : DateTime.now(),
              };
            }).toList();
      });
    } catch (e) {
      debugPrint('Erreur chargement messages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des messages')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = int.parse(authService.currentUser?.id ?? '0');
      final dbService = DatabaseService();

      await dbService.sendMessage({
        'conversation_id': widget.conversationId,
        'sender_id': currentUserId,
        'content': _messageController.text.trim(),
      });

      _messageController.clear();
      await _loadMessages();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Erreur envoi message: $e');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Discussion avec ${widget.otherUserName}')),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMessages,
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message, user);
                },
              ),
            ),
          ),

          // Champ de saisie
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, User? user) {
    final isMe = message['isMe'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Text(
              message['sender'] ?? 'Expéditeur',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message['text'] ?? '',
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message['time']),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
