import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sapers/components/screens/user_profile.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/user_hover_card.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/components/widgets/profile_header.dart';

class UserProfileCardHover extends StatefulWidget {
  final dynamic post;
  final VoidCallback onProfileOpen;
  bool isExpert;

  UserProfileCardHover({
    super.key,
    required this.post,
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
  UserInfoPopUp? user;
  FirebaseService firebaseService = FirebaseService();
  bool isLoguedIn = false;
  bool _isLoading = true; // Nuevo flag para control de carga

  Future<void> _initializeUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final userData =
          await FirebaseService().getUserInfoByUsername(widget.post.author);

      if (mounted) {
        setState(() {
          user = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading user profile: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeUserProfile();
  }

  @override
  void didUpdateWidget(UserProfileCardHover oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar el perfil si cambia el autor del post
    if (oldWidget.post.author != widget.post.author) {
      _initializeUserProfile();
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

  bool checkUserIsLoguedIn(FirebaseService firebaseServiceInstance) {
    return AuthService().isUserLoggedIn(context);
  }

  void _showHoverCard() {
    if (_isLoading || user == null) {
      return; // No mostrar si está cargando o no hay usuario
    }

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
            child: UserHoverCard(profile: user),
          ),
        ),
      ),
    );

    if (mounted && context.mounted) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          if (!_isLoading) {
            setState(() => _isHovering = true);
            _showHoverCard();
          }
        },
        onExit: (_) {
          setState(() => _isHovering = false);
          _removeOverlay();
        },
        child: GestureDetector(
          onTap: () {
            setState(() {
              isLoguedIn = checkUserIsLoguedIn(firebaseService);
            });

            if (isLoguedIn && user != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(userinfo: user),
                ),
              );
            }
          },
          child: _isLoading
              ? const SizedBox(
                  width: TwitterDimensions.avatarSizeSmall,
                  height: TwitterDimensions.avatarSizeSmall,
                  child: CircularProgressIndicator(),
                )
              : ProfileAvatar(
                  showBorder: user?.isExpert as bool,
                  seed: user!.email.toString(),
                  size: AppStyles.avatarSize - 5,
                ),
        ),
      ),
    );
  }
}
