import 'package:file_picker/file_picker.dart';
import 'package:sapers/components/screens/messages_screen.dart';
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
import 'package:sapers/components/widgets/sapers_ai_icon.dart';
import 'package:sapers/components/widgets/searchbar.dart';
import 'package:sapers/components/widgets/user_avatar.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
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

  AnimationController? _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

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

  final List<String> _modules = Modules.modules;
  List<PlatformFile> selectedFiles = [];
  final PanelController _panelController = PanelController();

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
  int _currentIndex = 0; // Replace TabController with simple index
  bool _showPanel = false;

  @override
  void dispose() {
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

  void _togglePanel() {
    setState(() {
      _showPanel = !_showPanel;
      if (_showPanel) {
        _panelController.animatePanelToPosition(1.0);
      } else {
        _panelController.close();
      }
    });
  }

  void _showCreatePostDialog() async {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => const LoginScreen(),
        ),
      );
    } else {
      final result = await showDialog<SAPPost>(
        context: context,
        builder: (context) => const CreatePostScreen(),
      );

      if (result != null) {
        await _firebaseService.createPost(result);
        await _updateFutures();
        setState(() {}); // Forzar reconstrucción del widget
      }
    }
  }

  void _showCreateProjectDialog() async {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => const LoginScreen(),
        ),
      );
    } else {
      UserInfoPopUp? user =
          Provider.of<AuthProviderSapers>(context, listen: false).userInfo;

      final result = await showDialog<Project>(
        context: context,
        builder: (context) => CreateProjectScreen(user: user),
      );

      if (result != null) {
        await _firebaseService.createProject(result);
        // if (widget.onProjectCreated != null) {
        //   widget.onProjectCreated!();
        // }
      }
    }
  }

  void _showCreateOptions() {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Symbols.post_add, weight: 1150.0),
                title: Text(
                  Texts.translate(
                      'crearPost', languageProvider.currentLanguage),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePostDialog();
                },
              ),
              ListTile(
                leading: const Icon(Symbols.add_task, weight: 1150.0),
                title: Text(
                  Texts.translate(
                      'nuevoProyecto', languageProvider.currentLanguage),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateProjectDialog();
                },
              ),
            ],
          ),
        );
      },
    );
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
              weight: 1120.0,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = 0.0;
    isMobile = MediaQuery.of(context).size.width < 600;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: _buildSlidingUpPanelUI(context, isMobile, screenWidth),
      floatingActionButton: _currentIndex == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // AI Assistant button
                FloatingActionButton(
                  heroTag: "btn2",
                  onPressed: _togglePanel,
                  backgroundColor: Colors.transparent,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NebulaEffect(shouldMove: false),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: "btn1",
                  onPressed: _showCreateOptions,
                  backgroundColor: AppStyles.colorAvatarBorder,
                  child: const Icon(
                    Symbols.add,
                    color: AppStyles.scaffoldBackgroundColorBright,
                    size: AppStyles.iconSizeSmall,
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildSlidingUpPanelUI(
      BuildContext context, bool isMobile, double screenWidth) {
    return Material(
      child: Stack(
        children: [
          Row(
            children: [
              if (!isMobile)
                Material(
                  elevation: 0,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  surfaceTintColor: Colors.white,
                  child: SizedBox(
                    width: 250,
                    height: MediaQuery.of(context).size.height,
                    child: _buildSideMenu(),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isMobile)
                      AppBar(
                        elevation: 0,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        leading: IconButton(
                          icon: const Icon(
                            Symbols.menu,
                            color: AppStyles.colorAvatarBorder,
                            size: AppStyles.iconSizeMedium,
                          ),
                          onPressed: () {
                            setState(() {
                              _menuSidebarController.toggle();
                            });
                          },
                        ),
                        centerTitle: true,
                        title: Image.asset(
                          AppStyles.logoImage,
                          height: 40,
                        ),
                      ),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: isMobile ? kBottomNavigationBarHeight : 0,
                            ),
                            child: _getCurrentView(isMobile),
                          ),
                          if (_currentIndex == 0)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: SlidingUpPanel(
                                controller: _panelController,
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.7,
                                minHeight:
                                    _showPanel ? (isMobile ? 75 : 85) : 0,
                                onPanelSlide: (position) {
                                  setState(() {
                                    _panelPosition = position;
                                    _isPanelOpen = position > 0;
                                  });
                                },
                                onPanelClosed: () {
                                  setState(() => _showPanel = false);
                                },
                                backdropEnabled: true,
                                backdropOpacity: 0.5,
                                boxShadow: const [],
                                renderPanelSheet: true, // Cambiado a true
                                panel: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24.0)),
                                  child: Material(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    child: SAPAIAssistantWidget(
                                      searchFocusNode: _searchFocusNode,
                                      username: widget.user?.displayName ??
                                          'UsuarioDemo',
                                      isPanelVisible: true,
                                      onPostCreated: _updateFutures,
                                      onProjectCreated: _updateFutures,
                                    ),
                                  ),
                                ),
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
          if (isMobile)
            AnimatedBuilder(
              animation: _menuSidebarController,
              builder: (context, _) {
                return Stack(
                  children: [
                    if (_menuSidebarController.isOpen)
                      GestureDetector(
                        onTap: () => _menuSidebarController.close(),
                        child: Container(
                          color: Colors.black54,
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(
                        _menuSidebarController.isOpen ? 0 : -250,
                        0,
                        0,
                      ),
                      child: Material(
                        elevation: 8,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: SizedBox(
                          width: 250,
                          height: MediaQuery.of(context).size.height,
                          child: _buildSideMenu(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _getCurrentView(bool isMobile) {
    switch (_currentIndex) {
      case 0:
        return _buildGeneralPostsTab(isMobile);
      case 1:
        return _buildProjectsTab(isMobile);
      case 2:
        return const UserSearchScreen();
      case 3:
        return const MessagesScreen();
      default:
        return _buildGeneralPostsTab(isMobile);
    }
  }

  Widget _buildSideMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Logo section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Image.asset(
            AppStyles.logoImage,
            height: 70,
            width: 70,
          ),
        ),

        // User profile section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 0,
              ),
              color: Colors.transparent,
            ),
            child: Row(
              children: [
                UserAvatar(
                  user: widget.user,
                  size: AppStyles.avatarSize,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    Provider.of<AuthProviderSapers>(context, listen: false)
                            .userInfo
                            ?.username ??
                        Texts.translate('iniciarSesion',
                            LanguageProvider().currentLanguage),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Menu items section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              _buildSideMenuItem(
                icon: Symbols.home_filled,
                label: Texts.translate(
                    'feedTab', LanguageProvider().currentLanguage),
                isSelected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _buildSideMenuItem(
                icon: Symbols.category,
                label: Texts.translate(
                    'projectsTab', LanguageProvider().currentLanguage),
                isSelected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _buildSideMenuItem(
                icon: Symbols.group,
                label: Texts.translate(
                    'personasTab', LanguageProvider().currentLanguage),
                isSelected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _buildSideMenuItem(
                icon: Symbols.email,
                label: Texts.translate(
                    'messagesScreen', LanguageProvider().currentLanguage),
                isSelected: _currentIndex == 3,
                onTap: () {
                  // Implementar navegación a la configuración
                  setState(() {
                    _currentIndex = 3;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSideMenuItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            onTap();
            if (isMobile) {
              _menuSidebarController.close();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppStyles.colorAvatarBorder.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppStyles.colorAvatarBorder
                      : AppStyles.textColor,
                  size: 15,
                  weight: 700,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppStyles.colorAvatarBorder
                        : AppStyles.textColor,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: AppStyles.fontSizeMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

        List<String> trendingTags = ['PP'];

        if (snapshot.hasData) {
          trendingTags = snapshot.data!;
        }

        return Column(
          children: [
            Expanded(
              child: PostsListWithSidebar(
                selectedTag: tagPressed,
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
                },
              ),
            ),
          ],
        );
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
