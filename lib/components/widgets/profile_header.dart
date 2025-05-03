import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/user_tier_badge.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/utils_sapers.dart';
import '../../main.dart';
import 'package:sapers/models/texts.dart';

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
      padding: const EdgeInsets.all(TwitterDimensions.spacing + 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                seed: profile.email,
                size: AppStyles.avatarSize + 10,
                showBorder: profile.isExpert,
              ),
              const SizedBox(width: 16), // Espacio entre el avatar y la info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfo(context, profile),
                    const SizedBox(height: 16),
                    _buildUserMetadata(context),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context) {
    bool isLoading = _loadingStates['follow'] ?? false;

    return isLoading
        ? AppStyles().progressIndicatorButton(context)
        : ElevatedButton.icon(
            onPressed: () async {
              setState(() {
                _loadingStates['follow'] = true;
              });
              bool isFollowed = await _firebaseService.followOrUnfollowUser(
                FirebaseAuth.instance.currentUser!.uid,
                widget.profile.username,
                context,
              );
              setState(() {
                _loadingStates['follow'] = false;
                isFollowing = isFollowed;
              });
            },
            icon: Icon(
              isFollowing ? Icons.person_remove : Icons.person_add,
              size: 16,
            ),
            label: Text(
              Texts.translate(
                isFollowing ? 'unfollow' : 'seguir',
                LanguageProvider().currentLanguage,
              ),
            ),
            style: ElevatedButton.styleFrom(
              iconColor: Theme.of(context).scaffoldBackgroundColor,
              backgroundColor: isFollowing
                  ? Colors.redAccent // Color para "dejar de seguir"
                  : Theme.of(context).primaryColor, // Color para "seguir"
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
  }

  Widget _buildUserInfo(BuildContext context, UserInfoPopUp profile) {
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
          maxLines: 3, // Limitar el número de líneas para evitar overflow
          overflow: TextOverflow
              .ellipsis, // Añadir puntos suspensivos si el texto es muy largo
        ),
        const SizedBox(height: 16),
        _buildFollowButton(context), // Botón mejorado
      ],
    );
  }

  Widget _buildUserMetadata(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetadataItem(
            context,
            Icons.location_on_outlined,
            widget.profile.location.toString(),
          ),
          const SizedBox(height: TwitterDimensions.spacingSmall),
          _buildMetadataItem(
            context,
            Icons.calendar_today_outlined,
            '${Texts.translate('joinedOn', LanguageProvider().currentLanguage)} ${UtilsSapers().formatTimestampJoinDate(widget.profile.joinDate.toString())}',
          ),
          const SizedBox(height: TwitterDimensions.spacingSmall),
          _buildMetadataItem(
            context,
            Icons.monetization_on_rounded,
            '${Texts.translate('fare', LanguageProvider().currentLanguage)} ${widget.profile.hourlyRate.toString()} €/h',
          ),
          UserTierBadge(
            currentLanguage: LanguageProvider().currentLanguage,
            userTier: widget.profile.userTier ?? 'L1',
            pointsInTier: widget.profile.pointsInTier ?? '0',
            translate: Texts.translate, // Función de traducción
          ),
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
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TwitterColors.secondary,
                ),
            maxLines: 2, // Limitar el número de líneas para evitar overflow
            overflow: TextOverflow
                .ellipsis, // Añadir puntos suspensivos si el texto es muy largo
          ),
        ),
      ],
    );
  }
}
