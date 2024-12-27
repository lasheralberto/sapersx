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

  int _loadMoreMessages = 25;
  int _incrementLoad = 25;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _updateFutures();
  }

  void _updateFutures() {
    setState(() {
      _postsFutureGeneral = _selectedModule.isEmpty
          ? _firebaseService.getPostsFuture(_loadMoreMessages)
          : _firebaseService.getPostsByModuleFuture(_selectedModule);
      _postsFutureFollowing =
          _firebaseService.getPostsFollowingFuture(_loadMoreMessages);
    });
  }

  Future<void> _showRefresh() async {
    if (!_isRefreshing) {
      setState(() {
        _isRefreshing = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _performSearch() {
    final searchText = _searchController.text.trim();
    setState(() {
      _postsFutureGeneral = searchText.isEmpty
          ? _firebaseService.getPostsFuture(_loadMoreMessages)
          : _firebaseService.getPostsByKeyword(searchText);

      if (searchText.isEmpty) {
        _selectedModule = '';
      }
    });
  }

  // Función para cargar más mensajes
  void _loadMoreMessagesFunc() {
    setState(() {
      _loadMoreMessages += _incrementLoad;
      if (_tabController.index == 1) {
        debugPrint('Fetching ' + _loadMoreMessages.toString());
        _postsFutureGeneral =
            _firebaseService.getPostsFuture(_loadMoreMessages);
      } else if (_tabController.index == 2) {
        debugPrint('Fetching ' + _loadMoreMessages.toString());
        _postsFutureFollowing =
            _firebaseService.getPostsFollowingFuture(_loadMoreMessages);
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
        _updateFutures();
      }
    }
  }

  Widget _buildPostsList(Future<List<SAPPost>> future) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
                final isAtTop = scrollInfo.metrics.pixels <=
                    scrollInfo.metrics.minScrollExtent;
                final isAtBottom = scrollInfo.metrics.pixels ==
                    scrollInfo.metrics.maxScrollExtent;

                // Manejar el refresco
                if (!_isRefreshing && isAtTop && _hasScrolledDown) {
                  _showRefresh();
                }

                // Manejar el desplazamiento hacia abajo y cargar más mensajes
                if (scrollInfo.metrics.pixels >
                    scrollInfo.metrics.minScrollExtent) {
                  setState(() {
                    _hasScrolledDown = true;
                  });

                  if (isAtBottom) {
                    _loadMoreMessagesFunc();
                  }
                }

                return false;
              },
              child: CustomScrollView(
                slivers: [
                  if (_isRefreshing)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: InkWell(
                          onTap: _updateFutures,
                          child: const Center(
                            child: Icon(Icons.refresh, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth * 0.05,
                            vertical: 8.0,
                          ),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: 800, // Maximum width for large screens
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppStyles().getCardColor(context),
                              borderRadius: BorderRadius.circular(
                                  AppStyles.borderRadiusValue),
                            ),
                            child: PostCard(post: posts[index]),
                          ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: SafeArea(
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: LayoutBuilder(
                builder: (context, constraints) {
                  return Image.asset(
                    'assets/images/logo.png',
                    width: constraints.maxWidth * 0.1,
                    height: constraints.maxHeight * 0.1,
                    fit: BoxFit.contain,
                  );
                },
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: UserAvatar(user: widget.user),
                ),
              ],
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the optimal width for the content
            final contentWidth = constraints.maxWidth > 1200
                ? 800.0
                : constraints.maxWidth * 0.9;

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                    Theme(
                      data: Theme.of(context).copyWith(
                        tabBarTheme: TabBarTheme(
                          labelStyle: TextStyle(
                            fontSize: constraints.maxWidth < 600 ? 12 : 14,
                          ),
                        ),
                      ),
                      child: TabBar(
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
                          Tab(
                            text: Texts.translate(
                                'feedGeneralTab', globalLanguage),
                          ),
                          Tab(
                            text:
                                Texts.translate('FollowingTab', globalLanguage),
                          ),
                        ],
                      ),
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
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreatePostDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
