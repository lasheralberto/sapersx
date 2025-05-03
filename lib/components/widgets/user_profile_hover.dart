import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';

import 'package:sapers/models/auth_service.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/utils_sapers.dart';

// 1. Caché global para todos los usuarios
class UserCacheManager {
  static final Map<String, UserInfoPopUp> _userCache = {};

  static UserInfoPopUp? getCachedUser(String username) => _userCache[username];

  static void cacheUser(String username, UserInfoPopUp user) {
    _userCache[username] = user;
  }
}

class UserProfileCardHover extends StatefulWidget {
  final String authorUsername;
  final VoidCallback onProfileOpen;
  final bool isExpert;

  const UserProfileCardHover({
    super.key,
    required this.authorUsername,
    required this.isExpert,
    required this.onProfileOpen,
  });

  @override
  State<UserProfileCardHover> createState() => _UserProfileCardHoverState();
}

class _UserProfileCardHoverState extends State<UserProfileCardHover> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  bool _isLoggedIn = false;

  // 2. Acceso al usuario en caché
  UserInfoPopUp? get _cachedUser =>
      UserCacheManager.getCachedUser(widget.authorUsername);

  // 3. Carga optimizada del perfil
  Future<void> _loadUserProfile() async {
    if (_cachedUser != null) return;

    try {
      final UserInfoPopUp? userData =
          await FirebaseService().getUserInfoByUsername(widget.authorUsername);

      if (mounted) {
        UserCacheManager.cacheUser(widget.authorUsername, userData!);
        setState(() {});
      }
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void didUpdateWidget(UserProfileCardHover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authorUsername != widget.authorUsername) {
      _loadUserProfile();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // 4. Mostrar hover card solo si hay datos
  void _showHoverCard() {
    if (_cachedUser == null) return;

    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
            child: _buildUserInfoCard(),
          ),
        ),
      ),
    );

    if (mounted) Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildUserInfoCard() {
    final user = _cachedUser!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        //color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ProfileAvatar(
                userInfoPopUp: user,
                showBorder: widget.isExpert, // Usar isExpert del widget
                seed: user.email,
                size: 60,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    user.isExpert == true
                        ? Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              Texts.translate(
                                  'expert', LanguageProvider().currentLanguage),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Texts.translate(
                                'Level', LanguageProvider().currentLanguage),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.userTier != null ? user.userTier! : 'L1',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.pointsInTier != null
                                ? user.pointsInTier!
                                : '0/500',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          if (user.bio != null && user.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                user.bio!,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 20,
            children: [
              //  _buildStatItem('Publicaciones', user.postsCount ?? 0),
              _buildStatItem(
                  Texts.translate(
                      'FollowingTab', LanguageProvider().currentLanguage),
                  user.following?.length ?? 0),

              _buildStatItem(
                  Texts.translate(
                      'FollowersTab', LanguageProvider().currentLanguage),
                  user.followers?.length ?? 0),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showHoverCard(),
        onExit: (_) => _removeOverlay(),
        child: GestureDetector(
          onTap: () {
            _isLoggedIn = AuthService().isUserLoggedIn(context);
            if (_isLoggedIn && _cachedUser != null) {
              context.push('/profile/${_cachedUser!.username}');
              widget.onProfileOpen();
            }
          },
          child: _cachedUser == null
              ? _buildLoadingIndicator()
              : _buildProfileAvatar(),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() => SizedBox(
        width: TwitterDimensions.avatarSizeSmall,
        height: TwitterDimensions.avatarSizeSmall,
        child: UtilsSapers().buildShimmerEffect(
            1,
            UtilsSapers()
                .buildAvatarIconShimmer(size: AppStyles.avatarSize - 5)),
      );

  Widget _buildProfileAvatar() => ProfileAvatar(
        userInfoPopUp: _cachedUser,
        showBorder: _cachedUser!.isExpert ?? false, // Usar isExpert del widget
        seed: _cachedUser!.email,
        size: AppStyles.avatarSize - 5,
      );
}
