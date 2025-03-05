
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sapers/components/screens/login_dialog.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //Comprobar que el usuario está logueado
  bool isUserLoggedIn(context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => const LoginScreen(),
        ),
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
          break;
        case 'user-not-found':
          break;
        case 'wrong-password':
          break;
        case 'user-disabled':
          break;
        case 'too-many-requests':
          break;
        case 'operation-not-allowed':
          break;
        default:
          return null;
      }

      // Opcional: lanzar una excepción personalizada para manejar en el UI
      throw Exception('Error al iniciar sesión: ${e.message}');
    } catch (e) {
      // Capturar otros errores no específicos de Firebase

      rethrow;
    }
  }

  Future<bool> signUp(String email, String pass) async {
    try {
      var emailCleaned = email.trim().toLowerCase();
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailCleaned, password: pass);

      // Añadir delay
      await Future.delayed(const Duration(seconds: 3));
      return userCredential.user != null;
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
