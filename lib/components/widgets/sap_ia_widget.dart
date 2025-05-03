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
import 'package:sapers/models/askassistant.dart';
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
  Timer? _debounceTimer;
  bool _shouldNebulaMove = false;
  bool _isPanelOpen = false;
  final PanelController _panelController = PanelController();
  final assistantService = AskAssistantService(
      baseUrl: 'https://sapersx-568424820796.us-west1.run.app');

  Future<void> _sendQuery() async {
    if (_queryController.text.trim().isEmpty) return;

    // Cancel any previous debounce timer
    _debounceTimer?.cancel();

    // Simple loading state
    setState(() => _isLoading = true);

    try {
      final result = await assistantService.askQuestion(_queryController.text);

      if (mounted) {
        setState(() {
          _fullResponse = result.responseChat;
          _isLoading = false;
        });
        _startSweepAnimation();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullResponse = 'Error al procesar la solicitud';
          _isLoading = false;
        });
      }
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

 
  @override
  void dispose() {
    _animationTimer?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  String _getPostTitle(dynamic post) {
    if (post is SAPPost) {
      return post.title ?? 'Sin título';
    } else if (post is Map) {
      return post['title'] ?? 'Sin título';
    }
    return 'Sin título';
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
                  // Search bar and add button - Always visible
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
                                      // // IconButton(
                                      // //   icon: const Icon(
                                      // //     Icons.add,
                                      // //     color: AppStyles.colorAvatarBorder,
                                      // //     size: 20,
                                      // //   ),
                                      // //   style: IconButton.styleFrom(
                                      // //     backgroundColor: AppStyles
                                      // //         .colorAvatarBorder
                                      // //         .withOpacity(0.1),
                                      // //     padding: const EdgeInsets.all(8),
                                      // //   ),
                                      // //   onPressed: _showCreateOptions,
                                      // // ),
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
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Response area - Only visible when there's content
                  if (_isLoading || _fullResponse.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: UtilsSapers().buildShimmerEffect(
                                6,
                                UtilsSapers().buildShimmerLine(),
                              ),
                            )
                          : _buildResponseArea(currentLanguage),
                    ),
                  ],
                ],
              ),
            )
          : Container(key: const ValueKey('chat-hidden')),
    );
  }

  Widget _buildResponseArea(String currentLanguage) {
    return Column(
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
            Texts.translate('recommendedPosts', currentLanguage),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => PostPopup.show(context, post),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyles.colorAvatarBorder.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Symbols.article,
                            size: 14,
                            color: AppStyles.colorAvatarBorder,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getPostTitle(post),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppStyles.colorAvatarBorder,
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
    );
  }

  Widget _buildAnimatedText() {
    final visibleLength = (_fullResponse.length * _animationProgress).round();
    final visibleText = _fullResponse.substring(0, visibleLength);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: SelectableText.rich(
          TextSpan(
            children: _parseFormattedText(visibleText),
          ),
          key: ValueKey(_animationProgress),
          style: TextStyle(
            fontSize: 13,
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  List<TextSpan> _parseFormattedText(String text) {
    List<TextSpan> spans = [];
    final paragraphs = text.split('\n\n');

    for (var paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;

      // Manejo de títulos numerados con viñetas
      if (RegExp(r'^\d+\.\s+\*\*.*\*\*').hasMatch(paragraph)) {
        var parts = paragraph.split('**');
        spans.add(TextSpan(
          text: '${String.fromCharCode(0x2022)} ${parts[0]}', // Bullet point
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            height: 2.0,
          ),
        ));
        if (parts.length > 2) {
          spans.add(TextSpan(
            text: parts[2],
            style: const TextStyle(fontSize: 15),
          ));
        }
        spans.add(const TextSpan(text: '\n\n'));
        continue;
      }

      // Manejo de bullets
      if (paragraph.contains('•') || paragraph.contains('###')) {
        var lines = paragraph.split('\n');
        for (var line in lines) {
          var cleanLine = line.replaceAll('###', '').trim();
          if (line.trim().startsWith('•') || line.trim().startsWith('###')) {
            spans.add(TextSpan(
              text: '${String.fromCharCode(0x2022)} ', // Bullet point
              style: const TextStyle(
                height: 1.8,
                fontSize: 15,
              ),
            ));
            spans.add(TextSpan(
              text: '${cleanLine.replaceAll('•', '').trim()}\n',
              style: const TextStyle(height: 1.8),
            ));
          }
        }
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Manejo de texto en negrita dentro de párrafos normales
      if (paragraph.contains('**')) {
        var parts = paragraph.split('**');
        for (var i = 0; i < parts.length; i++) {
          spans.add(TextSpan(
            text: parts[i],
            style: TextStyle(
              fontWeight: i % 2 == 1 ? FontWeight.bold : FontWeight.normal,
              height: 1.8,
            ),
          ));
        }
      } else {
        // Párrafo normal
        spans.add(TextSpan(
          text: '$paragraph\n\n',
          style: const TextStyle(height: 1.8),
        ));
      }
    }

    return spans;
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
