import 'package:flutter/material.dart';
import 'package:sapers/components/widgets/postcard.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/styles.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/user_tier.dart';
import 'package:sapers/components/widgets/user_card.dart';
import 'dart:math' as math;

// Tu widget TrendingTagsSidebar existente
class TrendingTagsSidebar extends StatefulWidget {
  final List<String> trendingTags;
  final Function(String) onTagSelected;
  final SidebarController sidebarController;

  const TrendingTagsSidebar({
    super.key,
    required this.trendingTags,
    required this.onTagSelected,
    required this.sidebarController,
  });

  @override
  State<TrendingTagsSidebar> createState() => _TrendingTagsSidebarState();
}

class _TrendingTagsSidebarState extends State<TrendingTagsSidebar> {
  String? selectedTag;

  void _handleTagSelection(String tag) {
    setState(() {
      // Si el tag ya está seleccionado, lo deseleccionamos
      if (selectedTag == tag) {
        selectedTag = null;
        widget.onTagSelected('');
      } else {
        // Si no está seleccionado, lo seleccionamos
        selectedTag = tag;
        widget.onTagSelected(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.3,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del sidebar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              Texts.translate(
                  'trendingTags', LanguageProvider().currentLanguage),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppStyles.colorAvatarBorder,
                  ),
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Lista de etiquetas
          Expanded(
            child: ListView.builder(
              itemCount: widget.trendingTags.length,
              itemBuilder: (context, index) {
                final tag = widget.trendingTags[index];
                final isSelected = selectedTag == tag;

                return InkWell(
                  onTap: () => _handleTagSelection(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                color: isSelected ? Colors.green : Colors.grey,
                                size: AppStyles.iconSizeSmall,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppStyles.colorAvatarBorder
                                        : Colors.black,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Clase para gestionar el estado del sidebar (con mejoras)
class SidebarController extends ChangeNotifier {
  bool _isOpen = false;
  bool _isFixed = false;

  bool get isOpen => _isOpen;
  bool get isFixed => _isFixed;

  void toggle() {
    _isOpen = !_isOpen;
    notifyListeners();
  }

  void close() {
    if (_isOpen) {
      _isOpen = false;
      notifyListeners();
    }
  }

  void open() {
    if (!_isOpen) {
      _isOpen = true;
      notifyListeners();
    }
  }

  void toggleFixed() {
    _isFixed = !_isFixed;
    _isOpen = true;
    notifyListeners();
  }
}

// Nuevo widget para el menú lateral estilo X
class XMenuSidebar extends StatefulWidget {
  final SidebarController sidebarController;
  final Function(int) onMenuOptionSelected;
  final bool isMobile;

  const XMenuSidebar({
    Key? key,
    required this.sidebarController,
    required this.onMenuOptionSelected,
    required this.isMobile,
  }) : super(key: key);

  @override
  State<XMenuSidebar> createState() => _XMenuSidebarState();
}

class _XMenuSidebarState extends State<XMenuSidebar> {
  int _selectedOption = 0;

  @override
  void initState() {
    super.initState();
    widget.sidebarController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    widget.sidebarController.removeListener(() {});
    super.dispose();
  }

  void _handleMenuOptionTap(int index) {
    if (!mounted) return;
    setState(() {
      _selectedOption = index;
      widget.onMenuOptionSelected(index);
      if (widget.isMobile) {
        widget.sidebarController.close();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isMobile
          ? MediaQuery.of(context).size.width * 0.7
          : MediaQuery.of(context).size.width * 0.25,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          // User profile section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppStyles.colorAvatarBorder,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usuario',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '@username',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Menu items
          _buildMenuItem(0, Icons.home_rounded, 'Inicio'),
          _buildMenuItem(1, Icons.search, 'Explorar'),
          _buildMenuItem(2, Icons.notifications_outlined, 'Notificaciones'),
          _buildMenuItem(3, Icons.mail_outline, 'Mensajes'),
          _buildMenuItem(4, Icons.bookmark_border, 'Guardados'),
          const Spacer(),
          // Settings option
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {},
              child: const Row(
                children: [
                  Icon(Icons.settings_outlined),
                  SizedBox(width: 12),
                  Text('Configuración'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String label) {
    final isSelected = _selectedOption == index;

    return InkWell(
      onTap: () => _handleMenuOptionTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppStyles.colorAvatarBorder.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppStyles.colorAvatarBorder : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppStyles.colorAvatarBorder : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Menú flotante para abrir el sidebar
class FloatingMenuButton extends StatelessWidget {
  final SidebarController controller;

  const FloatingMenuButton({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      top: 40,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          // Solo mostrar cuando el sidebar no está fijo o cuando está cerrado
          if (controller.isFixed && controller.isOpen) {
            return const SizedBox.shrink();
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            transform:
                Matrix4.translationValues(controller.isOpen ? 240 : 0, 0, 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppStyles.colorAvatarBorder,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  controller.isOpen ? Icons.close : Icons.menu,
                  color: Colors.white,
                ),
                onPressed: () => controller.toggle(),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Widget modificado para incorporar ambos sidebars
class PostsListWithSidebar extends StatefulWidget {
  final Future<List<SAPPost>> future;
  final bool isMobile;
  final List<String> trendingTags;
  final String? selectedTag;
  final Function(String?) onTagSelected;
  final Function(bool) onPostExpanded;
  final Function onRefresh;
  final SidebarController sidebarController;
  final SidebarController
      menuSidebarController; // Nuevo controlador para el menú X

  const PostsListWithSidebar({
    super.key,
    required this.future,
    required this.isMobile,
    required this.trendingTags,
    required this.onTagSelected,
    required this.selectedTag,
    required this.onPostExpanded,
    required this.onRefresh,
    required this.sidebarController,
    required this.menuSidebarController, // Nuevo parámetro
  });

  @override
  _PostsListWithSidebarState createState() => _PostsListWithSidebarState();
}

class _PostsListWithSidebarState extends State<PostsListWithSidebar> {
  bool _isRefreshing = false;
  int _selectedMenuOption = 0;
  Stream<List<UserInfoPopUp>>? _topContributors;
  final FirebaseService _firebaseService = FirebaseService();
  List<UserInfoPopUp>? _featuredUsers;
  final _random = math.Random();
  List<SAPPost>? _topPosts;
  List<String>? _hotTopics;

  // Cache para datos
  static final Map<String, List<UserInfoPopUp>> _contributorsCache = {};
  static final Map<String, List<String>> _topicsCache = {};

  // Control de paginación
  final int _pageSize = 10;
  int _currentPage = 0;
  bool _hasMorePosts = true;
  final List<SAPPost> _loadedPosts = [];
  bool _isLoadingMore = false;

  // ScrollController para lazy loading
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadInitialPosts(),
      _loadTopContributors(),
      _loadHotTopics(),
    ]);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMorePosts();
    }
  }

  Future<void> _loadInitialPosts() async {
    if (_loadedPosts.isEmpty) {
      final posts = await widget.future;
      setState(() {
        _loadedPosts.addAll(posts.take(_pageSize));
        _currentPage = 1;
        _hasMorePosts = posts.length > _pageSize;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_hasMorePosts || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final allPosts = await widget.future;
      final nextPosts =
          allPosts.skip(_currentPage * _pageSize).take(_pageSize).toList();

      if (nextPosts.isNotEmpty) {
        setState(() {
          _loadedPosts.addAll(nextPosts);
          _currentPage++;
          _hasMorePosts = allPosts.length > _loadedPosts.length;
        });
      } else {
        setState(() => _hasMorePosts = false);
      }
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadTopContributors() async {
    final cacheKey = 'contributors_${DateTime.now().day}';
    if (_contributorsCache.containsKey(cacheKey)) {
      setState(
          () => _topContributors = Stream.value(_contributorsCache[cacheKey]!));
      return;
    }

    final contributorsStream =
        _firebaseService.getTopContributors().asBroadcastStream();
    contributorsStream.listen((contributors) {
      _contributorsCache[cacheKey] = contributors;
    });

    setState(() => _topContributors = contributorsStream);
  }

  Future<void> _loadHotTopics() async {
    final cacheKey = 'topics_${DateTime.now().hour}';
    if (_topicsCache.containsKey(cacheKey)) {
      setState(() => _hotTopics = _topicsCache[cacheKey]);
      return;
    }

    try {
      final topics = await _firebaseService.getAllTags(10);
      _topicsCache[cacheKey] = topics;
      if (mounted) setState(() => _hotTopics = topics);
    } catch (e) {
      debugPrint('Error loading hot topics: $e');
    }
  }

  Widget _buildPostCard(SAPPost post, bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 0 : 8.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        child: PostCard(
          key: ValueKey(post.id),
          onExpandChanged: (p0) => setState(() => widget.onPostExpanded(p0)),
          tagPressed: widget.onTagSelected,
          selectedTag: widget.selectedTag,
          post: post,
        ),
      ),
    );
  }

  Widget _buildCombinedFeaturesRow() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: StreamBuilder<List<UserInfoPopUp>>(
        stream: _topContributors,
        builder: (context, snapshot) {
          List<Widget> allItems = [];

          // Add hot topics if available
          if (_hotTopics != null) {
            allItems
                .addAll(_hotTopics!.map((topic) => _buildHotTopicItem(topic)));
          }

          // Add contributors if available
          if (snapshot.hasData) {
            allItems.addAll(snapshot.data!
                .map((contributor) => _buildContributorItem(contributor)));
          }

          // Shuffle all items
          if (allItems.isNotEmpty) {
            allItems.shuffle(_random);
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: allItems.length,
            itemBuilder: (context, index) => allItems[index],
          );
        },
      ),
    );
  }

  Widget _buildHotTopicItem(String topic) {
    final isSelected = topic == widget.selectedTag;
    return Container(
      height: 36,
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        elevation: AppStyles.cardElevation,
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        child: InkWell(
          onTap: () => widget.onTagSelected(topic),
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppStyles.colorAvatarBorder.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppStyles.colorAvatarBorder.withOpacity(0.3)
                    : Colors.white,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up_rounded,
                    size: 14, color: AppStyles.colorAvatarBorder),
                const SizedBox(width: 4),
                Text(
                  topic,
                  style: TextStyle(
                    color: isSelected
                        ? AppStyles.colorAvatarBorder
                        : Colors.grey[800],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContributorItem(UserInfoPopUp contributor) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserProfileCardHover(
            authorUsername: contributor.username,
            isExpert: contributor.isExpert as bool,
            onProfileOpen: () {},
          ),
          const SizedBox(height: 4),
          Text(
            contributor.username,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTopPostsRow() {
    if (_topPosts == null || _topPosts!.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles.colorAvatarBorder.withOpacity(0.1),
            AppStyles.colorAvatarBorder.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: AppStyles.colorAvatarBorder),
                SizedBox(width: 8),
                Text(
                  'Posts Destacados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.colorAvatarBorder,
                  ),
                ),
              ],
            ),
          ),
          for (var post in _topPosts!)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPostCard(post, widget.isMobile),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Combined features row
            SliverToBoxAdapter(
              child: Container(
                height: 8,
                color: AppStyles.scaffoldColor,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildCombinedFeaturesRow(),
            ),

            // Primeros 5 posts
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _loadedPosts.length && _hasMorePosts) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (index >= _loadedPosts.length) return null;
                  return _buildPostCard(_loadedPosts[index], widget.isMobile);
                },
                childCount: _loadedPosts.length + (_hasMorePosts ? 1 : 0),
              ),
            ),

            // Posts destacados después de los primeros 5
            SliverToBoxAdapter(child: _buildTopPostsRow()),
          ],
        ),

        // Menú lateral estilo X con animación
        AnimatedBuilder(
          animation: widget.menuSidebarController,
          builder: (context, _) {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: widget.menuSidebarController.isOpen
                  ? 0
                  : -MediaQuery.of(context).size.width *
                      (widget.isMobile ? 0.7 : 0.25),
              top: 0,
              bottom: 0,
              width: widget.isMobile
                  ? MediaQuery.of(context).size.width * 0.7
                  : MediaQuery.of(context).size.width * 0.25,
              child: XMenuSidebar(
                sidebarController: widget.menuSidebarController,
                isMobile: widget.isMobile,
                onMenuOptionSelected: (index) {
                  setState(() {
                    _selectedMenuOption = index;
                  });
                  // Aquí puedes añadir cualquier otra acción al seleccionar
                },
              ),
            );
          },
        ),

        // Sidebar de tendencias con animación (original)
        AnimatedBuilder(
          animation: widget.sidebarController,
          builder: (context, _) {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: widget.sidebarController.isOpen
                  ? 0
                  : -MediaQuery.of(context).size.width *
                      (widget.isMobile ? 0.5 : 0.33),
              top: 0,
              bottom: 0,
              width: widget.isMobile
                  ? MediaQuery.of(context).size.width * 0.5
                  : MediaQuery.of(context).size.width * 0.33,
              child: GestureDetector(
                onTap: () {}, // Evita que los clics pasen a través del sidebar
                child: TrendingTagsSidebar(
                  sidebarController: widget.sidebarController,
                  trendingTags: widget.trendingTags,
                  onTagSelected: (tag) {
                    widget.onTagSelected(tag);
                    if (widget.isMobile) {
                      widget.sidebarController.close();
                    }
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
