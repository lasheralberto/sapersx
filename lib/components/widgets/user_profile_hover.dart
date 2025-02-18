import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/user_hover_card.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/user.dart';

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
  bool _isHovering = false;
  bool _isLoggedIn = false;

  // 2. Acceso al usuario en caché
  UserInfoPopUp? get _cachedUser =>
      UserCacheManager.getCachedUser(widget.authorUsername);

  // 3. Carga optimizada del perfil
  Future<void> _loadUserProfile() async {
    if (_cachedUser != null) return;

    try {
      final userData =
          await FirebaseService().getUserInfoByUsername(widget.authorUsername);
      if (mounted) {
        UserCacheManager.cacheUser(widget.authorUsername, userData!);
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
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
                  borderRadius:
                      BorderRadius.circular(AppStyles.borderRadiusValue),
                  child: UserHoverCard(profile: _cachedUser!),
                ),
              ),
            ));

    if (mounted) Overlay.of(context).insert(_overlayEntry!);
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
            }
          },
          child: _cachedUser == null
              ? _buildLoadingIndicator()
              : _buildProfileAvatar(),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() => const SizedBox(
        width: TwitterDimensions.avatarSizeSmall,
        height: TwitterDimensions.avatarSizeSmall,
        child: CircularProgressIndicator(),
      );

  Widget _buildProfileAvatar() => ProfileAvatar(
        userInfoPopUp: _cachedUser,
        showBorder: _cachedUser!.isExpert as bool,
        seed: _cachedUser!.email,
        size: AppStyles.avatarSize - 5,
      );
}
