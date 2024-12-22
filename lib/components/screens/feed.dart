import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
import 'package:easy_sidemenu/easy_sidemenu.dart';

class Feed extends StatefulWidget {
  const Feed({super.key});

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedModule = '';
  final FirebaseService _firebaseService = FirebaseService();
  final AppStyles _styles = AppStyles();
  final List<String> _modules = Modules.modules;
  Stream<List<SAPPost>>? _postsStream;
  bool? isLoadingPost = false;

  final String _imageUrl = ''; // Para guardar la URL de la imagen pegada

  // Controlador para el cambio de páginas
  int _selectedIndex = 0;

  // Lista de pantallas para navegar

  // Método para cambiar la pantalla
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    _postsStream = _firebaseService.getPosts();
  }

  void _performSearch() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _postsStream = _firebaseService.getPosts();
      });
    } else {
      setState(() {
        _postsStream = _firebaseService.searchPosts(_searchController.text);
      });
    }
  }

  void _handleModuleSelected(String module) {
    setState(() {
      _selectedModule = module;
      _postsStream = module.isEmpty
          ? _firebaseService.getPosts()
          : _firebaseService.getPostsByModule(_selectedModule);

      print('Módulo seleccionado: $module');
    });
  }

  void _showCreatePostDialog() async {
    if (FirebaseAuth.instance.currentUser == null) {
      showDialog(
        context: context,
        builder: (context) => const LoginDialog(),
      );
    } else {
      setState(() {
        isLoadingPost = true;
      });
      final result = await showDialog<SAPPost>(
        context: context,
        builder: (context) => const CreatePostDialog(),
      );

      if (result != null) {
        await _firebaseService.createPost(result);
        setState(() {
          isLoadingPost = false;
        });
      } else {
        //mostrar popups de error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear el post'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var mediaquery = MediaQuery.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // title: Center(
        //   child: Image.asset(
        //     'assets/images/logo-trans.png',
        //     height: 45,
        //   ),
        // ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                themeNotifier.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: 20,
              ),
              onPressed: () => themeNotifier.toggleTheme(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: UserAvatar(),
          ),
        ],
      ),
      body: StreamBuilder<List<SAPPost>>(
        stream: _postsStream,
        initialData: const [], // Proporciona una lista vacía como valor inicial
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Muestra un mensaje de error si ocurre algún problema en el stream
            return Center(
              child: SelectableText('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            // Muestra un indicador de carga mientras el stream está esperando datos
            return const Center(child: CircularProgressIndicator());
          }

          // Verifica si los datos están disponibles
          final posts = snapshot.data ?? [];

          if (posts.isEmpty &&
              _searchController.text.isEmpty &&
              _selectedModule.isEmpty) {
            // Muestra un mensaje si no hay publicaciones y no hay criterios de búsqueda
            return Center(
              child: Text(
                Texts.translate('noPostsDisponibles', globalLanguage),
              ),
            );
          }

          // Construye la interfaz principal si hay datos
          return Center(
            child: SizedBox(
              width: AppStyles().getScreenWidth(context),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SearchBarCustom(
                      controller: _searchController,
                      onSearch: _performSearch,
                      onModuleSelected: _handleModuleSelected,
                      modules: _modules,
                      selectedModule: _selectedModule,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => PostCard(post: posts[index]),
                        childCount: posts.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
