import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:sapers/models/styles.dart';

class ProfileAvatar extends StatelessWidget {
  final String seed;
  final double size;
  final bool showBorder;

  const ProfileAvatar({
    super.key,
    required this.seed,
    this.size = TwitterDimensions.avatarSizeMedium,
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
              : AppStyles.colorAvatarBorderLighter,
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
            : Center(
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
    );
  }
}
