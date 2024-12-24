import 'package:flutter/material.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/user.dart';


class UserHoverCard extends StatelessWidget {
  final UserInfoPopUp? profile;

  const UserHoverCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TwitterDimensions.spacing),
      decoration: BoxDecoration(
        color: TwitterColors.background,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, profile!),
          const SizedBox(height: TwitterDimensions.spacing),
          profile?.bio == null
              ? const SizedBox.shrink()
              : Text(
                  profile!.bio.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
          const SizedBox(height: TwitterDimensions.spacingSmall),
          const SizedBox(height: TwitterDimensions.spacingSmall),
          _buildLocation(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserInfoPopUp userprofile) {
    return Row(
      children: [
        ProfileAvatar(
          seed: userprofile.email,
          size: AppStyles.avatarSize - 10,
        ),
        const SizedBox(width: TwitterDimensions.spacingSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${userprofile.username}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TwitterColors.secondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocation(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 16,
          color: TwitterColors.secondary,
        ),
        const SizedBox(width: TwitterDimensions.spacingSmall),
        Text(
          profile!.location.toString(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TwitterColors.secondary,
              ),
        ),
      ],
    );
  }
}
