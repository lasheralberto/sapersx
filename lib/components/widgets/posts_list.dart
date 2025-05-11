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

  @override
  void initState() {
    super.initState();
    _loadTopContributors();
    _loadFeaturedUsers();
  }

  Future<void> _loadTopContributors() async {
    setState(() {
      _topContributors =
          _firebaseService.getTopContributors().asBroadcastStream();
    });
  }

  Future<void> _loadFeaturedUsers() async {
    _firebaseService.getTopContributors().listen((users) {
      if (users.length >= 2) {
        // Ordenar por score y tomar los 2 primeros
        users.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
        setState(() {
          _featuredUsers = users.take(2).toList();
        });
      }
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Aquí deberías implementar tu lógica de recarga
    widget.onRefresh();

    setState(() {
      _isRefreshing = false;
    });
  }

  Widget _buildPostCard(SAPPost post, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(
        bottom: isMobile ? 8.0 : 16.0,
        left: isMobile ? 2.0 : 8.0,
        right: isMobile ? 2.0 : 8.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: null,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          width: 0.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        child: Material(
          color: Colors.transparent,
          child: PostCard(
            key: ValueKey(post.id),
            onExpandChanged: (p0) => setState(() => widget.onPostExpanded(p0)),
            tagPressed:
                widget.onTagSelected, // Simply pass through the callback
            selectedTag: widget.selectedTag, // Use widget prop directly
            post: post,
          ),
        ),
      ),
    );
  }

  Widget _buildTopContributorsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            Texts.translate(
                'TopContributors', LanguageProvider().currentLanguage),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: StreamBuilder<List<UserInfoPopUp>>(
            stream: _topContributors,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final contributor = snapshot.data![index];
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: UserProfileCardHover(
                                authorUsername: contributor.username,
                                isExpert: contributor.isExpert as bool,
                                onProfileOpen: () {},
                              ),
                            ),
                            // Points Badge
                          ],
                        ),
                        const SizedBox(height: 8),
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
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedUsersRow() {
    if (_featuredUsers == null || _featuredUsers!.length < 2)
      return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryFixed,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              Texts.translate(
                  'featuredUsers', LanguageProvider().currentLanguage),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                for (var user in _featuredUsers!)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: UserCard(
                        user: user,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/profile',
                          arguments: user,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<SAPPost>>(
          future: widget.future,
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
                  Texts.translate(
                      'noposts', LanguageProvider().currentLanguage),
                ),
              );
            }

            // Insertar featured users en una posición aleatoria
            int featuredUsersPosition = _random.nextInt(posts.length);

            return LiquidPullToRefresh(
              backgroundColor: AppStyles.colorAvatarBorder,
              onRefresh: _handleRefresh,
              animSpeedFactor: 1,
              child: Row(
                children: [
                  // Espacio para el menú lateral fijo si está activo
                  AnimatedBuilder(
                    animation: widget.menuSidebarController,
                    builder: (context, _) {
                      return widget.menuSidebarController.isFixed &&
                              widget.menuSidebarController.isOpen &&
                              !widget.isMobile
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width * 0.25)
                          : const SizedBox.shrink();
                    },
                  ),

                  // Lista principal
                  Expanded(
                    flex: 10,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Top contributors
                        SliverToBoxAdapter(
                          child: _buildTopContributorsRow(),
                        ),

                        // Primeros 10 posts
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildPostCard(posts[index], widget.isMobile),
                            childCount: math.min(10, posts.length),
                          ),
                        ),

                        // Featured users después de los primeros 10 posts
                        SliverToBoxAdapter(child: _buildFeaturedUsersRow()),

                        // Resto de los posts
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildPostCard(
                              posts[index + math.min(10, posts.length)],
                              widget.isMobile,
                            ),
                            childCount: math.max(0, posts.length - 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Botón flotante menú lateral estilo X
        //  FloatingMenuButton(controller: widget.menuSidebarController),

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
