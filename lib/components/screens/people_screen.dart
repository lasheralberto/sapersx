import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/widgets/mustbeloggedsection.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart' as app_user;
import 'package:sapers/models/styles.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  late Stream<QuerySnapshot> _usersStream;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  app_user.UserInfoPopUp? currentUser;

  @override
  void initState() {
    super.initState();
    _initUsersStream();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _initUsersStream() {
    currentUser =
        Provider.of<AuthProviderSapers>(context, listen: false).userInfo;

    _usersStream = FirebaseFirestore.instance
        .collection('userinfo')
        .where('uid', isNotEqualTo: currentUser?.uid)
        .snapshots();
  }

  String get _currentUserId =>
      Provider.of<AuthProviderSapers>(context, listen: false).userInfo?.uid ??
      '';

  void _refreshCurrentUser() {
    Provider.of<AuthProviderSapers>(context, listen: false).refreshUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            children: [
              Expanded(
                child: currentUser == null
                    ? LoginRequiredWidget(
                        onTap: () {
                          AuthService().isUserLoggedIn(context);
                        },
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: _usersStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _buildErrorState(snapshot.error!);
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingState();
                          } else if (snapshot.connectionState ==
                              ConnectionState.none) {
                            return _buildErrorState(
                                'No se pudo cargar los datos');
                          }

                          if (snapshot.hasData) {
                            final users = _parseUsers(snapshot.data!.docs);
                            final filteredUsers = _filterUsers(users);

                            return filteredUsers.isEmpty
                                ? _buildEmptyState()
                                : _buildUserList(filteredUsers);
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 20),
          Text(
            Texts.translate(
                'error_loading_users', LanguageProvider().currentLanguage),
            style: TextStyle(
                color: Colors.red[700],
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() => _initUsersStream()),
            child: Text(
                Texts.translate('retry', LanguageProvider().currentLanguage)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(Texts.translate(
              'finding_users', LanguageProvider().currentLanguage)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty
                ? Texts.translate(
                    'no_users_available', LanguageProvider().currentLanguage)
                : Texts.translate('no_users_found_for',
                        LanguageProvider().currentLanguage) +
                    ' "$_searchQuery"',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton.icon(
                onPressed: () => _searchController.clear(),
                icon: const Icon(Icons.refresh),
                label: Text(Texts.translate(
                    'clear_search', LanguageProvider().currentLanguage)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<app_user.UserInfoPopUp> users) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _UserListItem(
          user: user,
          currentUserId: _currentUserId,
          onUpdate: _refreshCurrentUser,
          key: ValueKey(user.uid),
        );
      },
    );
  }

  List<app_user.UserInfoPopUp> _parseUsers(List<QueryDocumentSnapshot> docs) {
    return docs
        .map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            return app_user.UserInfoPopUp.fromMap(data);
          } catch (e) {
            debugPrint('Error parsing user ${doc.id}: $e');
            return app_user.UserInfoPopUp(
              uid: doc.id,
              username: 'Usuario inválido',
              email: '',
            );
          }
        })
        .where((user) => user.uid != _currentUserId)
        .toList();
  }

  List<app_user.UserInfoPopUp> _filterUsers(
      List<app_user.UserInfoPopUp> users) {
    if (_searchQuery.isEmpty) {
      return users;
    }

    return users.where((user) {
      final username = user.username.toLowerCase();
      final specialty = (user.specialty ?? '').toLowerCase();
      final bio = (user.bio ?? '').toLowerCase();
      final location = (user.location ?? '').toLowerCase();

      return username.contains(_searchQuery) ||
          specialty.contains(_searchQuery) ||
          bio.contains(_searchQuery) ||
          location.contains(_searchQuery);
    }).toList();
  }
}

class _UserListItem extends StatefulWidget {
  final app_user.UserInfoPopUp user;
  final String currentUserId;
  final VoidCallback onUpdate;

  const _UserListItem({
    required this.user,
    required this.currentUserId,
    required this.onUpdate,
    super.key,
  });

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  bool _isLoading = false;
  bool? _isFollowing;
  late Stream<DocumentSnapshot> _currentUserStream;

  @override
  void initState() {
    super.initState();
    _initFollowingStatus();
  }

  void _initFollowingStatus() {
    _currentUserStream = FirebaseFirestore.instance
        .collection('userinfo')
        .doc(widget.currentUserId)
        .snapshots();

    // Inicializa el estado de seguimiento
    _currentUserStream.first.then((snapshot) {
      if (mounted) {
        setState(() {
          final data = snapshot.data() as Map<String, dynamic>?;
          final following = data?['following'] as List<dynamic>? ?? [];
          _isFollowing = following.contains(widget.user.uid);
        });
      }
    });
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      bool result = await FirebaseService().followOrUnfollowUser(
        widget.currentUserId,
        widget.user.username,
      );

      if (mounted) {
        setState(() {
          _isFollowing = result;
          _isLoading = false;
        });
      }

      widget.onUpdate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result
                ? 'Ahora sigues a ${widget.user.username}'
                : 'Has dejado de seguir a ${widget.user.username}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        child: Padding(
          padding: const EdgeInsets.all(50.0),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.user.username,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.user.specialty?.isNotEmpty ?? false)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Chip(
                                  label: Text(widget.user.specialty!),
                                  backgroundColor: AppStyles.colorAvatarBorder
                                      .withOpacity(0.1),
                                  labelStyle: const TextStyle(fontSize: 12),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                ),
                              ),

                            ///f (widget.user.isExpert == true)
                            // const Padding(
                            //   padding: EdgeInsets.only(left: 4),
                            //   child: Icon(Icons.verified,
                            //       color: Colors.blue, size: 18),
                            // ),
                          ],
                        ),
                        if (widget.user.location?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14,
                                    color: Theme.of(context).hintColor),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.user.location!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.user.bio?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.user.bio!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildUserStats(context),
                  // StreamBuilder<DocumentSnapshot>(
                  //   stream: _currentUserStream,
                  //   builder: (context, snapshot) {
                  //     // Actualiza el estado de seguimiento si los datos cambian
                  //     if (snapshot.hasData && !_isLoading) {
                  //       final data =
                  //           snapshot.data!.data() as Map<String, dynamic>?;
                  //       final following =
                  //           data?['following'] as List<dynamic>? ?? [];
                  //       _isFollowing = following.contains(widget.user.uid);
                  //     }

                  //     return _FollowButton(
                  //       isFollowing: _isFollowing ?? false,
                  //       isLoading: _isLoading,
                  //       onPressed: _toggleFollow,
                  //     );
                  //   },
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserStats(BuildContext context) {
    return Row(
      children: [
        _buildStatItem(context, (widget.user.following?.length ?? 0).toString(),
            'seguidores'),
        const SizedBox(width: 16),
        _buildStatItem(context, (widget.user.following?.length ?? 0).toString(),
            'siguiendo'),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String count, String label) {
    return Column(
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
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onPressed;

  const _FollowButton({
    required this.isFollowing,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? const SizedBox(
              width: 90,
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : SizedBox(
              height: 36,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: isFollowing
                      ? Colors.grey[200]
                      : Theme.of(context).primaryColor,
                  foregroundColor:
                      isFollowing ? Colors.grey[700] : Colors.white,
                  side: BorderSide(
                    color: isFollowing
                        ? Colors.grey[300]!
                        : Theme.of(context).primaryColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: onPressed,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFollowing ? Icons.check : Icons.add,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFollowing
                          ? Texts.translate(
                              'following', LanguageProvider().currentLanguage)
                          : Texts.translate(
                              'follow', LanguageProvider().currentLanguage),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
