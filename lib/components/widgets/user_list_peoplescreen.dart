import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart' as app_user;

class UserListWidget extends StatefulWidget {
  final List<app_user.UserInfoPopUp> users;
  final String currentUserId;
  final Function() onRefreshCurrentUser;
  final Function(app_user.UserInfoPopUp) onSelectUser;
  final app_user.UserInfoPopUp? selectedUser;

  const UserListWidget({
    Key? key,
    required this.users,
    required this.currentUserId,
    required this.onRefreshCurrentUser,
    required this.onSelectUser,
    this.selectedUser,
  }) : super(key: key);

  @override
  State<UserListWidget> createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<UserListWidget> {
  final ScrollController _scrollController = ScrollController();

  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  void _selectUserOnMap(app_user.UserInfoPopUp user) {
    widget.onSelectUser(user);

    // Auto-scroll to selected user if not visible
    if (widget.selectedUser?.uid == user.uid) {
      final int index = widget.users.indexWhere((u) => u.uid == user.uid);
      if (index != -1 && _scrollController.hasClients) {
        final itemHeight =
            _isSmallScreen(context) ? 170.0 : 220.0; // Approximate height
        _scrollController.animateTo(
          index * itemHeight,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: widget.users.length,
      itemBuilder: (context, index) {
        final user = widget.users[index];
        return _UserListItem(
          user: user,
          currentUserId: widget.currentUserId,
          onUpdate: widget.onRefreshCurrentUser,
          onSelect: () => _selectUserOnMap(user),
          isSelected: widget.selectedUser?.uid == user.uid,
          isSmallScreen: _isSmallScreen(context),
          key: ValueKey(user.uid),
        );
      },
    );
  }
}

class _UserListItem extends StatefulWidget {
  final app_user.UserInfoPopUp user;
  final String currentUserId;
  final VoidCallback onUpdate;
  final VoidCallback onSelect;
  final bool isSelected;
  final bool isSmallScreen;

  const _UserListItem({
    required this.user,
    required this.currentUserId,
    required this.onUpdate,
    required this.onSelect,
    this.isSelected = false,
    this.isSmallScreen = false,
    super.key,
  });

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  bool _isLoading = false;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'user-${widget.user.uid}',
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        elevation: widget.isSelected ? 1 : 0,
        shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
        color: widget.isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : _isHovering
                ? Theme.of(context).cardColor.withOpacity(0.8)
                : Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
          side: widget.isSelected
              ? BorderSide(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 1)
              : BorderSide.none,
        ),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: InkWell(
            onTap: widget.onSelect,
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: widget.isSmallScreen ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserProfileCardHover(
                        authorUsername: widget.user.username,
                        isExpert: widget.user.isExpert ?? false,
                        onProfileOpen: () {},
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserHeader(context),
                            if (widget.user.location?.isNotEmpty ?? false)
                              _buildLocationInfo(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _buildUserBio(context),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildUserStats(context),
                      // _buildMapButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.user.username,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.user.specialty?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Tooltip(
              message: widget.user.specialty!,
              child: Chip(
                label: Text(widget.user.specialty!),
                backgroundColor: AppStyles.colorAvatarBorder.withOpacity(0.1),
                labelStyle: const TextStyle(fontSize: 12),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationInfo(BuildContext context) {
    return InkWell(
      onTap: widget.onSelect,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 14, color: Theme.of(context).hintColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.user.location!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.user.latitude != null && widget.user.longitude != null)
              Tooltip(
                message: Texts.translate(
                    'view_on_map', LanguageProvider().currentLanguage),
                child: Icon(
                  Icons.map_outlined,
                  size: 14,
                  color: Theme.of(context).primaryColor.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBio(BuildContext context) {
    if (widget.user.bio?.isNotEmpty ?? false) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          widget.user.bio!,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: widget.isSelected ? 4 : 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return const SizedBox(height: 0);
  }

  Widget _buildUserStats(BuildContext context) {
    return Row(
      children: [
        _buildStatItem(context, (widget.user.followers?.length ?? 0).toString(),
            'seguidores', Icons.people),
        const SizedBox(width: 16),
        _buildStatItem(context, (widget.user.following?.length ?? 0).toString(),
            'siguiendo', Icons.person_add),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context, String count, String label, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).primaryColor.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Text(
              Texts.translate(label, LanguageProvider().currentLanguage),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapButton(BuildContext context) {
    if (widget.user.latitude != null && widget.user.longitude != null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: widget.isSelected ? Matrix4.identity() : Matrix4.identity(),
        child: OutlinedButton.icon(
          onPressed: widget.onSelect,
          icon: const Icon(Icons.map, size: 16),
          label: widget.isSmallScreen
              ? const SizedBox.shrink() // En móvil, solo mostrar el ícono
              : Text(Texts.translate(
                  'view_on_map', LanguageProvider().currentLanguage)),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
                horizontal: widget.isSmallScreen ? 8 : 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            foregroundColor:
                widget.isSelected ? Theme.of(context).primaryColor : null,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
