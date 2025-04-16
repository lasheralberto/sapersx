// firebase_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/components/widgets/like_button.dart';
import 'package:sapers/components/widgets/mesmorphic_popup.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/user_reviews.dart';
import 'package:rxdart/rxdart.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:sapers/models/utils_sapers.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final CollectionReference postsCollection =
      FirebaseFirestore.instance.collection('posts');
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('userinfo');
  final CollectionReference repliesCollection =
      FirebaseFirestore.instance.collection('replies');
  //Projects collection
  final CollectionReference projectsCollection =
      FirebaseFirestore.instance.collection('projects');

  //Messages collection
  final CollectionReference messagesCollection =
      FirebaseFirestore.instance.collection('messages');

  //projectchat collection
  final CollectionReference projectChatCollection =
      FirebaseFirestore.instance.collection('projectChat');

  // Constantes para paginación
  static const int postsPerPage = 10;

  // Cache para información de usuarios
  final Map<String, UserInfoPopUp> _userCache = {};

  Stream<QuerySnapshot> getProjectChatStream(String projectId) {
    return projectChatCollection
        .doc(projectId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<bool> isProjectMember(String projectId, String userId) async {
    try {
      final projectQuery = await FirebaseFirestore.instance
          .collection('projects')
          .where('projectid', isEqualTo: projectId)
          .limit(1)
          .get();

      if (projectQuery.docs.isEmpty) return false;

      final projectData = projectQuery.docs.first.data();
      final membersData = projectData['members'];

      // Estandarización de la estructura de miembros
      List<Map<String, dynamic>> members = [];

      if (membersData is Map<String, dynamic>) {
        // Caso estructura Map con clave 'member'
        final mapMembers = membersData['member'] as List<dynamic>?;
        members = mapMembers?.cast<Map<String, dynamic>>() ?? [];
      } else if (membersData is List<dynamic>) {
        // Caso estructura List directa
        members = membersData.cast<Map<String, dynamic>>();
      }

      // Búsqueda del usuario en miembros
      return members.any((member) {
        final memberId = member['memberid'] as String?;
        return memberId == userId;
      });
    } catch (e) {
      print('Error verificando membresía: $e');
      return false;
    }
  }

  Future<void> sendProjectMessage({
    required String projectId,
    required String text,
    required String senderId,
    required String senderName,
    required String senderPhoto,
  }) async {
    // Verificar membresía

    await projectChatCollection.doc(projectId).collection('messages').add({
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'timestamp': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getProjectRequirementsStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('requirements')
        .snapshots();
  }

  Future<void> addProjectRequirement({
    required String projectId,
    required String title,
    required String description,
  }) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('requirements')
        .add({
      'title': title,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProjectRequirement({
    required String projectId,
    required String requirementId,
    required String title,
    required String description,
  }) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('requirements')
        .doc(requirementId)
        .update({
      'title': title,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProjectRequirement({
    required String projectId,
    required String requirementId,
  }) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('requirements')
        .doc(requirementId)
        .delete();
  }

  Future<List<Project>> getProjectsFuture() async {
    final snapshot = await projectsCollection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Project.fromMap(data, doc.id);
    }).toList();
  }

// Obtiene en tiempo real los proyectos creados por el usuario (QuerySnapshot)
  Stream<QuerySnapshot> getCreatedProjectsForUser(String uid) {
    try {
      // Retornamos el stream de snapshots que se actualiza automáticamente
      return projectsCollection.where('createdBy', isEqualTo: uid).snapshots();
    } catch (e) {
      print('Error al obtener proyectos creados para el usuario: $e');
      // En caso de error, retornamos un stream vacío
      return const Stream.empty();
    }
  }

  /// Crea un nuevo proyecto en Firestore.
  ///
  /// Se utiliza [project.toMap()] para convertir el objeto a un mapa, se almacena
  /// y luego se actualiza el campo 'id' con el ID generado por Firestore.
  Future<bool> createProject(Project project) async {
    try {
      // Se agrega el proyecto a Firestore y se obtiene la referencia al documento creado.
      DocumentReference docRef = await projectsCollection.add(project.toMap());

      // Actualizamos el campo 'id' del documento con el ID generado.
      // await projectsCollection.doc(docRef.id).update({'id': docRef.id});

      return true;
    } catch (e) {
      print('Error al crear el proyecto: $e');
      return false;
    }
  }

  Future<bool> addUserToProject(
      String username, String projectId, UserInfoPopUp userinfo) async {
    try {
      // 1. Buscar el documento usando where
      QuerySnapshot projectQuery = await projectsCollection
          .where('projectid', isEqualTo: projectId)
          .get();

      if (projectQuery.docs.isEmpty) {
        print('Project not found');
        return false;
      }

      // 2. Obtener la referencia del primer documento encontrado
      DocumentReference docRef = projectQuery.docs.first.reference;

      // 3. Crear objeto miembro completo
      final newMember = {
        'memberid': username,
        'userinfo': userinfo.toMap(),
      };

      // 4. Actualización atómica usando arrayUnion
      await docRef.update({
        'members': FieldValue.arrayUnion([newMember])
      });

      return true;
    } catch (e) {
      print('Error adding user: $e');
      return false;
    }
  }

// Método para eliminar a un usuario de un proyecto
  Future<bool> removeUserFromProject(String username, String projectId) async {
    try {
      QuerySnapshot project = await projectsCollection
          .where('projectid', isEqualTo: projectId)
          .get();
      for (var doc in project.docs) {
        await doc.reference.update({
          // Remueve el username del array 'member'
          'members.member': FieldValue.arrayRemove([username]),
          // Remueve el campo con la key correspondiente al username dentro del mapa 'userinfo'
          'members.userinfo.${username}': FieldValue.delete(),
        });
      }
      return true;
    } catch (e) {
      // Puedes imprimir el error para debug
      print('Error al remover usuario: $e');
      return false;
    }
  }

  //Método para cancelar la invitación de un proyecto

  Future<bool> acceptPendingInvitation(
      String uid, bool value, String invitationRecipient) async {
    try {
      // 1. Buscar invitaciones dirigidas al usuario actual
      QuerySnapshot invitations = await messagesCollection
          .where('invitationUid', isEqualTo: uid)
          .where('accepted', isEqualTo: false)
          .where('to', isEqualTo: invitationRecipient)
          .get();

      if (invitations.docs.isEmpty) return false;

      for (var inviteDoc in invitations.docs) {
        await inviteDoc.reference.update({'accepted': value});
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removePendingInvitation(String uid, bool value) async {
    try {
      // 1. Buscar invitaciones dirigidas al usuario actual
      QuerySnapshot invitations = await messagesCollection
          .where('invitationUid', isEqualTo: uid)
          .where('accepted', isEqualTo: true)
          .get();

      if (invitations.docs.isEmpty) return false;

      for (var inviteDoc in invitations.docs) {
        await inviteDoc.reference.update({'accepted': value});
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Método para enviar mensaje
  Future<bool> sendProjectInvitation(
      {required String to,
      required String message,
      required String from,
      required String projectName,
      required String projectId}) async {
    try {
      await messagesCollection.add({
        'to': to,
        'from': from,
        'message': message,
        'accepted': false,
        'timestamp': FieldValue.serverTimestamp(),
        'projectName': projectName,
        'invitationUid': projectId
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<QuerySnapshot> getMessages(String username) {
    return FirebaseFirestore.instance
        .collection('messages')
        .where('to',
            isEqualTo: username) // Filtra los mensajes dirigidos al usuario
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  //check existence of user in followers in firestore
  Future<bool> checkIfUserExistsInFollowers(String uid, String username) async {
    try {
      final userCollection = FirebaseFirestore.instance.collection('userinfo');
      final userDoc = await userCollection.doc(uid).get();

      if (userDoc.exists) {
        final userDocData = userDoc.data() as Map<String, dynamic>;
        final followers = List<String>.from(userDocData['following'] ?? []);

        if (followers.contains(username)) {
          return true;
        } else {
          return false;
        }
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> followOrUnfollowUser(
      String uid, String username, context) async {
    try {
      final currentUserInfo =
          Provider.of<AuthProviderSapers>(context, listen: false).userInfo;
      final currentUserName = currentUserInfo?.username;

      // Obtener el UID del usuario objetivo (al que se está siguiendo)
      final targetUserQuery = await userCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (targetUserQuery.docs.isEmpty) {
        throw Exception("El usuario objetivo no existe");
      }
      final targetUid = targetUserQuery.docs.first.id;

      // Verificar si ya está siguiendo al usuario
      final userExists = await checkIfUserExistsInFollowers(uid, username);

      // Crear un batch para actualizar ambos documentos
      final batch = FirebaseFirestore.instance.batch();

      if (userExists) {
        // Dejar de seguir: eliminar de "following" y "followers"
        batch.update(userCollection.doc(uid), {
          'following': FieldValue.arrayRemove([username]),
        });
        batch.update(userCollection.doc(targetUid), {
          'followers': FieldValue.arrayRemove([currentUserName]),
        });
      } else {
        // Empezar a seguir: agregar a "following" y "followers"
        batch.update(userCollection.doc(uid), {
          'following': FieldValue.arrayUnion([username]),
        });
        batch.update(userCollection.doc(targetUid), {
          'followers': FieldValue.arrayUnion([currentUserName]),
        });
      }

      await batch.commit(); // Ejecutar ambas operaciones atómicamente
      return !userExists;
    } catch (e) {
      rethrow;
    }
  }

  // //Function to follow the user
  // Future<bool> followOrUnfollowUser(String uid, String username) async {
  //   try {
  //     final userExists = await checkIfUserExistsInFollowers(uid, username);
  //     if (userExists) {
  //       await userCollection.doc(uid).update({
  //         'following': FieldValue.arrayRemove([username])
  //       });
  //       return false; // Unfollow
  //     } else {
  //       await userCollection.doc(uid).update({
  //         'following': FieldValue.arrayUnion([username])
  //       });
  //       return true; // Follow
  //     }
  //   } catch (e) {
  //     rethrow;
  //   }
  // }

// Usar BehaviorSubject en lugar de StreamController
  final BehaviorSubject<List<SAPPost>> _postsSubject =
      BehaviorSubject<List<SAPPost>>.seeded([]);

  Future<List<SAPPost>> getPostsFollowingFuture() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      // Si no hay usuario, retornar una lista vacía
      return [];
    }

    final userDoc =
        await _firestore.collection('userinfo').doc(currentUser.uid).get();

    if (!userDoc.exists || !userDoc.data()!.containsKey('following')) {
      // Si no tiene campo 'following', retornar una lista vacía
      return [];
    }

    final List<String> following =
        List<String>.from(userDoc.data()!['following'] ?? []);

    if (following.isEmpty) {
      // Si no sigue a nadie, retornar una lista vacía
      return [];
    }

    final chunks = _chunkList(
        following, 10); // Dividimos la lista de seguidores en trozos de 10
    List<SAPPost> allPosts = [];

    for (final chunk in chunks) {
      final snapshot = await _firestore
          .collection('posts') // Asegúrate de usar la colección correcta
          .where('author', whereIn: chunk)
          .orderBy('timestamp', descending: true)
          // .limit(morePosts)
          .get();

      final posts = snapshot.docs.map((doc) {
        final data = doc.data();
        return SAPPost(
          id: doc.id,
          title: data['title'] ?? '',
          isExpert: data['isExpert'] ?? false,
          content: data['content'] ?? '',
          author: data['author'] ?? '',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          module: data['module'] ?? '',
          isQuestion: data['isQuestion'] ?? false,
          tags: List<String>.from(data['tags'] ?? []),
          attachments:
              List<Map<String, dynamic>>.from(data['attachments'] ?? []),
          replyCount: data['replyCount'] ?? 0,
        );
      }).toList();

      allPosts.addAll(posts);
    }

    // Ordenamos los posts por timestamp
    allPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return allPosts;
  }

  void dispose() {
    _postsSubject
        .close(); // Asegúrate de cerrar el BehaviorSubject cuando ya no sea necesario
  }

  List<List<String>> _chunkList(List<String> list, int chunkSize) {
    List<List<String>> chunks = [];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
          i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  //Método para obtener todos los tags de todos los posts
  Future<List<String>> getAllTags(int take) async {
    final snapshot = await postsCollection
        .where('lang', isEqualTo: LanguageProvider().currentLanguage)
        .get();

    // Flatten tags from all documents
    final allTags = snapshot.docs
        .expand((doc) => List<String>.from(
            (doc.data() as Map<String, dynamic>)['tags'] ?? []))
        .toList();

    // Count tag occurrences
    final tagCount = allTags.fold<Map<String, int>>({}, (map, tag) {
      map[tag] = (map[tag] ?? 0) + 1;
      return map;
    });
    List<dynamic> entries = tagCount.entries
        .map((entry) => {'tag': entry.key, 'count': entry.value})
        .toList();

    entries.sort((a, b) => b['count'].compareTo(a['count']));
    final result = entries.take(take);
    return result.map((entry) => entry['tag'].toString()).toList();
  }

  //Method to check if username exists
  Future<bool> checkIfUsernameExists(String username) async {
    try {
      final userQuery = await userCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return userQuery.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

// Método para obtener todos los posts una sola vez
  Future<List<SAPPost>> getPostsFuture() async {
    final snapshot = await postsCollection
        .where('lang', isEqualTo: LanguageProvider().currentLanguage)
        .orderBy('timestamp', descending: true)
        //.limit(morePosts)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SAPPost(
        id: doc.id,
        title: data['title'] ?? '',
        lang: data['lang'] ?? 'en',
        isExpert: data['isExpert'] ?? false,
        content: data['content'] ?? '',
        author: data['author'] ?? '',
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        module: data['module'] ?? '',
        isQuestion: data['isQuestion'] ?? false,
        tags: List<String>.from(data['tags'] ?? []),
        attachments: List<Map<String, dynamic>>.from(data['attachments'] ?? []),
        replyCount: data['replyCount'] ?? 0,
      );
    }).toList();
  }

  Future<List<SAPPost>> getPostsFutureByAuthor(username) async {
    final snapshot = await postsCollection
        .where('lang', isEqualTo: LanguageProvider().currentLanguage)
        .where('author', isEqualTo: username)
        .orderBy('timestamp', descending: true)
        //.limit(morePosts)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SAPPost(
        id: doc.id,
        title: data['title'] ?? '',
        lang: data['lang'] ?? 'en',
        isExpert: data['isExpert'] ?? false,
        content: data['content'] ?? '',
        author: data['author'] ?? '',
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        module: data['module'] ?? '',
        isQuestion: data['isQuestion'] ?? false,
        tags: List<String>.from(data['tags'] ?? []),
        attachments: List<Map<String, dynamic>>.from(data['attachments'] ?? []),
        replyCount: data['replyCount'] ?? 0,
      );
    }).toList();
  }

  Future<UserInfoPopUp?> getUserInfoByUsername(String username) async {
    // Verificar cache primero
    if (_userCache.containsKey(username)) {
      return _userCache[username];
    }

    try {
      final querySnapshot = await userCollection
          .where('username', isEqualTo: username)
          .limit(1) // Limitar a 1 resultado
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docSnapshot = querySnapshot.docs.first;
        final rawData = docSnapshot.data();
        if (rawData is Map<String, dynamic>) {
          final data = rawData;

          final userInfo = UserInfoPopUp(
            uid: data['uid'] ?? '',
            username: data['username'] ?? '',
            bio: data['bio'] ?? '',
            location: data['location'] ?? '',
            email: data['email'] ?? '',
            website: data['website'] ?? '',
            hourlyRate: (data['hourlyRate'] ?? 0).toDouble(),
            following: data['following'] != null
                ? List<String>.from(data['following'])
                : <String>[],
            followers: data['followers'] != null
                ? List<String>.from(data['followers'])
                : <String>[],
            joinDate: data['joinDate'] ?? Timestamp.fromDate(DateTime.now()),
            experience: data['experience'] ?? '',
            isExpert: data['isExpert'] ?? false,
          );

          _userCache[username] = userInfo;
          return userInfo;
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserInfoPopUp?> getUserInfoByEmail(String mail) async {
    try {
      final userCollection = FirebaseFirestore.instance.collection('userinfo');
      final cleanedEmail = mail.trim().toLowerCase();

      // Primera búsqueda: exacta y case-sensitive
      var querySnapshot = await userCollection
          .where('email', isEqualTo: cleanedEmail)
          .limit(1) // Optimización: solo necesitamos uno
          .get();

      // Si no hay resultados, intentar búsqueda case-insensitive
      if (querySnapshot.docs.isEmpty) {
        // Obtener todos los documentos que podrían coincidir
        querySnapshot = await userCollection
            .orderBy('email')
            .startAt([cleanedEmail])
            .endAt(['$cleanedEmail\uf8ff'])
            .limit(10) // Limitamos para evitar cargar demasiados docs
            .get();

        // Buscar coincidencia exacta ignorando mayúsculas/minúsculas
        for (var doc in querySnapshot.docs) {
          String docEmail = doc['email']?.toString().toLowerCase() ?? '';

          if (docEmail == cleanedEmail) {
            return _createUserInfoFromDoc(doc.data());
          }
        }
      } else {
        // Si encontramos directamente, crear el objeto

        return _createUserInfoFromDoc(querySnapshot.docs.first.data());
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

// Método separado para crear el objeto UserInfoPopUp
  UserInfoPopUp _createUserInfoFromDoc(Map<String, dynamic> data) {
    try {
      return UserInfoPopUp(
          uid: data['uid']?.toString() ?? '',
          username: data['username']?.toString() ?? '',
          bio: data['bio']?.toString() ?? '',
          location: data['location']?.toString() ?? '',
          email: data['email']?.toString().toLowerCase() ??
              '', // Aseguramos lowercase
          website: data['website']?.toString() ?? '',
          isAvailable: data['isAvailable'] as bool? ?? false,
          isExpert: data['isExpert'] as bool? ?? false,
          hourlyRate: (data['hourlyRate'] ?? 0.0).toDouble(),
          joinDate: Timestamp.fromDate(DateTime.now()),
          experience: data['experience']?.toString() ?? '',
          reviews: List<Map<String, dynamic>>.from(data['reviews'] ?? []),
          specialty: data['specialty']?.toString() ?? '');
    } catch (e) {
      rethrow;
    }
  }

  //Método para poner la info del usuario en firebase
  // Función para guardar la información del usuario en Firebase
  Future<void> saveUserInfo(UserInfoPopUp userInfo) async {
    try {
      final userCollection = FirebaseFirestore.instance.collection('userinfo');

      // Usar el uid del usuario como el ID del documento
      await userCollection.doc(userInfo.uid).set(userInfo.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Método para crear un nuevo post
  Future<void> createPost(SAPPost post) async {
    await postsCollection.add({
      'title': post.title,
      'content': post.content,
      'author': post.author,
      'timestamp': Timestamp.fromDate(post.timestamp),
      'module': post.module,
      'isQuestion': post.isQuestion,
      'lang': LanguageProvider().currentLanguage,
      'tags': post.tags,
      'attachments': post.attachments,
    });
  }

  Future<List<SAPPost>> getPostsByKeywordAI(String keyword) async {
    final snapshot = await postsCollection.get();
    final posts = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['timestamp'] is Timestamp) {
        data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
      }

      return SAPPost.fromMap(data, doc.id);
    }).toList();

    // Separar la frase en palabras clave
    final words = keyword.toLowerCase().split(RegExp(r'\s+'));

    return posts.where((post) {
      final content = post.content.toLowerCase();
      final title = post.title.toLowerCase();
      final author = post.author.toLowerCase();
      final tags = post.tags.map((t) => t.toLowerCase()).toList();

      return words.any((word) =>
          content.contains(word) ||
          title.contains(word) ||
          author.contains(word) ||
          tags.any((tag) => tag.contains(word)));
    }).toList();
  }

  Future<List<SAPPost>> getPostsByKeyword(String keyword) async {
    final snapshot =
        await postsCollection.get(); // Obtiene todos los documentos
    final posts = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Convertir timestamp antes de pasarlo a SAPPost
      if (data['timestamp'] is Timestamp) {
        data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
      }

      // Crear el objeto SAPPost a partir de los datos del documento
      return SAPPost.fromMap(data, doc.id);
    }).toList();

    // Filtrar los posts por la palabra clave (insensible a mayúsculas/minúsculas)
    return posts
        .where((post) =>
            (post.content.toLowerCase().contains(keyword.toLowerCase())) ||
            (post.title.toLowerCase().contains(keyword.toLowerCase())) ||
            (post.tags.contains(keyword.toLowerCase())) ||
            (post.author.toLowerCase().contains(keyword.toLowerCase())))
        .toList();
  }

  Future<List<SAPPost>> getPostsbyTag(String tag) async {
    final snapshot = await postsCollection
        .where('tags', arrayContains: tag)
        .orderBy('timestamp', descending: true)
        .get();

    if (snapshot.docs.isEmpty) {
      // Si no hay documentos, retornar una lista vacía
      return [];
    }

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SAPPost(
        id: doc.id,
        title: data['title'] ?? '',
        isExpert: data['isExpert'] ?? false,
        content: data['content'] ?? '',
        author: data['author'] ?? '',
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        module: data['module'] ?? '',
        isQuestion: data['isQuestion'] ?? false,
        tags: List<String>.from(data['tags'] ?? []),
        replyCount: data['replyCount'] ?? 0,
      );
    }).toList();
  }

  // Método para filtrar posts por módulo (consulta única)
  Future<List<SAPPost>> getPostsByModuleFuture(String module) async {
    final snapshot = await postsCollection
        .where('module', isEqualTo: module)
        .where('lang', isEqualTo: LanguageProvider().currentLanguage)
        .orderBy('timestamp', descending: true)
        .get();

    if (snapshot.docs.isEmpty) {
      // Si no hay documentos, retornar una lista vacía
      return [];
    }

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SAPPost(
        id: doc.id,
        title: data['title'] ?? '',
        isExpert: data['isExpert'] ?? false,
        content: data['content'] ?? '',
        author: data['author'] ?? '',
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        module: data['module'] ?? '',
        isQuestion: data['isQuestion'] ?? false,
        tags: List<String>.from(data['tags'] ?? []),
        replyCount: data['replyCount'] ?? 0,
      );
    }).toList();
  }

  // Método para buscar posts
  Stream<List<SAPPost>> searchPosts(String searchTerm) {
    return postsCollection
        .where('lang', isEqualTo: LanguageProvider().currentLanguage)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SAPPost(
            id: doc.id,
            title: data['title'] ?? '',
            content: data['content'] ?? '',
            isExpert: data['isExpert'] ?? false,
            author: data['author'] ?? '',
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            module: data['module'] ?? '',
            isQuestion: data['isQuestion'] ?? false,
            tags: List<String>.from(data['tags'] ?? []),
            replyCount: data['replyCount'] ?? 0);
      }).where((post) {
        return post.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
            post.content.toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getAttachments(String projectId) async {
    var storage = FirebaseStorage.instance;
    List<Map<String, dynamic>> attachmentsList = [];
    try {
      Reference ref = storage.ref().child('projects').child(projectId);
      ListResult listFiles = await ref.listAll();
      for (var fileRef in listFiles.items) {
        final metadata = await fileRef.getMetadata();

        // Obtener URL de descarga
        final downloadUrl = await fileRef.getDownloadURL();

        // Agregar a la lista con información relevante
        attachmentsList.add({
          'name': fileRef.name,
          'url': downloadUrl,
          'type': metadata.contentType ?? 'file', // Tipo MIME
          'extension': metadata.name?.split('.').last ?? 'file' // Extensión
        });
      }
      return attachmentsList;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> pickAndUploadFileProject(
      String projectId, String username) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
    );

    final List<PlatformFile>? files = result?.files;
    final List<Map<String, dynamic>> attachments = [];

    if (files != null) {
      await Future.forEach(files, (PlatformFile platformFile) async {
        try {
          final String fileName = platformFile.name;
          final Uint8List? fileBytes = await _getFileBytes(platformFile);

          if (fileBytes != null && fileBytes.isNotEmpty) {
            final uploadedFile = await uploadAttachmentProject(
              projectId: projectId,
              fileBytes: fileBytes,
              uploadedBy: username,
              fileName: fileName,
            );

            if (uploadedFile != null) {
              attachments.add(uploadedFile);
            }
          }
        } catch (e) {
          debugPrint('Error procesando archivo ${platformFile.name}: $e');
        }
      });
    }
    return attachments;
  }

  Future<Uint8List?> _getFileBytes(PlatformFile platformFile) async {
    if (kIsWeb) {
      return platformFile.bytes;
    } else {
      final File file = File(platformFile.path!);
      return file.readAsBytes();
    }
  }

  Future<Map<String, dynamic>?> uploadAttachmentProject({
    required String projectId,
    required String uploadedBy,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final storage = FirebaseStorage.instance;

      // Crear referencia con la misma estructura
      final Reference ref =
          storage.ref().child('projects').child(projectId).child(fileName);

      // Determinar tipo MIME
      final String fileExtension = fileName.split('.').last.toLowerCase();
      final String? mimeType = _getMimeType(fileExtension);

      // Configurar metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'uploadedBy': uploadedBy, // Agregar ID de usuario si es necesario
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Subir usando putData para compatibilidad multiplataforma
      final UploadTask uploadTask = ref.putData(fileBytes, metadata);
      final TaskSnapshot taskSnapshot = await uploadTask;

      // Obtener URL pública
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return {
        'name': fileName,
        'url': downloadUrl,
        'type': mimeType ?? 'file',
        'extension': fileExtension,
        'size': taskSnapshot.bytesTransferred,
      };
    } catch (e) {
      debugPrint('Error subiendo archivo $fileName: $e');
      return null;
    }
  }

  String? _getMimeType(String extension) {
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'txt': 'text/plain',
      'zip': 'application/zip',
    };
    return mimeTypes[extension];
  }

  Future<List<Map<String, dynamic>>> addAttachments(String postId,
      String replyId, String author, List<PlatformFile> selectedFiles) async {
    var storage = FirebaseStorage.instance;
    List<Map<String, dynamic>> attachmentsList = [];

    try {
      for (PlatformFile file in selectedFiles) {
        final bytes = file.bytes;
        if (bytes == null) {
          continue;
        }

        String fileName = file.name;
        String imageName = fileName.substring(0, fileName.lastIndexOf('.'));

        Reference ref =
            storage.ref().child('posts').child(postId).child(fileName);

        try {
          // Subir archivo a Firebase Storage
          TaskSnapshot taskSnapshot = await ref.putData(
            bytes,
            SettableMetadata(
              contentType: UtilsSapers().getContentType(fileName),
              customMetadata: {
                'name': imageName,
                'uploadDate': DateTime.now().toIso8601String(),
              },
            ),
          );

          // Obtener URL de descarga
          final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

          // Crear el attachment
          Map<String, dynamic> attachment = {
            'url': downloadUrl,
            'name': imageName,
            'fileName': fileName,
            'uploadDate': DateTime.now(),
            'replyId': replyId,
            'author': author
          };
          attachmentsList.add(attachment);

          // Verificar si el documento del post existe en Firestore
          DocumentReference postRef =
              FirebaseFirestore.instance.collection('posts').doc(postId);
          DocumentSnapshot postSnapshot = await postRef.get();

          if (postSnapshot.exists) {
            // Si existe, actualizar el campo de attachments
            await postRef.update({
              'attachments': FieldValue.arrayUnion([attachment]),
            });
          } else {
            // Si no existe, crear el documento y agregar el attachment
            // await postRef.set({
            //   'attachments': [attachment],
            //   'createdAt': DateTime.now(),
            // });
          }
        } catch (e) {}
      }
    } catch (e) {}

    return attachmentsList;
  }

  Future<void> addReview(String username, String review, double rating) async {
    try {
      final userCollection = FirebaseFirestore.instance.collection('userinfo');

      // Realizar una consulta para encontrar el documento donde `username` coincida
      final querySnapshot =
          await userCollection.where('username', isEqualTo: username).get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Usuario no encontrado');
      }

      // Suponiendo que `username` es único, seleccionamos el primer documento
      final docId = querySnapshot.docs.first.id;

      final reviewMap = {
        'review': review,
        'rating': rating,
        'timestamp':
            DateTime.now().toIso8601String(), // Usamos un timestamp local
      };

      // Actualizar el campo `reviews` del documento encontrado
      await userCollection.doc(docId).update({
        'reviews': FieldValue.arrayUnion([reviewMap]),
      });
    } catch (e) {
      rethrow; // Opcional: para propagar el error al código llamante
    }
  }

  Stream<QuerySnapshot> getReviews(String username) {
    return FirebaseFirestore.instance
        .collection('userinfo')
        .where('username', isEqualTo: username)
        .snapshots(); // Escucha cambios en el documento donde el username coincide
  }

  Stream<List<SAPReply>> getRepliesForPost(String postId) {
    try {
      return FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('replies')
          // .orderBy('timestamp', descending: true)
          .orderBy('replyVotes', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                try {
                  final data = doc.data();
                  // Asegurarse de que data sea un Map<String, dynamic>
                  data['id'] = doc.id;
                  data['postId'] = postId;
                  // Procesar la lista de attachments (si existe)
                  final attachments =
                      (data['attachments'] as List<dynamic>? ?? [])
                          .map((e) => e as Map<String, dynamic>)
                          .toList();
                  data['attachments'] = attachments;
                  return SAPReply.fromMap(data);
                } catch (e) {
                  // Retornar un objeto válido con valores por defecto
                  return SAPReply(
                    id: doc.id,
                    author: 'Anonymous',
                    content: '',
                    timestamp: DateTime.now(),
                    repliedBy: [],
                    replyVotes: 0,
                    attachments: [],
                    postId: postId,
                  );
                }
              }).toList());
    } catch (e) {
      // Retornar un stream vacío en caso de error
      return Stream.value([]);
    }
  }

  // Verifica si el usuario actual ha dado like
  Future<bool> hasUserLiked(String postId, String replyId, context) async {
    try {
      final userInfo =
          Provider.of<AuthProviderSapers>(context, listen: false).userInfo;
      if (userInfo == null) return false;

      final doc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('replies')
          .doc(replyId)
          .get();

      if (!doc.exists) return false;

      final likes = doc.data()?['likes'] as Map<String, dynamic>? ?? {};
      return likes.containsKey(userInfo.username);
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  // Toggle like
  Future<void> toggleLike(String postId, String replyId, context) async {
    try {
      final userInfo =
          Provider.of<AuthProviderSapers>(context, listen: false).userInfo;
      ;
      if (userInfo == null) throw Exception('Usuario no autenticado');

      final replyRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('replies')
          .doc(replyId);

      return _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(replyRef);
        if (!doc.exists) throw Exception('Reply no encontrada');

        final likes = Map<String, dynamic>.from(
            doc.data()?['likes'] as Map<String, dynamic>? ?? {});
        final currentLikeCount = doc.data()?['likeCount'] ?? 0;

        if (likes.containsKey(userInfo.username)) {
          // Quitar like
          likes.remove(userInfo.username);
          transaction.update(replyRef, {
            'likes': likes,
            'likeCount': currentLikeCount - 1,
          });
        } else {
          // Añadir like
          likes[userInfo.username] = ReplyLike(
            userId: userInfo.username,
            timestamp: DateTime.now(),
          ).toMap();

          transaction.update(replyRef, {
            'likes': likes,
            'likeCount': currentLikeCount + 1,
          });
        }
      });
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  Future<void> createReply(
    String username,
    String postId,
    String content,
    int replyCount, {
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final reply = {
        'author': username ?? 'Anonymous',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'attachments': attachments ?? [],
        'replyVotes': 0,
      };

      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Añadir la respuesta a la subcolección
        transaction.set(
          postRef.collection('replies').doc(),
          reply,
        );

        // Actualizar el contador de respuestas en el post principal
        transaction.update(postRef, {
          'replyCount':
              FieldValue.increment(1), // Usar increment para evitar conflictos
        });
      });
    } catch (e) {
      rethrow; // Relanzar el error para manejarlo en la UI
    }
  }

  // Gamification Methods
  
  Future<void> updateUserReputation(String userId, int points) async {
    try {
      await userCollection.doc(userId).update({
        'reputation': FieldValue.increment(points),
        'weeklyPoints': FieldValue.increment(points)
      });
      await _checkAndUpdateLevel(userId);
    } catch (e) {
      print('Error updating reputation: $e');
    }
  }

  Future<void> _checkAndUpdateLevel(String userId) async {
    try {
      final userDoc = await userCollection.doc(userId).get();
      final data = userDoc.data() as Map<String, dynamic>?;
  final reputation = data?['reputation'] ?? 0;
      
      String newLevel = 'Beginner';
      if (reputation >= 1000) newLevel = 'Expert';
      else if (reputation >= 500) newLevel = 'Advanced';
      else if (reputation >= 100) newLevel = 'Intermediate';

      final data = userDoc.data() as Map<String, dynamic>?;
  if (data?['level'] != newLevel) {
        await userCollection.doc(userId).update({'level': newLevel});
        _notifyLevelUp(userId, newLevel);
      }
    } catch (e) {
      print('Error checking level: $e');
    }
  }

  Future<void> _notifyLevelUp(String userId, String newLevel) async {
    try {
      await messagesCollection.add({
        'to': userId,
        'type': 'achievement',
        'message': 'Congratulations! You\'ve reached $newLevel level!',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending level up notification: $e');
    }
  }

  Future<void> updateModuleExpertise(String userId, String module, int points) async {
    try {
      await userCollection.doc(userId).update({
        'moduleExpertise.$module': FieldValue.increment(points)
      });
    } catch (e) {
      print('Error updating module expertise: $e');
    }
  }

  Stream<List<UserInfoPopUp>> getTopContributors() {
    return userCollection
        .orderBy('weeklyPoints', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserInfoPopUp.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  void subscribeToUserAchievements(String userId, Function(String) onAchievement) {
    messagesCollection
        .where('to', isEqualTo: userId)
        .where('type', isEqualTo: 'achievement')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
  if (data?['message'] != null) {
    onAchievement(data!['message'] as String);
  }
      }
    });
  }

  Future<void> resetWeeklyPoints() async {
    final batch = _firestore.batch();
    final users = await userCollection.get();
    
    for (var user in users.docs) {
      batch.update(user.reference, {'weeklyPoints': 0});
    }
    
    await batch.commit();
  }

  Future<void> awardBadge(String userId, String badge) async {
    try {
      await userCollection.doc(userId).update({
        'badges': FieldValue.arrayUnion([badge])
      });
      
      await messagesCollection.add({
        'to': userId,
        'type': 'achievement',
        'message': 'You\'ve earned the $badge badge!',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error awarding badge: $e');
    }
  }
}
