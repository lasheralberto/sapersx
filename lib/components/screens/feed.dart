import 'package:file_picker/file_picker.dart';
import 'package:floating_menu_button/floating_menu_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:icons_plus/icons_plus.dart';
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
  Future<List<String>>? _futureTags;
  Future<List<Project>>? _postsProjects;
  bool _isRefreshing = false;
  bool isPostExpanded = false;
  UserInfoPopUp? userinfo;
  LanguageProvider languageProvider = LanguageProvider();
  String? tagPressed;
  bool trendsPressed = false;
  bool searchPressed = false;
  final SidebarController _sidebarController = SidebarController();
  int takenTags = 10;

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        _updateFutures();
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
        _updateFutures();
      }
    }
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
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close,
              size: 16,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: FloatingMenuWidget(
        menuTray: const MenuTray(
            itemsSeparation: 30,
            itemTextStyle: TextStyle(fontWeight: FontWeight.bold),
            padding: EdgeInsets.all(10),
            trayHeight: 150,
            trayWidth: 150),
        menuButton: MenuButton(
          padding: const EdgeInsets.only(right: 30, left: 15),
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
          ),
          iconSize: 20,
          iconOnClose: Icons.add,
          iconOnOpen: Icons.close,
          iconColor: AppStyles.colorAvatarBorder,
          textOnClose:
              Texts.translate('open', LanguageProvider().currentLanguage),
          textOnOpen:
              Texts.translate('close', LanguageProvider().currentLanguage),
        ),
        menuItems: [
          MenuItems(
              id: "1",
              value: Texts.translate(
                  'crearPost', LanguageProvider().currentLanguage)),
          MenuItems(
              id: "2",
              value: Texts.translate(
                  'nuevoProyecto', LanguageProvider().currentLanguage)),
        ],
        onItemSelection: (menuItems) {
          if (menuItems.id == "1") {
            _showCreatePostDialog();
          } else if (menuItems.id == "2") {
            _showCreateProjectDialog();
          } else if (menuItems.id == "3") {}
        },
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: innerBoxIsScrolled ? 4 : 0,
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
                    // Modifica el InkWell del icono de búsqueda
                    Row(
                      children: [
                        FloatingActionButton(
                          elevation: 1,
                          backgroundColor: Colors.white,
                          mini: true,
                          onPressed: () {
                            _sidebarController.toggle();
                          },
                          child: AnimatedBuilder(
                            animation: _sidebarController,
                            builder: (context, _) {
                              return Icon(
                                _sidebarController.isOpen
                                    ? Icons.close
                                    : Icons.tag,
                                color: AppStyles.colorAvatarBorder,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 18),
                        InkWell(
                          child: const Icon(Icons.search),
                          onTap: () {
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
              ),
              SliverPersistentHeader(
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
                          width: screenWidth >= 600
                              ? screenWidth / 2
                              : screenWidth * 0.9,
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
                      _buildTab('genteTab')
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              FutureBuilder<List<String>>(
                future: _futureTags,
                builder: (context, snapshot) {
                  List<String> trendingTags = ['PP']; // Valor por defecto

                  if (snapshot.hasData) {
                    trendingTags = snapshot.data!;
                  }

                  return PostsListWithSidebar(
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
              ),
              FutureBuilder<List<String>>(
                future: _futureTags,
                builder: (context, snapshot) {
                  List<String> trendingTags = ['PP']; // Valor por defecto

                  if (snapshot.hasData) {
                    trendingTags = snapshot.data!;
                  }

                  return PostsListWithSidebar(
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
              ),
              // _buildPostsList(_postsFutureGeneral!, isMobile),
              //_buildPostsList(_postsFutureFollowing!, isMobile),
              ProjectListView(
                future: _postsProjects!,
                isMobile: isMobile,
                onRefresh: () {
                  _updateFutures();
                },
              ),
              const UserSearchScreen()
            ],
          ),
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
            Texts.translate(textKey, languageProvider.currentLanguage),
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

// Agrega esta clase personalizada para el delegate animado
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
