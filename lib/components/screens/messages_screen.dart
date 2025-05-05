import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:intl/intl.dart';
import 'package:sapers/components/screens/chat_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? selectedChat;
  final TextEditingController _messageController = TextEditingController();

  bool get isMobile => MediaQuery.of(context).size.width < 600;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProviderSapers>(context).userInfo;
    if (currentUser == null) return const Center(child: Text('Not logged in'));

    return Scaffold(
      body: Row(
        children: [
          // Chat list sidebar with constrained width
          SizedBox(
            width: isMobile ? MediaQuery.of(context).size.width : 300,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: Colors.grey.withOpacity(0.2))),
                  ),
                  child: Text(
                    Texts.translate(
                        'messages', LanguageProvider().currentLanguage),
                    style: const TextStyle(
                      fontSize: AppStyles.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Chat list
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firebaseService
                        .getUserDirectMessages(currentUser.username),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: SelectableText('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final chats = snapshot.data!.docs;
                      if (chats.isEmpty) {
                        return Center(
                          child: Text(
                            Texts.translate('noMessages',
                                LanguageProvider().currentLanguage),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chatDoc = chats[index];
                          final chat = chatDoc.data() as Map<String, dynamic>;
                          final otherUser = (chat['participants'] as List)
                              .firstWhere((u) => u != currentUser.username,
                                  orElse: () => '');

                          if (otherUser.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final isSelected = chatDoc.id == selectedChat;

                          return _buildChatListItem(
                            chat,
                            otherUser,
                            chatDoc.id, // Pass document ID
                            isSelected,
                            onTap: () =>
                                setState(() => selectedChat = chatDoc.id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Show chat content only on desktop
          if (!isMobile && selectedChat != null)
            Expanded(
              child: ChatDetailScreen(
                otherUser: (selectedChat!
                    .split('_')
                    .firstWhere((u) => u != currentUser.username)),
                chatId: selectedChat!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatListItem(
    Map<String, dynamic> chat,
    String otherUser,
    String docId, // Add docId parameter
    bool isSelected, {
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppStyles.colorAvatarBorder.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () {
          if (isMobile) {
            // Navigate to new screen on mobile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  otherUser: otherUser,
                  chatId: docId,
                ),
              ),
            );
          } else {
            // Update selected chat on desktop
            setState(() => selectedChat = docId);
          }
        },
        //leading: CircleAvatar(child: Text(otherUser[0].toUpperCase())),
        leading: UserProfileCardHover(
            authorUsername: otherUser, isExpert: false, onProfileOpen: () {}),
        title: Text(otherUser),
        subtitle: Text(
          chat['lastMessage'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatDate(chat['lastMessageTime'] as Timestamp),
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildNoChatSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            Texts.translate('selectChat', LanguageProvider().currentLanguage),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent(String currentUsername) {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firebaseService.getChatMessages(selectedChat!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!.docs;
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message =
                      messages[index].data() as Map<String, dynamic>;
                  final isMe = message['fromUsername'] == currentUsername;

                  return _buildMessageBubble(message, isMe);
                },
              );
            },
          ),
        ),
        // Message input
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border:
                Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: Texts.translate(
                        'typeMessage', LanguageProvider().currentLanguage),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? AppStyles.colorAvatarBorder : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['message'],
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(message['timestamp'] as Timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays < 7) {
      return DateFormat('E HH:mm').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || selectedChat == null) return;

    final currentUser =
        Provider.of<AuthProviderSapers>(context, listen: false).userInfo;
    if (currentUser == null) return;

    final otherUser =
        selectedChat!.split('_').firstWhere((u) => u != currentUser.username);

    _firebaseService.sendDirectMessage(
      fromUsername: currentUser.username,
      toUsername: otherUser,
      message: _messageController.text.trim(),
    );

    _messageController.clear();
  }
}
