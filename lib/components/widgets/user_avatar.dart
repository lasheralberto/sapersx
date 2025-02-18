import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/screens/user_profile.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/main.dart' as main;
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/texts.dart';
import '../screens/login_dialog.dart';
import 'package:sapers/models/auth_utils.dart' as zauth;

class UserAvatar extends StatelessWidget {
  final User? user;

  UserAvatar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Si no hay un usuario autenticado, mostramos el icono de login
    if (user == null) {
      if (1 == 1) {
        return IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => _showLoginDialog(context),
        );
      }
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
    return Consumer<zauth.AuthProvider>(
      builder: (context, authProvider, child) {
        // Si los datos del usuario están disponibles, mostramos el avatar
        if (authProvider.userInfo != null) {
          final user = authProvider.userInfo!;
          var userAvatar = user.email;

          return PopupMenuButton(
            child: ProfileAvatar(
              isProfileMenuButton: true,
              userInfoPopUp: user,
              size: AppStyles.avatarSize,
              seed: userAvatar,
              showBorder: user.isExpert as bool,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: GestureDetector(
                  child: Text(user.email),
                  onTap: () {
                    context.push('/profile/${user.username}');
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
