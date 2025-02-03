// constants.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/user.dart';
import '../../main.dart';
import 'package:sapers/models/texts.dart';

// widgets/profile_header.dart
class ProfileHeader extends StatefulWidget {
  final UserInfoPopUp profile;

  const ProfileHeader({
    super.key,
    required this.profile,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  final FirebaseService _firebaseService = FirebaseService();
  bool isFollowing = false;
  bool _initialized = false; // Para evitar múltiples llamadas
  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    _firebaseService
        .checkIfUserExistsInFollowers(
            FirebaseAuth.instance.currentUser!.uid, widget.profile.username)
        .then(
      (value) {
        setState(() {
          isFollowing = value;
          _initialized = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildProfileInfo(context, widget.profile),
      ],
    );
  }

  Widget _buildProfileInfo(BuildContext context, profile) {
    return Padding(
      padding: const EdgeInsets.all(TwitterDimensions.spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ProfileAvatar(
                seed: profile.email,
                size: AppStyles.avatarSize + 10,
                showBorder: profile.isExpert,
              ),
              const Spacer(),
              //   _buildEditProfileButton(context),
            ],
          ),
          const SizedBox(height: TwitterDimensions.spacing),
          _buildUserInfo(context),
          const SizedBox(height: TwitterDimensions.spacing),
          _buildUserMetadata(context),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildButton(context, isFollowing == true ? 'unfollow' : 'seguir',
                  () async {
                //follow action
                setState(() {
                  _loadingStates['seguir'] = true;
                  _loadingStates['unfollow'] = true;
                });
                bool isFollowed = await _firebaseService.followOrUnfollowUser(
                    FirebaseAuth.instance.currentUser!.uid, profile.username);

                setState(() {
                  _loadingStates['seguir'] = false;
                  _loadingStates['unfollow'] = false;
                  isFollowing = isFollowed;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, String buttonText, VoidCallback onPressedAction) {
    // Comprobamos el estado de carga del botón específico
    bool isLoading = _loadingStates[buttonText] ?? false;

    return isLoading
        ? AppStyles().progressIndicatorButton()
        : OutlinedButton(
            onPressed: onPressedAction,
            style: AppStyles().getButtonStyle(context),
            child: Text(
              Texts.translate(buttonText, globalLanguage),
              style: AppStyles().getButtontTextStyle(context),
            ),
          );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '@${widget.profile.username}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: TwitterColors.secondary,
              ),
        ),
        const SizedBox(height: TwitterDimensions.spacingSmall),
        Text(
          widget.profile.bio.toString(),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildUserMetadata(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildMetadataItem(
                context,
                Icons.location_on_outlined,
                widget.profile.location.toString(),
              ),
              const SizedBox(width: TwitterDimensions.spacing),
              _buildMetadataItem(
                context,
                Icons.calendar_today_outlined,
                'Se unió en ${UtilsSapers().formatTimestampJoinDate(widget.profile.joinDate.toString())}',
              ),
            ],
          ),
          const SizedBox(height: TwitterDimensions.spacing),
          _buildMetadataItem(context, Icons.monetization_on_rounded,
              'Tarifa ${widget.profile.hourlyRate.toString()} €/h'),
          const SizedBox(height: TwitterDimensions.spacing),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: TwitterColors.secondary,
        ),
        const SizedBox(width: TwitterDimensions.spacingSmall / 2),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TwitterColors.secondary,
              ),
        ),
      ],
    );
  }
}
