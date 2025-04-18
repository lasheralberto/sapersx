import 'package:flutter/material.dart';
import 'package:sapers/components/widgets/postcard.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/styles.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:sapers/models/texts.dart';

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
    print('Handling tag selection: $tag'); // Debug
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

          // Tag seleccionado (chip)
          if (selectedTag != null) // Solo mostrar si hay un tag seleccionado
            Padding(
              padding: const EdgeInsets.all(16),
              child: Chip(
                label: Text(
                  selectedTag!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: AppStyles.colorAvatarBorder,
                deleteIcon: const Icon(
                  Icons.close,
                  size: AppStyles.iconSizeSmall,
                  color: Colors.white,
                ),
                onDeleted: () => _handleTagSelection(selectedTag!),
              ),
            ),

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
                          ? AppStyles.colorAvatarBorder.withOpacity(0.1)
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
                                color: isSelected
                                    ? AppStyles.colorAvatarBorder
                                    : Colors.grey,
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
  bool _isFixed = false; // Nueva propiedad para mantener el sidebar fijo

  bool get isOpen => _isOpen;
  bool get isFixed => _isFixed;

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

  // Nuevo método para alternar el modo fijo
  void toggleFixed() {
    //  _isFixed = !_isFixed;
    // if (_isFixed) {
    _isOpen = true; // Si está fijo, asegurarse de que esté abierto
    //   }
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
    // TODO: implement initState
    super.initState();
    widget.sidebarController.addListener(() {
      if (!widget.sidebarController.isOpen) {
        setState(() {
          widget.sidebarController.open();
        });
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),

          // Perfil de usuario
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

          // Opciones del menú
          _buildMenuItem(0, Icons.home_rounded, 'Inicio'),
          _buildMenuItem(1, Icons.search, 'Explorar'),
          _buildMenuItem(2, Icons.notifications_outlined, 'Notificaciones'),
          _buildMenuItem(3, Icons.mail_outline, 'Mensajes'),
          _buildMenuItem(4, Icons.bookmark_border, 'Guardados'),

          const Spacer(),

          // Botón para fijar el sidebar (pin)
          if (!widget.isMobile) // Solo en pantallas grandes
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  widget.sidebarController.toggleFixed();
                },
                child: Row(
                  children: [
                    Icon(
                      widget.sidebarController.isFixed
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      color: widget.sidebarController.isFixed
                          ? AppStyles.colorAvatarBorder
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.sidebarController.isFixed
                          ? 'Fijar menú'
                          : 'Desfijar menú',
                      style: TextStyle(
                        color: widget.sidebarController.isFixed
                            ? AppStyles.colorAvatarBorder
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Configuración en la parte inferior
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
      onTap: () {
        setState(() {
          _selectedOption = index;
        });
        widget.onMenuOptionSelected(index);
        if (widget.isMobile && !widget.sidebarController.isFixed) {
          widget.sidebarController.close();
        }
      },
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
  final Function(String) onTagSelected;
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
