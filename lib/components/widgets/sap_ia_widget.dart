import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/components/screens/people_screen.dart';
import 'package:sapers/components/screens/popup_create_post.dart';
import 'package:sapers/components/screens/project_dialog.dart';
import 'package:sapers/components/screens/project_screen.dart';
import 'package:sapers/components/widgets/postcard.dart';
import 'package:sapers/components/widgets/posts_list.dart';
import 'package:sapers/components/widgets/project_card.dart';
import 'package:sapers/components/widgets/project_list.dart';
import 'package:sapers/components/widgets/sap_ia_widget.dart';
import 'package:sapers/components/widgets/sapers_ai_icon.dart';
import 'package:sapers/components/widgets/searchbar.dart';
import 'package:sapers/components/widgets/user_avatar.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/sap_ai_assistant.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/theme.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/utils_sapers.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class SAPAIAssistantWidget extends StatefulWidget {
  final String username;
  final bool isPanelVisible;
  final Function(dynamic post)? onPostSelected;
  final FocusNode searchFocusNode;
  final VoidCallback? onPostCreated;
  final VoidCallback? onProjectCreated;

  const SAPAIAssistantWidget({
    super.key,
    required this.username,
    required this.isPanelVisible,
    this.onPostSelected,
    required this.searchFocusNode,
    this.onPostCreated,
    this.onProjectCreated,
  });

  @override
  _SAPAIAssistantWidgetState createState() => _SAPAIAssistantWidgetState();
}

class _SAPAIAssistantWidgetState extends State<SAPAIAssistantWidget> {
  final TextEditingController _queryController = TextEditingController();
  final SAPAIAssistantService _assistantService = SAPAIAssistantService();
  final FirebaseService _firebaseService = FirebaseService();
  String _fullResponse = '';
  double _animationProgress = 0.0;
  bool _isLoading = false;
  List<dynamic> _recommendedPosts = [];
  Timer? _animationTimer;
  bool _shouldNebulaMove = false;
  bool _isPanelOpen = false;
  final PanelController _panelController = PanelController();

  Future<void> _sendQuery() async {
    if (_queryController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _fullResponse = '';
      _animationProgress = 0.0;
      _recommendedPosts = [];
      _shouldNebulaMove = true;
    });

    try {
      final (response, posts) = await _assistantService.generateAIResponse(
          query: _queryController.text, username: widget.username);

      setState(() {
        _fullResponse = response;
        _recommendedPosts = posts;
        _shouldNebulaMove = false;
        _isLoading = false;
      });

      _startSweepAnimation();
    } catch (e) {
      setState(() {
        _fullResponse = 'Error al procesar la solicitud';
        _isLoading = false;
        _shouldNebulaMove = false;
      });
    }
  }

  void _startSweepAnimation() {
    const animationDuration = Duration(seconds: 1);
    const frameDuration = Duration(milliseconds: 16); // ~60 FPS
    final totalSteps =
        animationDuration.inMilliseconds ~/ frameDuration.inMilliseconds;
    var currentStep = 0;

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(frameDuration, (timer) {
      currentStep++;
      setState(() {
        _animationProgress = currentStep / totalSteps;
      });

      if (currentStep >= totalSteps) {
        timer.cancel();
        setState(() {
          _animationProgress = 1.0;
          _isLoading = false;
        });
      }
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
        if (widget.onPostCreated != null) {
          widget.onPostCreated!();
        }
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
        if (widget.onProjectCreated != null) {
          widget.onProjectCreated!();
        }
      }
    }
  }

  void _showCreateOptions() {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Symbols.post_add, weight: 1150.0),
                title: Text(
                  Texts.translate(
                      'crearPost', languageProvider.currentLanguage),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePostDialog();
                },
              ),
              ListTile(
                leading: const Icon(Symbols.add_task, weight: 1150.0),
                title: Text(
                  Texts.translate(
                      'nuevoProyecto', languageProvider.currentLanguage),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateProjectDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage =
        Provider.of<LanguageProvider>(context).currentLanguage;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: widget.isPanelVisible
          ? Container(
              key: const ValueKey('chat-visible'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.05),
                ),
              ),
              child: Column(
                children: [
                  // Search bar and add button row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withOpacity(0.08),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          focusNode: widget.searchFocusNode,
                                          controller: _queryController,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            hintText: Texts.translate(
                                                'askMe', currentLanguage),
                                            hintStyle: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.5),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.fromLTRB(
                                                    16, 14, 8, 14),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                          ),
                                          onSubmitted: (_) => _sendQuery(),
                                        ),
                                      ),
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: _isLoading
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 12),
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      AppStyles
                                                          .colorAvatarBorder
                                                          .withOpacity(0.8),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : IconButton(
                                                icon: Icon(
                                                  Symbols.send,
                                                  size: 16,
                                                  color: AppStyles
                                                      .colorAvatarBorder
                                                      .withOpacity(0.8),
                                                ),
                                                style: IconButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                ),
                                                onPressed: _sendQuery,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: AppStyles.colorAvatarBorder,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppStyles.colorAvatarBorder.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                        onPressed: _showCreateOptions,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Response and recommendations area
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: UtilsSapers().buildShimmerEffect(
                              3,
                              UtilsSapers().buildShimmerLine(),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  child: _buildAnimatedText(),
                                ),
                              ),
                              if (_recommendedPosts.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  Texts.translate(
                                      'recommendedPosts', currentLanguage),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 32,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _recommendedPosts.length,
                                    itemBuilder: (context, index) {
                                      final post = _recommendedPosts[index];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: InkWell(
                                          onTap: () =>
                                              PostPopup.show(context, post),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppStyles.colorAvatarBorder
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Symbols.article,
                                                  size: 14,
                                                  color: AppStyles
                                                      .colorAvatarBorder,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _getPostTitle(post),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppStyles
                                                        .colorAvatarBorder,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            )
          : Container(key: const ValueKey('chat-hidden')),
    );
  }

  Widget _buildAnimatedText() {
    final visibleLength = (_fullResponse.length * _animationProgress).round();
    final visibleText = _fullResponse.substring(0, visibleLength);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      child: SelectableText.rich(
        TextSpan(
          children: UtilsSapers.parsePostContent(visibleText),
        ),
        key: ValueKey(_animationProgress),
        style: TextStyle(
          fontSize: 12,
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  String _getPostTitle(dynamic post) {
    if (post is SAPPost) {
      return post.title;
    } else if (post is Map) {
      return post['title'] ?? 'Post relacionado';
    }
    return 'Post relacionado';
  }
}

// Clase PostPopup para mostrar detalles de posts
class PostPopup {
  static void show(BuildContext context, dynamic post) {
    final orangeAccent = Colors.orange.shade400;
    final lightOrange = Colors.orange.shade50;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y botón de cerrar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _getPostTitle(post),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.close, size: 24),
                    color: Colors.black54,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Divisor
              Divider(
                color: orangeAccent.withOpacity(0.2),
                thickness: 1,
                height: 1,
              ),

              const SizedBox(height: 16),

              // Contenido del post
              Expanded(
                child: SingleChildScrollView(
                  child: Text.rich(
                    TextSpan(
                      children: _parsePostContent(_getPostContent(post)),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Footer con autor
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: lightOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Symbols.person,
                        size: 16,
                        color: orangeAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getPostAuthor(post),
                        style: TextStyle(
                          color: orangeAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<TextSpan> _parsePostContent(String content) {
    final List<TextSpan> spans = [];
    final lines = content.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      if (line.startsWith('#')) {
        // Encabezado
        spans.add(TextSpan(
          text: '${line.replaceAll('#', '').trim()}\n',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ));
      } else if (line.startsWith('* ') || line.startsWith('- ')) {
        // Lista
        spans.add(TextSpan(
          text: '• ${line.substring(2).trim()}\n',
          style: const TextStyle(
            color: Colors.black87,
          ),
        ));
      } else if (line.contains('**')) {
        // Texto en negrita
        final parts = line.split('**');
        for (int i = 0; i < parts.length; i++) {
          spans.add(TextSpan(
            text: parts[i],
            style: TextStyle(
              fontWeight: i.isOdd ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ));
        }
        spans.add(const TextSpan(text: '\n'));
      } else if (line.contains('`')) {
        // Código
        spans.add(TextSpan(
          text: '${line.replaceAll('`', '').trim()}\n',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            backgroundColor: Colors.orange.withOpacity(0.1),
            color: Colors.orange.shade800,
          ),
        ));
      } else {
        // Texto normal
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(
            color: Colors.black87,
          ),
        ));
      }
    }

    return spans;
  }

  static String _getPostTitle(dynamic post) {
    if (post is SAPPost) {
      return post.title;
    } else if (post is Map) {
      return post['title'] ?? 'Post relacionado';
    }
    return 'Post relacionado';
  }

  static String _getPostContent(dynamic post) {
    if (post is SAPPost) {
      return post.content;
    } else if (post is Map) {
      return post['content'] ?? '';
    }
    return '';
  }

  static String _getPostAuthor(dynamic post) {
    if (post is SAPPost) {
      return post.author;
    } else if (post is Map) {
      return post['author'] ?? 'Autor desconocido';
    }
    return 'Autor desconocido';
  }
}
