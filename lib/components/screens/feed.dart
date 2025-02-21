import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/components/screens/popup_create_post.dart';
import 'package:sapers/components/screens/project_dialog.dart';
import 'package:sapers/components/screens/project_screen.dart';
import 'package:sapers/components/widgets/postcard.dart';
import 'package:sapers/components/widgets/project_card.dart';
import 'package:sapers/components/widgets/project_list.dart';
import 'package:sapers/components/widgets/searchbar.dart';
import 'package:sapers/components/widgets/user_avatar.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/theme.dart';
import 'package:sapers/models/user.dart';

class Feed extends StatefulWidget {
  final User? user;
  final VoidCallback? onLoginRequired;
  const Feed({super.key, required this.user, this.onLoginRequired});

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final List<String> _modules = Modules.modules;
  List<PlatformFile> selectedFiles = [];

  late TabController _tabController;
  String _selectedModule = '';
  Future<List<SAPPost>>? _postsFutureGeneral;
  Future<List<SAPPost>>? _postsFutureFollowing;
  Future<List<Project>>? _postsProjects;
  bool _isRefreshing = false;
  bool isPostExpanded = false;
  UserInfoPopUp? userinfo;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      setState(() {});
    });
    _updateFutures();
  }

  Future<void> _handleRefresh() async {
    if (!_isRefreshing) {
      setState(() => _isRefreshing = true);
      await _updateFutures();
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _updateFutures() async {
    final generalPosts = _selectedModule.isEmpty
        ? _firebaseService.getPostsFuture()
        : _firebaseService.getPostsByModuleFuture(_selectedModule);
    final followingPosts = _firebaseService.getPostsFollowingFuture();
    final projectsPosts = _firebaseService.getProjectsFuture();

    setState(() {
      _postsFutureGeneral = generalPosts;
      _postsFutureFollowing = followingPosts;
      _postsProjects = projectsPosts;
    });
  }

  void _performSearch() {
    final searchText = _searchController.text.trim();
    setState(() {
      _postsFutureGeneral = searchText.isEmpty
          ? _firebaseService.getPostsFuture()
          : _firebaseService.getPostsByKeyword(searchText);
      _selectedModule = searchText.isEmpty ? _selectedModule : '';
    });
  }

  void _showCreatePostDialog() async {
    if (FirebaseAuth.instance.currentUser == null) {
      showDialog(context: context, builder: (context) => const LoginDialog());
    } else {
      final result = await showDialog<SAPPost>(
        context: context,
        builder: (context) => const CreatePostDialog(),
      );

      if (result != null) {
        await _firebaseService.createPost(result);
        _updateFutures();
      }
    }
  }

  void _showCreateProjectDialog() async {
    if (FirebaseAuth.instance.currentUser == null) {
      showDialog(context: context, builder: (context) => const LoginDialog());
    } else {
      UserInfoPopUp? user = await FirebaseService()
          .getUserInfoByEmail(FirebaseAuth.instance.currentUser!.email!);
      final result = await showDialog<Project>(
        context: context,
        builder: (context) => CreateProjectDialog(user: user),
      );

      if (result != null) {
        await _firebaseService.createProject(result);
        _updateFutures();
      }
    }
  }

  


  Widget _buildPostsList(Future<List<SAPPost>> future, bool isMobile) {
    return FutureBuilder<List<SAPPost>>(
      future: future,
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
              child: Text(Texts.translate('noposts', globalLanguage)));
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_isRefreshing)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 4.0 : 16.0,
                  vertical: 8.0,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Container(
                        margin: EdgeInsets.only(
                          bottom: isMobile ? 8.0 : 16.0,
                          left: isMobile ? 2.0 : 8.0,
                          right: isMobile ? 2.0 : 8.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              AppStyles.borderRadiusValue),
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: null,
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.15),
                            width: 0.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              AppStyles.borderRadiusValue),
                          child: Material(
                            color: Colors.transparent,
                            child: PostCard(
                              onExpandChanged: (p0) =>
                                  setState(() => isPostExpanded = p0),
                              post: posts[index],
                            ),
                          ),
                        ),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      //bottomSheet: _buildHotTopicsPanel(),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: innerBoxIsScrolled ? 4 : 0,
              shadowColor: Theme.of(context).shadowColor.withOpacity(0.1),
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              title: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Image.asset(
                  AppStyles.logoImage,
                  width: isMobile ? 80.0 : 100.0,
                  height: isMobile ? 80.0 : 100.0,
                ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: isMobile ? 8.0 : 16.0),
                  child: UserAvatar(user: widget.user),
                ),
              ],
            ),
            SliverPersistentHeader(
              pinned: false,
              floating: true,
              delegate: SliverSearchBarDelegate(
                minHeight: 80,
                maxHeight: 80,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8.0 : 16.0,
                      vertical: 8.0,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: screenWidth >= 600
                            ? screenWidth / 2
                            : screenWidth * 0.9,
                        child: SearchBarCustom(
                          controller: _searchController,
                          onSearch: _performSearch,
                          onModuleSelected: (module) {
                            setState(() {
                              _selectedModule = module;
                              _updateFutures();
                            });
                          },
                          modules: _modules,
                          selectedModule: _selectedModule,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: SliverTabBarDelegate(
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  indicatorPadding: EdgeInsets.all(isMobile ? 5.0 : 10.0),
                  indicatorSize: TabBarIndicatorSize.tab,
                  controller: _tabController,
                  indicator: const BoxDecoration(
                    image: DecorationImage(
                      alignment: Alignment.center,
                      opacity: 0.8,
                      scale: 0.5,
                      image: AssetImage(AppStyles.tabMarkerImage),
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                  labelColor: AppStyles.colorAvatarBorder,
                  unselectedLabelColor: Theme.of(context).disabledColor,
                  indicatorColor: AppStyles.colorAvatarBorder,
                  dividerColor: Colors.transparent,
                  tabs: [
                    _buildTab('feedGeneralTab'),
                    _buildTab('FollowingTab'),
                    _buildTab('projectsTab'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsList(_postsFutureGeneral!, isMobile),
            _buildPostsList(_postsFutureFollowing!, isMobile),
            ProjectListView(
              future: _postsProjects!,
              isMobile: isMobile,
              onRefresh: () {},
            ),
          ],
        ),
      ),
      floatingActionButton:
          (_tabController.index == 0 || _tabController.index == 1)
              ? Visibility(
                  visible: MediaQuery.of(context).viewInsets.bottom == 0,
                  child: FloatingActionButton(
                    foregroundColor: Colors.white,
                    backgroundColor: AppStyles.colorAvatarBorder,
                    enableFeedback: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    ),
                    mini: false,
                    onPressed: _showCreatePostDialog,
                    child: const Icon(EvaIcons.plus_outline),
                  ),
                )
              : Visibility(
                  visible: MediaQuery.of(context).viewInsets.bottom == 0,
                  child: FloatingActionButton(
                    foregroundColor: Colors.white,
                    backgroundColor: AppStyles.colorAvatarBorder,
                    enableFeedback: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    ),
                    mini: false,
                    onPressed: _showCreateProjectDialog,
                    child: const Icon(EvaIcons.folder_add),
                  ),
                ),
    );
  }

  Widget _buildTab(String textKey) {
    return Tab(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 80), // Reducir de 100 a 80
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8), // Añadir padding horizontal
          child: Text(
            Texts.translate(textKey, globalLanguage),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppStyles.fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class SliverSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  SliverSearchBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(SliverSearchBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
