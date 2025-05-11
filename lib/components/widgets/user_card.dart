import 'package:flutter/material.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/styles.dart';

class UserCard extends StatelessWidget {
  final UserInfoPopUp user;
  final VoidCallback onTap;

  const UserCard({
    Key? key,
    required this.user,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con avatar y nombre
                Row(
                  children: [
                    UserProfileCardHover(
                      authorUsername: user.username,
                      isExpert: user.isExpert as bool,
                      onProfileOpen: () {},
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user.specialty?.isNotEmpty ?? false)
                            Text(
                              user.specialty!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (user.isExpert == true)
                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                  ],
                ),

                const SizedBox(height: 8),

                // Información adicional
                if (user.specialty?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.category_outlined,
                    user.specialty!,
                    iconColor: AppStyles.colorAvatarBorder,
                    isHighlighted: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ],
                if (user.location?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    user.location!,
                    iconColor: Colors.redAccent,
                  ),
                ],
                if (user.bio?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(
                    user.bio!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (user.website?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.link_outlined,
                    user.website!,
                    iconColor: Colors.blue,
                    textColor: Colors.blue.withOpacity(0.8),
                  ),
                ],
                if (user.followers?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.people_outline,
                    "${user.followers!.length} seguidores",
                    showBadge: false,
                    iconColor: AppStyles.colorAvatarBorder,
                  ),
                ],
                if (user.following?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    Icons.person_add_outlined,
                    "${user.following!.length} siguiendo",
                    showBadge: false,
                    iconColor: AppStyles.colorAvatarBorder,
                  ),
                ],
              ]),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text, {
    Color? iconColor,
    Color? textColor,
    double iconSize = 14,
    double fontSize = 12,
    bool showBadge = false,
    bool isHighlighted = false,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 2),
  }) {
    return Padding(
      padding: padding,
      child: Container(
        decoration: isHighlighted
            ? BoxDecoration(
                color: AppStyles.colorAvatarBorder.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppStyles.colorAvatarBorder.withOpacity(0.2),
                  width: 0.5,
                ),
              )
            : null,
        padding: isHighlighted
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  color: textColor ?? Colors.grey[600],
                  fontWeight:
                      isHighlighted ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppStyles.colorAvatarBorder.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: AppStyles.colorAvatarBorder,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
