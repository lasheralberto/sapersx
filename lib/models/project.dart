import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String projectid;
  final String projectName;
  final String description;
  final String createdBy;
  final List<String> tags;
  final String createdIn; // Cambiado a String
  final List<String> members;

  Project({
    required this.projectid,
    required this.projectName,
    required this.description,
    required this.tags,
    required this.createdBy,
    required this.createdIn,
    required this.members,
  });

  factory Project.fromMap(Map<String, dynamic> data, String id) {
    return Project(
      projectid: data['projectid'] ?? '',
      projectName: data['projectName'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdIn:
          _formatTimestamp(data['createdIn']), // Convertir Timestamp a String
      members: List<String>.from(data['members'] ?? []),
    );
  }

  // Método para convertir Timestamp a String
  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate(); // Convertir Timestamp a DateTime
      return "${date.day}-${date.month}-${date.year}"; // Formato de fecha
    }
    return timestamp.toString(); // Si no es Timestamp, devolver como String
  }

  Map<String, dynamic> toMap() {
    return {
      'projectid': projectid,
      'projectName': projectName,
      'description': description,
      'tags': tags,
      'createdBy': createdBy,
      'createdIn': createdIn,
      'members': members,
    };
  }
}
