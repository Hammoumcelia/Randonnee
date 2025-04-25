import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randonnee/services/auth_service.dart';

class MessagerieWidget extends StatefulWidget {
  const MessagerieWidget({super.key});

  @override
  State<MessagerieWidget> createState() => _MessagerieWidgetState();
}

class _MessagerieWidgetState extends State<MessagerieWidget> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.insert(0, {
        'text': _messageController.text,
        'sender': user?.name ?? 'Anonyme',
        'isMe': true,
        'time': DateTime.now(),
      });
      _messageController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Column(
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              const Icon(Icons.message, color: Colors.blue),
              const SizedBox(width: 10),
              Text(
                'Messagerie',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Liste des messages
        Expanded(
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (_) => _sendMessage(context),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () => _sendMessage(context),
              ),
            ],
          ),
        ),
      ],
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
