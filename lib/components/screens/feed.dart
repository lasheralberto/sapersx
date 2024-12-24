import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/components/screens/popup_create_post.dart';
import 'package:sapers/components/widgets/postcard.dart';
import 'package:sapers/components/widgets/searchbar.dart';
import 'package:sapers/components/widgets/user_avatar.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/theme.dart';

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

  late TabController _tabController;
  String _selectedModule = '';
  Future<List<SAPPost>>? _postsFutureGeneral;
  Future<List<SAPPost>>? _postsFutureFollowing;
  bool _isRefreshing = false;
  bool _hasScrolledDown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _updateFutures();
  }

  // Método para manejar la acción de refrescar al hacer pull
  Future<void> _handleRefresh() async {
    if (!_isRefreshing) {
      setState(() {
        _isRefreshing = true;
      });

      await Future.delayed(
          const Duration(seconds: 2)); // Simulación de refresco
      setState(() {
        _updateFutures();
        _isRefreshing = false;
      });
    }
  }

  void _updateFutures() {
    setState(() {
      _postsFutureGeneral = _selectedModule.isEmpty
          ? _firebaseService.getPostsFuture()
          : _firebaseService.getPostsByModuleFuture(_selectedModule);
      _postsFutureFollowing = _firebaseService.getPostsFollowingFuture();
    });
  }

  void _performSearch() {
    final searchText = _searchController.text.trim();
    setState(() {
      _postsFutureGeneral = searchText.isEmpty
          ? _firebaseService.getPostsFuture()
          : _firebaseService.getPostsByKeyword(searchText);

      if (searchText.isEmpty) {
        _selectedModule = '';
      }
    });
  }

  void _showCreatePostDialog() async {
    if (FirebaseAuth.instance.currentUser == null) {
      showDialog(
        context: context,
        builder: (context) => const LoginDialog(),
      );
    } else {
      final result = await showDialog<SAPPost>(
        context: context,
        builder: (context) => const CreatePostDialog(),
      );

      if (result != null) {
        await _firebaseService.createPost(result);
        _updateFutures(); // Actualiza los streams después de crear un post
      }
    }
  }

  Widget _buildPostsList(Future<List<SAPPost>> future) {
    return FutureBuilder<List<SAPPost>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: SelectableText('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
              child: Text(Texts.translate('noposts', globalLanguage)));
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            // Detectamos cuando el usuario está en el inicio
            if (!_isRefreshing &&
                scrollInfo.metrics.pixels <=
                    scrollInfo.metrics.minScrollExtent) {
              // Solo refrescamos si el usuario ha desplazado la lista hacia abajo previamente
              if (_hasScrolledDown) {
                _handleRefresh(); // Llamamos a refrescar
              }
            }

            // Detectamos si el usuario ha hecho scroll hacia abajo (en cualquier dirección)
            if (scrollInfo.metrics.pixels >
                scrollInfo.metrics.minScrollExtent) {
              setState(() {
                _hasScrolledDown =
                    true; // Marcamos que se ha hecho scroll hacia abajo
              });
            }

            return false; // Deja que el scroll siga funcionando normalmente
          },
          child: CustomScrollView(
            slivers: [
              // const SliverAppBar(
              //   expandedHeight: 0.0, // Evita que el AppBar se expanda
              //   floating: true,
              //   pinned: true,
              //   snap: true,
              //   flexibleSpace: SizedBox(),
              // ),
              // Si estamos en web, mostramos el icono de refresco
              if (_isRefreshing)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child:
                        Center(child: Icon(Icons.refresh, color: Colors.grey)),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppStyles().getCardColor(context),
                        borderRadius:
                            BorderRadius.circular(AppStyles.borderRadiusValue),
                      ),
                      child: PostCard(post: posts[index]),
                    );
                  },
                  childCount: posts.length,
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/images/logo.png', // Ruta de tu logo
          width: 100.0, // Ajusta el tamaño del logo según sea necesario
          height: 100.0, // Ajusta el tamaño del logo según sea necesario
        ),
        actions: [
          // IconButton(
          //   icon: Icon(
          //       themeNotifier.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          //   onPressed: () => themeNotifier.toggleTheme(),
          // ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: UserAvatar(
              user: widget.user,
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          child: Column(
            children: [
              SearchBarCustom(
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
              TabBar(
                indicatorPadding: const EdgeInsets.all(10.0),
                indicatorSize: TabBarIndicatorSize.tab,
                controller: _tabController,
                indicator: const BoxDecoration(
                  image: DecorationImage(
                    alignment: Alignment.center,
                    opacity: 0.8,
                    scale: 0.5,
                    image: AssetImage('assets/images/tabmarker.png'),
                    fit: BoxFit.scaleDown,
                  ),
                ),
                labelColor: AppStyles.colorAvatarBorder,
                indicatorColor: AppStyles.colorAvatarBorder,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: Texts.translate('feedGeneralTab', globalLanguage)),
                  Tab(text: Texts.translate('FollowingTab', globalLanguage)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsList(_postsFutureGeneral!),
                    _buildPostsList(_postsFutureFollowing!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
