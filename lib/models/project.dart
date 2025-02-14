import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapers/models/user.dart';

class Member {
  final String memberId;
  final UserInfoPopUp userInfo;

  Member({
    required this.memberId,
    required this.userInfo,
  });

  factory Member.fromMap(String member, Map<String, dynamic> userInfoData) {
    return Member(
      memberId: member ?? '',
      userInfo: UserInfoPopUp.fromMap(userInfoData),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'userInfo': userInfo.toMap(),
    };
  }
}

class Project {
  final String projectid;
  final String projectName;
  final String description;
  final String createdBy;
  final List<String> tags;
  final String createdIn; // Cambiado a String
  final List<Member> members;

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
    // Verifica si 'members' es un mapa con las claves 'member' y 'userinfo'
    final membersData = data['members'];
    List<Member> membersList = [];

    if (membersData.isNotEmpty) {
      for (var mem in membersData) {
        membersList.add(Member.fromMap(mem['memberId'], mem['userInfo']));
      }
    }

    return Project(
      projectid: data['projectid'] ?? '',
      projectName: data['projectName'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdIn:
          _formatTimestamp(data['createdIn']), // Convertir Timestamp a String
      members: membersList,
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
      'members': {
        'member': members.map((member) => member.toMap()).toList(),
        'userinfo': members.isNotEmpty ? members.first.userInfo.toMap() : {},
      },
    };
  }
}

// task_model.dart
class ProjectTask {
  final String id;
  final String title;
  final String description;
  final String status;
  final double progress;
  final String assigneeId;
  final DateTime dueDate;

  ProjectTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.progress,
    required this.assigneeId,
    required this.dueDate,
  });

  factory ProjectTask.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ProjectTask(
      id: snapshot.id,
      title: data['title'],
      description: data['description'],
      status: data['status'],
      progress: data['progress']?.toDouble() ?? 0.0,
      assigneeId: data['assigneeId'],
      dueDate: (data['dueDate'] as Timestamp).toDate(),
    );
  }
}

// meeting_model.dart
class ProjectMeeting {
  final String id;
  final String title;
  final DateTime date;
  final List<String> participants;
  final String agenda;
  final String organizer;
  final String status;

  ProjectMeeting({
    required this.id,
    required this.title,
    required this.date,
    required this.participants,
    required this.agenda,
    required this.organizer,
    required this.status,
  });

  factory ProjectMeeting.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ProjectMeeting(
      id: snapshot.id,
      title: data['title'],
      date: (data['date'] as Timestamp).toDate(),
      participants: List<String>.from(data['participants']),
      agenda: data['agenda'],
      organizer: data['organizer'],
      status: data['status'],
    );
  }
}
