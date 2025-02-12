import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  const ProfileAvatar({
    super.key,
    required this.seed,
    this.isProfileMenuButton = false,
    this.size = TwitterDimensions.avatarSizeMedium,
    this.userInfoPopUp,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        //backgroundColor: TwitterColors.primary.withOpacity(0.1),
        radius: size / 2,
        child: AppStyles.showAvatars == true
            ? RandomAvatar(
                seed.isNotEmpty ? seed : 'U',
                height: size,
                width: size,
              )
            : isProfileMenuButton == true
                ? Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(seed.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            fontSize: AppStyles.fontSize,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  )
                : Center(
                    child: InkWell(
                      onTap: () async {
                        if (userInfoPopUp != null) {
                          bool isUserLoggedIn =
                              AuthService().isUserLoggedIn(context);

                          if (isUserLoggedIn) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                return UserProfilePage(userinfo: userInfoPopUp);
                              },
                            ));
                          }
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(seed.substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              fontSize: AppStyles.fontSize,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                  ),
      ),
    );
  }
}
