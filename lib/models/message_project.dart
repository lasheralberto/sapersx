import 'package:cloud_firestore/cloud_firestore.dart';

class MessageProject {
  final String author;
  final String content;
  final bool accepted;
  final String destiny;
  final DateTime timestamp;

  MessageProject({
    required this.author,
    required this.destiny,
    required this.content,
    required this.accepted,
    required this.timestamp,
  });

  factory MessageProject.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageProject(
      author: data['from'] ?? '',
      destiny: data['to'] ?? '',
      content: data['message'] ?? '',
      accepted:data['accepted'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
