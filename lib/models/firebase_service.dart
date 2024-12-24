// firebase_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/user_reviews.dart';
import 'package:rxdart/rxdart.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final CollectionReference postsCollection =
      FirebaseFirestore.instance.collection('posts');
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('userinfo');
  final CollectionReference repliesCollection =
      FirebaseFirestore.instance.collection('replies');

  // Cache para información de usuarios
  final Map<String, UserInfoPopUp> _userCache = {};

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
      print('Error al seguir al usuario: $e');
      rethrow;
    }
  }

  //Function to follow the user
  Future<bool> followOrUnfollowUser(String uid, String username) async {
    try {
      final userExists = await checkIfUserExistsInFollowers(uid, username);
      if (userExists) {
        await userCollection.doc(uid).update({
          'following': FieldValue.arrayRemove([username])
        });
        return false; // Unfollow
      } else {
        await userCollection.doc(uid).update({
          'following': FieldValue.arrayUnion([username])
        });
        return true; // Follow
      }
    } catch (e) {
      print('Error al seguir al usuario: $e');
      rethrow;
    }
  }

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
          .limit(50)
          .get();

      final posts = snapshot.docs.map((doc) {
        final data = doc.data();
        return SAPPost(
          id: doc.id,
          title: data['title'] ?? '',
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

// Método para obtener todos los posts una sola vez
  Future<List<SAPPost>> getPostsFuture() async {
    final snapshot = await postsCollection
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SAPPost(
        id: doc.id,
        title: data['title'] ?? '',
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
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        final userInfo = UserInfoPopUp(
          uid: data['uid'] ?? '',
          username: data['username'] ?? '',
          bio: data['bio'] ?? '',
          location: data['location'] ?? '',
          email: data['email'] ?? '',
          website: data['website'] ?? '',
        );

        // Guardar en cache
        _userCache[username] = userInfo;
        return userInfo;
      }
      return null;
    } catch (e) {
      print('Error al obtener información del usuario: $e');
      rethrow;
    }
  }

  Future<UserInfoPopUp?> getUserInfoByEmail(String mail) async {
    try {
      final userCollection = FirebaseFirestore.instance.collection('userinfo');
      final cleanedEmail = mail.trim().toLowerCase();

      print('DEBUG: Iniciando búsqueda para email: $cleanedEmail');

      // Primera búsqueda: exacta y case-sensitive
      var querySnapshot = await userCollection
          .where('email', isEqualTo: cleanedEmail)
          .limit(1) // Optimización: solo necesitamos uno
          .get();

      print(
          'DEBUG: Resultado búsqueda exacta: ${querySnapshot.docs.length} documentos');

      // Si no hay resultados, intentar búsqueda case-insensitive
      if (querySnapshot.docs.isEmpty) {
        print('DEBUG: Intentando búsqueda case-insensitive');

        // Obtener todos los documentos que podrían coincidir
        querySnapshot = await userCollection
            .orderBy('email')
            .startAt([cleanedEmail])
            .endAt(['$cleanedEmail\uf8ff'])
            .limit(10) // Limitamos para evitar cargar demasiados docs
            .get();

        print('DEBUG: Resultados encontrados: ${querySnapshot.docs.length}');

        // Buscar coincidencia exacta ignorando mayúsculas/minúsculas
        for (var doc in querySnapshot.docs) {
          String docEmail = doc['email']?.toString().toLowerCase() ?? '';
          print('DEBUG: Comparando con documento email: $docEmail');

          if (docEmail == cleanedEmail) {
            print('DEBUG: ¡Coincidencia encontrada!');
            return _createUserInfoFromDoc(doc.data());
          }
        }
      } else {
        // Si encontramos directamente, crear el objeto
        print('DEBUG: Usando resultado de búsqueda exacta');
        return _createUserInfoFromDoc(querySnapshot.docs.first.data());
      }

      print(
          'DEBUG: No se encontró ninguna coincidencia para el email: $cleanedEmail');
      return null;
    } catch (e) {
      print('ERROR: Excepción al buscar usuario: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

// Método separado para crear el objeto UserInfoPopUp
  UserInfoPopUp _createUserInfoFromDoc(Map<String, dynamic> data) {
    print('DEBUG: Creando UserInfoPopUp con datos: $data');

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
          joinDate: data['joinDate']?.toString() ?? DateTime.now().toString(),
          experience: data['experience']?.toString() ?? '',
          reviews: List<Map<String, dynamic>>.from(data['reviews'] ?? []),
          specialty: data['specialty']?.toString() ?? '');
    } catch (e) {
      print('ERROR: Error al crear UserInfoPopUp: $e');
      print('ERROR: Datos problemáticos: $data');
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

      print('Información del usuario guardada correctamente');
    } catch (e) {
      print('Error al guardar la información del usuario: $e');
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
      'tags': post.tags,
      'attachments': post.attachments,
    });
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
            post.content.toLowerCase().contains(keyword.toLowerCase()))
        .toList();
  }

  // Método para filtrar posts por módulo (consulta única)
  Future<List<SAPPost>> getPostsByModuleFuture(String module) async {
    final snapshot = await postsCollection
        .where('module', isEqualTo: module)
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
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SAPPost(
            id: doc.id,
            title: data['title'] ?? '',
            content: data['content'] ?? '',
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

  Future<List<Map<String, dynamic>>> addAttachments(
      String postId, String replyId, List<PlatformFile> selectedFiles) async {
    var storage = FirebaseStorage.instance;
    List<Map<String, dynamic>> attachmentsList = [];

    try {
      for (PlatformFile file in selectedFiles) {
        final bytes = file.bytes;
        if (bytes == null) {
          print('Error: No se pudieron obtener los bytes del archivo');
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

          print('Archivo subido exitosamente: $fileName');
        } catch (e) {
          print('Error al subir el archivo $fileName: $e');
        }
      }
    } catch (e) {
      print('Error general: $e');
    }

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
      print('Error al añadir la reseña: $e');
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
          .orderBy('timestamp', descending: true)
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
                  print('Error processing document ${doc.id}: $e');
                  // Retornar un objeto válido con valores por defecto
                  return SAPReply(
                    id: doc.id,
                    author: 'Anonymous',
                    content: '',
                    timestamp: DateTime.now(),
                    attachments: [],
                    postId: postId,
                  );
                }
              }).toList());
    } catch (e) {
      print('Error in getRepliesForPost: $e');
      // Retornar un stream vacío en caso de error
      return Stream.value([]);
    }
  }

  Future<void> createReply(
    String postId,
    String content,
    int replyCount, {
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final reply = {
        'author': user.email ?? 'Anonymous',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'attachments': attachments ?? [],
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
      print('Error creating reply: $e');
      rethrow; // Relanzar el error para manejarlo en la UI
    }
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //Comprobar que el usuario está logueado
  bool isUserLoggedIn(context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => const LoginDialog(),
      );
      return false;
    } else {
      return true;
    }
  }

  // Iniciar sesión con email y contraseña
  Future<User?> signIn(String email, String password) async {
    var emailCleaned = email.trim().toLowerCase();
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user; // Devuelve el usuario logueado
    } on FirebaseAuthException catch (e) {
      // Manejo específico de errores de Firebase Authentication
      switch (e.code) {
        case 'invalid-email':
          print('El formato del email es inválido.');
          break;
        case 'user-not-found':
          print('No existe un usuario con este email.');
          break;
        case 'wrong-password':
          print('La contraseña ingresada es incorrecta.');
          break;
        case 'user-disabled':
          print('Esta cuenta ha sido deshabilitada.');
          break;
        case 'too-many-requests':
          print('Demasiados intentos. Inténtalo de nuevo más tarde.');
          break;
        case 'operation-not-allowed':
          print(
              'El inicio de sesión con email y contraseña no está habilitado.');
          break;
        default:
          print('Error desconocido: ${e.code}');

          return null;
      }

      // Opcional: lanzar una excepción personalizada para manejar en el UI
      throw Exception('Error al iniciar sesión: ${e.message}');
    } catch (e) {
      // Capturar otros errores no específicos de Firebase
      print('Error inesperado: $e');
      rethrow;
    }
  }

  Future<bool> signUp(String email, String pass) async {
    try {
      print('Intentando signup con email: $email');
      var emailCleaned = email.trim().toLowerCase();
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailCleaned, password: pass);
      print('Signup exitoso. Usuario: ${userCredential.user?.uid}');
      // Añadir delay
      await Future.delayed(const Duration(seconds: 3));
      return userCredential.user != null;
    } on FirebaseAuthException catch (e) {
      print('Error en signup: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class UtilsSapers {
  List<Map<String, dynamic>> convertPlatformFilesToAttachments(
      List<PlatformFile> files) {
    return files
        .map((file) => {
              'name': file.name,
              'size': file.size,
              'type': file.extension ?? 'unknown',
              // You might want to generate a temporary URL or handle this differently
              //'url': file.path ?? '',
            })
        .toList();
  }

  Future<dynamic> pickFiles(selectedFiles, context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', '.jpg', '.jpeg', '.png'],
        allowMultiple: true,
      );

      if (result != null) {
        selectedFiles.addAll(result.files);
        return selectedFiles;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(Texts.translate('filePickError', globalLanguage))),
      );
    }
  }

  String userUniqueUid(String email) {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  //Función para obtener un id unico para las replies de los posts basado en el usuario loguado y la fecha
  String getReplyId(context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return '';
    } else {
      return user.uid + DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// Método para formatear fecha
  String formatDateString(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'Invalid Date'; // En caso de error
    }
  }

  /// Método para formatear fecha
  String formatDateStringWithTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd/MM/yyyy hh:mm').format(dateTime);
    } catch (e) {
      return 'Invalid Date'; // En caso de error
    }
  }

  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return Texts.translate('now', globalLanguage);
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String getContentType(String fileName) {
    String ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
