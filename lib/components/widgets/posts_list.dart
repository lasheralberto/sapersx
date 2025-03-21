import 'package:flutter/material.dart';
import 'package:sapers/components/widgets/postcard.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/styles.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:sapers/models/texts.dart';

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
  int tagSelected = -1;
  bool _closeTagSelected = false;

  String cleanText(String text) {
    return text
        .replaceAll('"', '') // Elimina comillas dobles
        .replaceAll("'", '') // Elimina comillas simples
        .replaceAll('"', '') // Elimina comillas tipográficas
        .replaceAll('"', '')
        .replaceAll('´', '') // Elimina acentos agudos
        .replaceAll('`', '')
        .replaceAll('`', '') // Elimina acentos graves
        .replaceAll('¨', '') // Elimina diéresis
        .replaceAll(',', '')
        .trim(); // Elimina espacios al inicio y final
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              selectionColor: AppStyles.colorAvatarBorder,
              Texts.translate(
                  'trendingTags', LanguageProvider().currentLanguage),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppStyles.colorAvatarBorder),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.trendingTags.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      tagSelected = index;
                      _closeTagSelected = false;
                    });
                    widget.onTagSelected(widget.trendingTags[index]);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              index == tagSelected
                                  ? _closeTagSelected == false
                                      ? IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              _closeTagSelected = true;
                                            });
                                            widget.onTagSelected('null');
                                          })
                                      : const SizedBox.shrink()
                                  : const SizedBox.shrink(),
                              Icon(
                                Icons.trending_up_rounded,
                                color: index < 2
                                    ? AppStyles.colorAvatarBorder
                                    : Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cleanText(widget.trendingTags[index])
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: (tagSelected == index &&
                                          _closeTagSelected == false)
                                      ? AppStyles.colorAvatarBorder
                                      : Colors.black,
                                  fontWeight: (tagSelected == index &&
                                          _closeTagSelected == false)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
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

// Clase para gestionar el estado del sidebar
class SidebarController extends ChangeNotifier {
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  void toggle() {
    _isOpen = !_isOpen;
    notifyListeners();
  }

  void close() {
    _isOpen = false;
    notifyListeners();
  }

  void open() {
    _isOpen = true;
    notifyListeners();
  }
}

// Modificación de tu widget de lista de posts para incluir el sidebar
class PostsListWithSidebar extends StatefulWidget {
  final Future<List<SAPPost>> future;
  final bool isMobile;
  final List<String> trendingTags;
  final Function(String) onTagSelected;
  final Function(bool) onPostExpanded;
  final Function onRefresh;
  final SidebarController sidebarController;

  const PostsListWithSidebar({
    super.key,
    required this.future,
    required this.isMobile,
    required this.trendingTags,
    required this.onTagSelected,
    required this.onPostExpanded,
    required this.onRefresh,
    required this.sidebarController,
  });

  @override
  _PostsListWithSidebarState createState() => _PostsListWithSidebarState();
}

class _PostsListWithSidebarState extends State<PostsListWithSidebar> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Aquí deberías implementar tu lógica de recarga
    
    widget.onRefresh;
   

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
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        child: Material(
          color: Colors.transparent,
          child: PostCard(
            key: ValueKey(post.id),
            onExpandChanged: (p0) => setState(() => widget.onPostExpanded(p0)),
            tagPressed: (tag) => widget.onTagSelected(tag.toString()),
            post: post,
          ),
        ),
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

            return LiquidPullToRefresh(
              backgroundColor: AppStyles.colorAvatarBorder,
              onRefresh: _handleRefresh,
              child: Row(
                children: [
                  // Lista principal (ajustada según si el sidebar está abierto)
                  Expanded(
                    flex: 10,
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
                            horizontal: widget.isMobile ? 4.0 : 16.0,
                            vertical: 0.0,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              addAutomaticKeepAlives: false,
                              (context, index) {
                                return _buildPostCard(
                                    posts[index], widget.isMobile);
                              },
                              childCount: posts.length,
                            ),
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

        // Botón para abrir/cerrar sidebar

        // Sidebar con animación
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
                  ? MediaQuery.of(context).size.width *
                      0.5 // 1/2 de pantalla en móvil
                  : MediaQuery.of(context).size.width *
                      0.33, // 1/3 de pantalla en escritorio
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
