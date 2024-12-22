import 'package:cloud_firestore/cloud_firestore.dart';

class SAPPost {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime timestamp;
  final String module;
  final bool isQuestion;
  final int replyCount;
  final List<String> tags;
  final List<Map<String, dynamic>>? attachments;

  SAPPost(
      {required this.id,
      required this.title,
      required this.content,
      required this.author,
      required this.timestamp,
      required this.module,
      this.isQuestion = false,
      required this.replyCount, // Ya no tiene valor por defecto
      required this.tags,
      this.attachments});

  // Añade el método fromMap para crear el objeto desde Firestore
  factory SAPPost.fromMap(Map<String, dynamic> map, String id) {
    return SAPPost(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      author: map['author'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      module: map['module'] ?? '',
      isQuestion: map['isQuestion'] ?? false,
      replyCount: map['replyCount'] ?? 0, // Toma el valor de Firestore
      tags: List<String>.from(map['tags'] ?? []),
      attachments: List<Map<String, dynamic>>.from(
          map['attachments'] ?? []), // Add this line
    );
  }

  // Añade el método toMap para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'author': author,
      'timestamp': timestamp.toIso8601String(),
      'module': module,
      'isQuestion': isQuestion,
      'replyCount': replyCount,
      'tags': tags,
    };
  }
}

class SAPReply {
  final String id;
  final String postId;
  final String content;
  final String author;
  final DateTime timestamp;
  final List<Map<String, dynamic>>? attachments;

  SAPReply({
    required this.id,
    required this.postId,
    required this.content,
    required this.author,
    required this.timestamp,
    this.attachments,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'content': content,
      'author': author,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SAPReply.fromMap(Map<String, dynamic> map) {
    return SAPReply(
      id: map['id'],
      postId: map['postId'],
      content: map['content'],
      author: map['author'],
      attachments: List<Map<String, dynamic>>.from(
          map['attachments'] ?? []), // Add this line
      // Convertir el Timestamp a DateTime, si es necesario
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp']),
    );
  }
}
