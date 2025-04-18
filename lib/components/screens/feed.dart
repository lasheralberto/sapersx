import 'package:file_picker/file_picker.dart';
import 'package:sapers/components/widgets/achievement_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/components/screens/people_screen.dart';
import 'package:sapers/components/screens/popup_create_post.dart';
import 'package:sapers/components/screens/project_dialog.dart';
import 'package:sapers/components/screens/project_screen.dart';
import 'package:sapers/components/widgets/postcard.dart';
import 'package:sapers/components/widgets/posts_list.dart';
import 'package:sapers/components/widgets/project_card.dart';
import 'package:sapers/components/widgets/project_list.dart';
import 'package:sapers/components/widgets/sap_ia_widget.dart';
import 'package:sapers/components/widgets/searchbar.dart';
import 'package:sapers/components/widgets/user_avatar.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/theme.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/utils_sapers.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

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
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  bool _showLeaderboard = false;
  Stream<List<UserInfoPopUp>>? _topContributors;
  AnimationController? _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadTopContributors();
    _initializeGamification();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _panelController.animatePanelToPosition(
          1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
    _updateFutures();
  }

  Future<void> _loadTopContributors() async {
    // Implement loading top contributors logic
    _topContributors = await _firebaseService.getTopContributors();
    setState(() {});
  }

  void _initializeGamification() {
    // Initialize gamification features
    _firebaseService.subscribeToUserAchievements(widget.user?.uid ?? '', (achievement) {
      _showAchievementAnimation(achievement);
    });
  }

  void _showAchievementAnimation(String achievement) {
    showDialog(
      context: context,
      builder: (context) => AchievementDialog(
        achievement: achievement,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }
  final List<String> _modules = Modules.modules;
  List<PlatformFile> selectedFiles = [];
  final PanelController _panelController = PanelController();

  late TabController _tabController;
  String _selectedModule = '';
  Future<List<SAPPost>>? _postsFutureGeneral;
  Future<List<SAPPost>>? _postsFutureFollowing;
  Future<List<String>>? _futureTags;
  Future<List<Project>>? _postsProjects;
  final bool _isRefreshing = false;
  bool isPostExpanded = false;
  UserInfoPopUp? userinfo;
  LanguageProvider languageProvider = LanguageProvider();
  String? tagPressed;
  bool trendsPressed = false;
  bool searchPressed = false;
  final SidebarController _sidebarController = SidebarController();
  final SidebarController _menuSidebarController = SidebarController();
  int takenTags = 10;
  bool _isPanelOpen = false;
  double _panelPosition = 0.0;
  final FocusNode _searchFocusNode = FocusNode();
  bool isMobile = false;

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _menuSidebarController.dispose();
    super.dispose();
  }


  Future<void> _updateFutures() async {
    // Determinar qué posts cargar basado en los filtros seleccionados
    final Future<List<SAPPost>> generalPosts;
    if (tagPressed != null) {
      // Si se ha pulsado un tag, obtener los posts por tag
      if (tagPressed == 'null') {
        generalPosts = _firebaseService.getPostsFuture();
      } else {
        generalPosts = _firebaseService.getPostsbyTag(tagPressed!);
      }
    } else if (_selectedModule.isNotEmpty) {
      // Si no se ha pulsado un tag pero hay un módulo seleccionado, obtener los posts por módulo
      generalPosts = _firebaseService.getPostsByModuleFuture(_selectedModule);
    } else {
      // Si no se ha pulsado un tag y no hay ningún módulo seleccionado, obtener todos los posts
      generalPosts = _firebaseService.getPostsFuture();
    }
    // Cargar posts de seguidos y proyectos en paralelo
    final followingPosts = _firebaseService.getPostsFollowingFuture();
    final projectsPosts = _firebaseService.getProjectsFuture();
    final tags = _firebaseService.getAllTags(takenTags);

    // Actualizar el estado con los nuevos futures
    setState(() {
      _postsFutureGeneral = generalPosts;
      _postsFutureFollowing = followingPosts;
      _postsProjects = projectsPosts;
      _futureTags = tags;
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

  Widget tagBubblePressed({
    required String tag,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: AppStyles.colorAvatarBorder, width: 1),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(
              color: Colors.black,
              fontSize: AppStyles.fontSizeMedium, // Usando fontSizeMedium
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Symbols.close,
              size: AppStyles.iconSizeSmall, // Usando iconSizeSmall
              weight: 1150.0,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalSidebarToggle() {
    return IconButton(
      icon: AnimatedBuilder(
        animation: _sidebarController,
        builder: (context, _) {
          return Icon(
            _sidebarController.isOpen ? Symbols.close : Symbols.tag,
            color: AppStyles.colorAvatarBorder,
            size: AppStyles.iconSizeMedium, // Usando iconSizeMedium
          );
        },
      ),
      onPressed: () {
        _sidebarController.toggle();
      },
      splashRadius:
          24.0, // Reduce el área de interacción para hacerlo más minimalista
      tooltip: _sidebarController.isOpen ? 'Cerrar Sidebar' : 'Abrir Sidebar',
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = 0.0;
    isMobile = MediaQuery.of(context).size.width < 600;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: _tabController.index == 0
          ? _buildSlidingUpPanelUI(context, isMobile, screenWidth)
          : _buildRegularUI(context, isMobile, screenWidth),
    );
  }

// En la clase _FeedState, actualiza este método:

  Widget _buildSlidingUpPanelUI(
      BuildContext context, bool isMobile, double screenWidth) {
    return SlidingUpPanel(
      onPanelSlide: (position) {
        setState(() {
          _panelPosition = position;
          _isPanelOpen = position > 0.5;
        });
      },
      controller: _panelController,
      minHeight: 75,
      maxHeight: MediaQuery.of(context).size.height * 0.7,
      parallaxEnabled: false,
      parallaxOffset: 0.5,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24.0),
        topRight: Radius.circular(24.0),
      ),
      panel: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SAPAIAssistantWidget(
              searchFocusNode: _searchFocusNode,
              username: widget.user?.displayName ?? 'UsuarioDemo',
              isPanelVisible: true,
              onPostCreated:
                  _updateFutures, // Actualiza los posts cuando se crea uno nuevo
              onProjectCreated:
                  _updateFutures, // Actualiza los proyectos cuando se crea uno nuevo
            ),
          ),
       
      ],
    ),
    body: _buildContentView(context, isMobile, screenWidth),
  );
}


  Widget _buildRegularUI(
      BuildContext context, bool isMobile, double screenWidth) {
    return _buildContentView(context, isMobile, screenWidth);
  }

  Widget _buildContentView(
      BuildContext context, bool isMobile, double screenWidth) {
    return _buildNestedScrollView(context, isMobile, screenWidth);
  }

  Widget _buildNestedScrollView(
      BuildContext context, bool isMobile, double screenWidth) {
    return NestedScrollView(
      controller:
          PrimaryScrollController.of(context), // Usa el controlador principal
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          _buildAppBar(context, isMobile),
          _buildSearchBarHeader(context, isMobile, screenWidth),
          _buildTabBarHeader(),
        ];
      },
      body: _buildTabBarView(context, isMobile),
    );
  }

  Widget _buildTabBarView(BuildContext context, bool isMobile) {
    return TabBarView(
      controller: _tabController,
      physics:
          const ClampingScrollPhysics(), // Evita conflictos de desplazamiento
      children: [
        _buildGeneralPostsTab(isMobile),
        _buildFollowingPostsTab(isMobile),
        _buildProjectsTab(isMobile),
        const UserSearchScreen(),
      ],
    );
  }

  Widget _buildGeneralPostsTab(bool isMobile) {
    return FutureBuilder<List<String>>(
      future: _futureTags,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return UtilsSapers()
              .buildShimmerEffect(5, UtilsSapers().buildShimmerPost(context));
        }

        List<String> trendingTags = ['PP']; // Valor por defecto

        if (snapshot.hasData) {
          trendingTags = snapshot.data!;
        }

        return PostsListWithSidebar(
            menuSidebarController: _menuSidebarController,
            sidebarController: _sidebarController,
            onRefresh: _updateFutures,
            onPostExpanded: (p0) {
              setState(() {
                isPostExpanded = p0;
              });
            },
            future: _postsFutureGeneral!,
            isMobile: isMobile,
            trendingTags: trendingTags,
            onTagSelected: (tag) {
              setState(() {
                tagPressed = tag;
                _updateFutures();
              });
            });
      },
    );
  }

  Widget _buildFollowingPostsTab(bool isMobile) {
    return FutureBuilder<List<String>>(
      future: _futureTags,
      builder: (context, snapshot) {
        List<String> trendingTags = ['PP']; // Valor por defecto

        if (snapshot.hasData) {
          trendingTags = snapshot.data!;
        }

        return PostsListWithSidebar(
            menuSidebarController: _menuSidebarController,
            sidebarController: _sidebarController,
            onRefresh: _updateFutures,
            onPostExpanded: (p0) {
              setState(() {
                isPostExpanded = p0;
              });
            },
            future: _postsFutureFollowing!,
            isMobile: isMobile,
            trendingTags: trendingTags,
            onTagSelected: (tag) {
              setState(() {
                tagPressed = tag;
                _updateFutures();
              });
            });
      },
    );
  }

  Widget _buildProjectsTab(bool isMobile) {
    return ProjectListView(
      future: _postsProjects!,
      isMobile: isMobile,
      onRefresh: () {
        _updateFutures();
      },
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isMobile) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 4,
      shadowColor: Theme.of(context).shadowColor.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
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
          Row(
            children: [
              _buildMinimalSidebarToggle(),
              const SizedBox(width: 18),
              IconButton(
                icon: const Icon(
                  Symbols.search,
                  size: AppStyles.iconSizeMedium,
                  color: AppStyles.colorAvatarBorder,
                ),
                onPressed: () {
                  setState(() {
                    searchPressed = !searchPressed;
                  });
                },
              ),
            ],
          )
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: isMobile ? 8.0 : 16.0),
          child: UserAvatar(user: widget.user),
        ),
      ],
    );
  }

  SliverPersistentHeader _buildSearchBarHeader(
      BuildContext context, bool isMobile, double screenWidth) {
    return SliverPersistentHeader(
      pinned: false,
      floating: true,
      delegate: AnimatedSliverHeaderDelegate(
        visible: searchPressed,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8.0 : 16.0,
              vertical: 8.0,
            ),
            child: Center(
              child: SizedBox(
                width: screenWidth >= 600 ? screenWidth / 2 : screenWidth * 0.9,
                child: SearchBarCustom(
                  onDeleteTag: () {
                    setState(() {
                      tagPressed = null;
                      _updateFutures();
                    });
                  },
                  tag: tagPressed.toString(),
                  controller: _searchController,
                  onSearch: _performSearch,
                  onModuleSelected: (module) {
                    setState(() {
                      _selectedModule = module;
                      searchPressed = !searchPressed;
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
    );
  }

  SliverPersistentHeader _buildTabBarHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: SliverTabBarDelegate(
        TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorPadding: const EdgeInsets.all(10.0),
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
            _buildTab('genteTab')
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String textKey) {
    return Tab(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 80),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            Texts.translate(textKey, languageProvider.currentLanguage),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppStyles.fontSize, // Usando fontSize
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Header Delegate Classes

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

class AnimatedSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool visible;
  final Widget child;
  final Animation<double> _animation;

  AnimatedSliverHeaderDelegate({
    required this.visible,
    required this.child,
  }) : _animation = CurvedAnimation(
          parent: kAlwaysCompleteAnimation,
          curve: Curves.easeInOut,
        ) {
    _animation.addListener(() {});
  }

  @override
  double get minExtent => visible ? 80 : 0;
  @override
  double get maxExtent => visible ? 80 : 0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: visible ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        height: visible ? 80 : 0,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: 80,
          child: visible ? child : const SizedBox.shrink(),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(AnimatedSliverHeaderDelegate oldDelegate) {
    return visible != oldDelegate.visible || child != oldDelegate.child;
  }

  @override
  FloatingHeaderSnapConfiguration? get snapConfiguration => null;
  @override
  OverScrollHeaderStretchConfiguration? get stretchConfiguration => null;
}