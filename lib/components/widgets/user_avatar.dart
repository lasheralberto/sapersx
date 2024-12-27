import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/screens/user_profile.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/main.dart' as main;
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/texts.dart';
import '../screens/login_dialog.dart';

class UserAvatar extends StatelessWidget {
  final User? user;

  UserAvatar({super.key, required this.user});

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
    return _buildUserAvatar(context);
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LoginDialog(),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return Consumer<main.AuthProvider>(
      builder: (context, authProvider, child) {
        // Si los datos del usuario están disponibles, mostramos el avatar
        if (authProvider.userInfo != null) {
          final user = authProvider.userInfo!;
          var userAvatar = user.email;

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
                child:
                    Text(Texts.translate('cerrarSesion', main.globalLanguage)),
              ),
            ],
          );
        } else {
          // Cargar la información del usuario una sola vez
          authProvider.loadUserInfo(user!);
          return const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
