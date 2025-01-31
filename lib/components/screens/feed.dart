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
      color: Color(0x22000000),
      blurRadius: 5,
      spreadRadius: 1,
      offset: Offset(1, 8),
    ),
    BoxShadow(
      color: Color(0x44FFFFFF),
      blurRadius: 5,
      spreadRadius: 1,
      offset: Offset(-1, -8),
    ),
  ];

  static const _mesoBorder = BorderSide(
    color: Color(0x44FFFFFF),
    width: 2,
  );

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

  Widget _buildPostsList(Future<List<SAPPost>> future) {
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
            slivers: [
              if (_isRefreshing)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: _mesoShadow,
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/images/logo.png',
          width: 100.0,
          height: 100.0,
        ),
        actions: [
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
              BoxConstraints(maxWidth: AppStyles().getFeedWith(context)),
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
