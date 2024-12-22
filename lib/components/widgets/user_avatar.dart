// user_avatar.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:sapers/components/screens/user_profile.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/components/widgets/profile_header.dart';

import '../screens/login_dialog.dart';

class UserAvatar extends StatefulWidget {
  const UserAvatar({super.key});

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  AuthService? _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(); // Asumiendo que tienes una clase AuthService
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LoginDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(),
          );
        }

        final firebaseUser = snapshot.data;

        if (firebaseUser == null) {
          return IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _showLoginDialog(context),
          );
        }

        return _buildUserAvatar(firebaseUser);
      },
    );
  }

  Widget _buildUserAvatar(User firebaseUser) {
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
                        builder: (context) => UserProfilePage(userinfo: user)),
                  );
                },
              ),
            ),
            PopupMenuItem(
              onTap: () => _authService!.signOut(),
              child: Text(Texts.translate('cerrarSesion', globalLanguage)),
            ),
          ],
        );
      },
    );
  }
}
