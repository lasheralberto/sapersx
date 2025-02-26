import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:sapers/components/screens/user_profile.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/user.dart';

class ProfileAvatar extends StatelessWidget {
  final String seed;
  final double size;
  final bool showBorder;
  final UserInfoPopUp? userInfoPopUp;
  final bool? isProfileMenuButton;
  final Widget Function(BuildContext, String)? childBuilder;

  const ProfileAvatar({
    super.key,
    required this.seed,
    this.isProfileMenuButton = false,
    this.size = TwitterDimensions.avatarSizeMedium,
    this.userInfoPopUp,
    this.showBorder = false,
    this.childBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      // Añadido RepaintBoundary principal
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: showBorder == true
                ? AppStyles.colorAvatarBorder
                : const Color.fromARGB(255, 150, 202, 237),
            width: 4,
          ),
        ),
        child: CircleAvatar(
          radius: size / 2,
          child: AppStyles.showAvatars == true
              ? RandomAvatar(
                  seed.isNotEmpty ? seed : 'U',
                  height: size,
                  width: size,
                )
              : isProfileMenuButton == true
                  ? _buildTextAvatar(context)
                  : _buildClickableAvatar(context),
        ),
      ),
    );
  }

  Widget _buildTextAvatar(BuildContext context) {
    return RepaintBoundary(
      // RepaintBoundary para el contenido estático
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: _buildTextContent(context),
      ),
    );
  }

  Widget _buildClickableAvatar(BuildContext context) {
    return RepaintBoundary(
      // RepaintBoundary para el contenido interactivo
      child: InkWell(
        onTap: () async {
          if (userInfoPopUp != null) {
            bool isUserLoggedIn = AuthService().isUserLoggedIn(context);
            if (isUserLoggedIn) {
              context.push('/profile/${userInfoPopUp!.username}');
            }
          }
        },
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: _buildTextContent(context),
        ),
      ),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    final textContent = seed.substring(0, 2).toUpperCase();

    return childBuilder != null
        ? childBuilder!(context, textContent)
        : FittedBox(
            // FittedBox para escalado dinámico
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.all(size * 0.1),
              child: Text(
                textContent,
                style: TextStyle(
                  fontSize: size * 0.4, // Tamaño relativo al avatar
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          );
  }
}
