import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/user_tier_badge.dart';
import 'package:sapers/models/auth_provider.dart';
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

  void _showDMDialog(BuildContext context, UserInfoPopUp recipient) {
    final messageController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '@${recipient.username}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: Texts.translate(
                        'writeMessage', LanguageProvider().currentLanguage),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isSending)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      FilledButton(
                        onPressed: () async {
                          if (messageController.text.trim().isEmpty) return;
                          setState(() => isSending = true);
                          try {
                            final user = Provider.of<AuthProviderSapers>(
                                    context,
                                    listen: false)
                                .userInfo;
                            await FirebaseService().sendDirectMessage(
                              fromUsername: user?.username ?? 'Unknown',
                              toUsername: recipient.username,
                              message: messageController.text.trim(),
                            );
                            if (context.mounted) Navigator.pop(context);
                          } finally {
                            if (mounted) setState(() => isSending = false);
                          }
                        },
                        child: Text(
                          Texts.translate(
                              'send', LanguageProvider().currentLanguage),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(TwitterDimensions.spacing + 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  children: [
                    ProfileAvatar(
                      seed: profile.email,
                      size: AppStyles.avatarSize + 10,
                      showBorder: profile.isExpert,
                    ),
                    const SizedBox(height: 8),
                    _buildFollowButton(context),
                    IconButton(
                      onPressed: () => _showDMDialog(context, profile),
                      icon: const Icon(Icons.mail_outline_rounded, size: 20),
                      tooltip: Texts.translate(
                          'sendMessage', LanguageProvider().currentLanguage),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildUserInfo(context, profile),
                      const SizedBox(height: 16),
                      _buildUserMetadata(context),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TwitterDimensions.spacingSmall + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context) {
    bool isLoading = _loadingStates['follow'] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 40,
      width: 40,
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppStyles.colorAvatarBorder,
                  ),
                ),
              ),
            )
          : IconButton(
              onPressed: () async {
                setState(() => _loadingStates['follow'] = true);
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
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isFollowing
                      ? Icons.person_remove_rounded
                      : Icons.person_add_rounded,
                  key: ValueKey<bool>(isFollowing),
                  size: 24,
                  color: isFollowing
                      ? Colors.redAccent
                      : AppStyles.colorAvatarBorder,
                ),
              ),
              tooltip: Texts.translate(
                isFollowing ? 'unfollow' : 'seguir',
                LanguageProvider().currentLanguage,
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
        // Botón mejorado
      ],
    );
  }

  Widget _buildUserMetadata(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
