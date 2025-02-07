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
  final bool isExpert;
  final List<Map<String, dynamic>>? attachments;

  SAPPost(
      {required this.id,
      required this.title,
      required this.content,
      required this.author,
      required this.timestamp,
      required this.module,
      required this.isExpert,
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
      isExpert: map['isExpert'] ?? false,
      author: map['author'] ?? '',
      timestamp: map['timestamp'] != null
          ? map['timestamp'] is String
              ? DateTime.parse(
                  map['timestamp']) // Si es un String, lo parseamos
              : map['timestamp'] is DateTime
                  ? map[
                      'timestamp'] // Si ya es DateTime, lo usamos directamente
                  : DateTime
                      .now() // Si no es String ni DateTime, ponemos la fecha actual
          : DateTime.now(), // Si es null, usamos la fecha actual
      module: map['module'] ?? '',
      isQuestion: map['isQuestion'] ?? false,
      replyCount: map['replyCount'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      attachments: List<Map<String, dynamic>>.from(map['attachments'] ?? []),
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
      'isExpert': isExpert,
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
  final int replyVotes;
  final List<String> repliedBy;
  final List<Map<String, dynamic>>? attachments;

  SAPReply({
    required this.id,
    required this.postId,
    required this.content,
    required this.author,
    required this.repliedBy,
    required this.replyVotes,
    required this.timestamp,
    this.attachments,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'content': content,
      'author': author,
      'replyVotes': replyVotes,
      'timestamp': timestamp.toIso8601String(),
      'repliedBy': repliedBy
    };
  }

  factory SAPReply.fromMap(Map<String, dynamic> map) {
    return SAPReply(
      id: map['id'],
      postId: map['postId'],
      content: map['content'],
      author: map['author'],
      replyVotes: map['replyVotes'] ?? 0,
      repliedBy: List<String>.from(map['repliedBy'] ?? []),
      attachments: List<Map<String, dynamic>>.from(
          map['attachments'] ?? []), // Add this line
      // Convertir el Timestamp a DateTime, si es necesario
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp']),
    );
  }
}
