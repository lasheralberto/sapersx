import 'package:file_picker/file_picker.dart';
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
import 'package:seo_renderer/seo_renderer.dart';

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
  int? _selectedPostIndex;
  List<PlatformFile> selectedFiles = [];

  late TabController _tabController;
  String _selectedModule = '';
  Future<List<SAPPost>>? _postsFutureGeneral;
  Future<List<SAPPost>>? _postsFutureFollowing;
  bool _isRefreshing = false;
  bool isPostExpanded = false;

  // Estilo Mesomórfico para el feed
  static const _mesoShadow = [
    BoxShadow(
      color: Color.fromARGB(33, 208, 116, 116),
      blurRadius: 10,
      spreadRadius: 1,
      offset: Offset(1, 1),
    ),
    BoxShadow(
      color: Color(0x44FFFFFF),
      blurRadius: 10,
      spreadRadius: 1,
      offset: Offset(-1, -1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

    setState(() {
      _postsFutureGeneral = generalPosts;
      _postsFutureFollowing = followingPosts;
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
                          borderRadius:
                              BorderRadius.circular(isMobile ? 12 : 20),
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
                          borderRadius:
                              BorderRadius.circular(isMobile ? 12 : 20),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: ImageRenderer(
          alt: 'Logo Image',
          child: Image.asset(
            AppStyles.logoImage,
            width: isMobile ? 80.0 : 100.0,
            height: isMobile ? 80.0 : 100.0,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 8.0 : 16.0),
            child: UserAvatar(
              user: widget.user,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8.0 : 16.0,
                  vertical: 8.0,
                ),
                child: Center(
                  child: SizedBox(
                    width: constraints.maxWidth >= 600
                        ? constraints.maxWidth / 2
                        : constraints.maxWidth * 0.9,
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
              TabBar(
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
                indicatorColor: AppStyles.colorAvatarBorder,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: TextRenderer(
                      style: TextRendererStyle.header1,
                      child: Text(
                        Texts.translate('feedGeneralTab', globalLanguage),
                        style: const TextStyle(
                          fontSize: AppStyles.fontSize,
                        ),
                      ),
                    ),
                  ),
                  Tab(
                    child: TextRenderer(
                      style: TextRendererStyle.header1,
                      child: Text(
                        Texts.translate('FollowingTab', globalLanguage),
                        style: const TextStyle(
                          fontSize: AppStyles.fontSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsList(_postsFutureGeneral!, isMobile),
                    _buildPostsList(_postsFutureFollowing!, isMobile),
                  ],
                ),
              ),
            ],
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
