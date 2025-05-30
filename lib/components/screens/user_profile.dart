import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/screens/edit_profile_screen.dart';
import 'package:sapers/components/widgets/expert_profile_card.dart';
import 'package:sapers/components/widgets/invitation_item.dart';
import 'package:sapers/components/widgets/postcard.dart';
import 'package:sapers/components/widgets/project_invitation_section.dart';
import 'package:sapers/components/widgets/profile_header.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/user_reviews.dart';

class UserProfilePage extends StatefulWidget {
  final UserInfoPopUp? userinfo;

  const UserProfilePage({
    super.key,
    required this.userinfo,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with TickerProviderStateMixin {
  late Future<UserInfoPopUp?> userProfileData;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    userProfileData = _loadUserProfileData();
    _tabController = TabController(
        length: widget.userinfo?.isExpert == true ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                            await FirebaseService().sendDirectMessage(
                              fromUsername:
                                  AuthProviderSapers().userInfo!.username,
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

  Future<UserInfoPopUp?> _loadUserProfileData() async {
    return widget.userinfo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                backgroundColor: Theme.of(context).cardColor,
                elevation: 0,
                pinned: true,
                expandedHeight: 300.0, // Altura flexible del header
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: FutureBuilder<UserInfoPopUp?>(
                    future: userProfileData,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ProfileHeader(profile: snapshot.data!);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize:
                      const Size.fromHeight(48.0), // Altura del TabBar
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor:
                          Theme.of(context).textTheme.bodyMedium?.color,
                      labelColor: Theme.of(context).textTheme.bodyMedium?.color,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(
                            text: Texts.translate('projects',
                                LanguageProvider().currentLanguage)),
                        Tab(
                            text: Texts.translate(
                                'posts', LanguageProvider().currentLanguage)),
                        if (widget.userinfo?.isExpert == true)
                          Tab(
                              text: Texts.translate('expertTab',
                                  LanguageProvider().currentLanguage)),
                      ],
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: TwitterColors.darkGray,
                  onPressed: () => context.pop(),
                ),
                actions: [
                  if (widget.userinfo?.uid ==
                      Provider.of<AuthProviderSapers>(context).userInfo?.uid)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () async {
                            final updatedUser =
                                await Navigator.push<UserInfoPopUp>(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProfileScreen(user: widget.userinfo!),
                              ),
                            );

                            if (updatedUser != null) {
                              setState(() {
                                userProfileData = Future.value(updatedUser);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppStyles.colorAvatarBorder,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child:  Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                             const   Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppStyles.colorAvatarBorder,
                                ),
                                const SizedBox(width: 4),
                                Text(
                               Texts.translate('editProfile', LanguageProvider().currentLanguage),
                                  style: const TextStyle(
                                    color: AppStyles.colorAvatarBorder,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _ProjectsTab(userinfo: widget.userinfo),
            _PostsTab(userId: widget.userinfo?.username ?? ''),
            if (widget.userinfo?.isExpert == true)
              SAPExpertProfile(profile: widget.userinfo!),
          ],
        ),
      ),
    );
  }
}

class _ProjectsTab extends StatelessWidget {
  final UserInfoPopUp? userinfo;

  const _ProjectsTab({required this.userinfo});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Project Cards Section
              if (userinfo != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ResponsiveProjectsLayout(data: userinfo!),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostsTab extends StatefulWidget {
  final String userId;

  const _PostsTab({required this.userId});

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  final bool _isRefreshing = false;
  final FirebaseService _firebaseService = FirebaseService();

  Future<List<SAPPost>>? _postsFutureGeneral;
  Future<List<SAPPost>>? generalPosts;

  @override
  void initState() {
    super.initState();
    _postsFutureGeneral =
        _firebaseService.getPostsFutureByAuthor(widget.userId);
  }

  Future<void> _handleRefresh() async {
    await _updateFutures();
  }

  Future<void> _updateFutures() async {
    generalPosts = _firebaseService.getPostsFutureByAuthor(widget.userId);
    setState(() {
      _postsFutureGeneral = generalPosts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SAPPost>>(
      future: _postsFutureGeneral,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: SelectableText('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Text(
              Texts.translate('noposts', LanguageProvider().currentLanguage),
            ),
          );
        }

        return LiquidPullToRefresh(
          backgroundColor: AppStyles.colorAvatarBorder,
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(
                  top: 16.0, // Espacio mínimo entre el header y los posts
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return PostCard(
                        key: ValueKey(posts[index].id),
                        onExpandChanged: (p0) {},
                        tagPressed: (tag) {},
                        post: posts[index],
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ResponsiveProjectsLayout extends StatefulWidget {
  final UserInfoPopUp data;

  const ResponsiveProjectsLayout({
    required this.data,
    super.key,
  });

  @override
  State<ResponsiveProjectsLayout> createState() =>
      _ResponsiveProjectsLayoutState();
}

class _ResponsiveProjectsLayoutState extends State<ResponsiveProjectsLayout> {
  UserInfoPopUp? userFrom;
  String? selectedProject;
  bool isMessageSending = false;

  @override
  void initState() {
    super.initState();
    _getUserFrom();
  }

  Future<void> _getUserFrom() async {
    final user =
        Provider.of<AuthProviderSapers>(context, listen: false).userInfo;
    setState(() {
      userFrom = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return ProjectInvitationSection(profile: widget.data);
  }
}
