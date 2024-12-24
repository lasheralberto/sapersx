import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sapers/components/screens/user_profile.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';

import '../screens/login_dialog.dart';

class UserAvatar extends StatelessWidget {
  final User? user; // Parámetro que recibimos de Feed u otro widget

  const UserAvatar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Si no hay un usuario autenticado, mostramos el icono de login
    if (user == null) {
      return IconButton(
        icon: const Icon(Icons.account_circle_outlined),
        onPressed: () => _showLoginDialog(context),
      );
    }

    // Si hay un usuario autenticado, mostramos el avatar del usuario
    return _buildUserAvatar(user!);
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LoginDialog(),
    );
  }

  Widget _buildUserAvatar(User firebaseUser) {
    // Usamos un StreamBuilder para escuchar los cambios en la autenticación
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .authStateChanges(), // Escucha cambios en el estado de autenticación
      builder: (context, snapshot) {
        // Mientras se obtiene la información, mostramos un indicador de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(),
          );
        }

        // Si hay un error o no hay datos, mostramos el icono de login
        if (snapshot.hasError || !snapshot.hasData) {
          return IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _showLoginDialog(context),
          );
        }

        final firebaseUser =
            snapshot.data!; // Aquí obtenemos el usuario autenticado

        // Usamos un FutureBuilder para obtener la información del usuario desde Firebase
        return FutureBuilder<UserInfoPopUp?>(
          future: FirebaseService().getUserInfoByEmail(firebaseUser.email!),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(),
              );
            }

            if (userSnapshot.hasError || userSnapshot.data == null) {
              return IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () => _showLoginDialog(context),
              );
            }

            final user = userSnapshot.data!;
            var userAvatar = user.email;

            // Aquí renderizamos el avatar y los menús del usuario
            return PopupMenuButton(
              child: ProfileAvatar(
                size: AppStyles.avatarSize,
                seed: userAvatar,
                showBorder: true,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: GestureDetector(
                    child: Text(user.email),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(userinfo: user),
                        ),
                      );
                    },
                  ),
                ),
                PopupMenuItem(
                  onTap: () => AuthService().signOut(),
                  child: Text(Texts.translate('cerrarSesion', globalLanguage)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
