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
      'member': memberId,
      'userinfo': userInfo.toMap(),
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
    List<Member> membersList = [];

    // Obtenemos el valor sin forzar el tipo, ya que puede ser Map o List.
    final dynamic membersRaw = data['members'];

    Map<String, dynamic> membersData;
    if (membersRaw is Map<String, dynamic>) {
      // Si ya es un Map, lo usamos directamente.
      membersData = membersRaw;
    } else if (membersRaw is List) {
      // Si es una lista, asumimos que es una lista de mapas (cada uno con 'member' y 'userinfo').
      if (membersRaw.isNotEmpty && membersRaw[0] is Map<String, dynamic>) {
        List<dynamic> memberIds = [];
        List<dynamic> userinfoList = [];

        // Recorremos cada elemento de la lista y extraemos los datos.
        for (var item in membersRaw) {
          // Usamos 'member' o 'memberid', según cómo se guarden los IDs.
          memberIds.add(item['member'] ?? item['memberid'] ?? '');
          userinfoList.add(item['userinfo'] ?? {});
        }
        membersData = {
          'member': memberIds,
          'userinfo': userinfoList,
        };
      } else {
        // Si la lista está vacía o no tiene el formato esperado, usamos un mapa vacío.
        membersData = {};
      }
    } else {
      // Si no es Map ni List, lo dejamos como mapa vacío.
      membersData = {};
    }

    // Extraemos la lista de IDs. Si no existe, usamos una lista vacía.
    final List<dynamic> memberIds =
        membersData['member'] as List<dynamic>? ?? [];

    // Extraemos la información de usuario; puede venir como List o como Map.
    final dynamic userinfoRaw = membersData['userinfo'];
    List<dynamic> userinfoList;
    if (userinfoRaw is List<dynamic>) {
      userinfoList = userinfoRaw;
    } else if (userinfoRaw is Map<String, dynamic>) {
      // Convertimos los valores del mapa a una lista.
      userinfoList = userinfoRaw.values.toList();
    } else {
      userinfoList = [];
    }

    // Combinamos ambas listas usando el mismo índice.
    for (int i = 0; i < memberIds.length; i++) {
      final String memberId = memberIds[i].toString();
      final Map<String, dynamic> userInfoMap =
          (i < userinfoList.length && userinfoList[i] is Map<String, dynamic>)
              ? userinfoList[i] as Map<String, dynamic>
              : {};
      membersList.add(Member.fromMap(memberId, userInfoMap));
    }

    return Project(
      projectid: data['projectid'] ?? '',
      projectName: data['projectName'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdIn: _formatTimestamp(data['createdIn']),
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
