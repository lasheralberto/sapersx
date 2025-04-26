import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/screens/user_profile.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/main.dart' as main;
import 'package:sapers/models/auth_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/texts.dart';
import '../screens/login_dialog.dart';
import 'package:sapers/models/auth_provider.dart' as zauth;

class UserAvatar extends StatelessWidget {
  final User? user;
  final double size;

  const UserAvatar({super.key, required this.user, this.size = 36});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return IconButton(
        icon: const Icon(Icons.account_circle_outlined),
        onPressed: () => _showLoginDialog(context),
      );
    }

    return _buildUserAvatar(context);
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LoginScreen(),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return Consumer<zauth.AuthProviderSapers>(
      builder: (context, authProvider, child) {
        if (authProvider.userInfo != null) {
          final user = authProvider.userInfo!;
          
          return PopupMenuButton(
            onSelected: (value) async {
              if (value == 'profile') {
                // Usar push para mantener el historial
                await Future.delayed(Duration.zero); // Pequeño delay para cerrar el menú
                context.push('/profile/${user.username}');
              } else if (value == 'logout') {
                AuthService().signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user.email),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: Text(
                    Texts.translate('cerrarSesion', LanguageProvider().currentLanguage),
                  ),
                ),
              ),
            ],
            child: ProfileAvatar(
              isProfileMenuButton: true,
              userInfoPopUp: user,
              size: this.size.toDouble(),
              seed: user.email,
              showBorder: user.isExpert as bool,
            ),
          );
        } else {
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