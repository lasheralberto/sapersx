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
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppStyles.colorAvatarBorder,
                width: 4,
              ),
            )
          : null,
      child: CircleAvatar(
        //backgroundColor: TwitterColors.primary.withOpacity(0.1),
        radius: size / 2,
        child: RandomAvatar(
          seed.isNotEmpty ? seed : 'U',
          height: size,
          width: size,
        ),
      ),
    );
  }
}
