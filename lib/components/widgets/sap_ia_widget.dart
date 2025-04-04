import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/widgets/sapers_ai_icon.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/sap_ai_assistant.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/utils_sapers.dart';

class SAPAIAssistantWidget extends StatefulWidget {
  final String username;
  final bool isPanelVisible;
  final Function(dynamic post)? onPostSelected;
  final FocusNode searchFocusNode;

  const SAPAIAssistantWidget({
    super.key,
    required this.username,
    required this.isPanelVisible,
    this.onPostSelected,
    required this.searchFocusNode
  });

  @override
  _SAPAIAssistantWidgetState createState() => _SAPAIAssistantWidgetState();
}

class _SAPAIAssistantWidgetState extends State<SAPAIAssistantWidget> {
  final TextEditingController _queryController = TextEditingController();
  final SAPAIAssistantService _assistantService = SAPAIAssistantService();
  String _fullResponse = '';
  double _animationProgress = 0.0;
  bool _isLoading = false;
  List<dynamic> _recommendedPosts = [];
  Timer? _animationTimer;
  bool _shouldNebulaMove = false;

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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    spacing: 10.0,
                    children: [
                      NebulaEffect(
                        shouldMove: _shouldNebulaMove,
                      ),
                      Expanded(
                        child: TextField(
                          focusNode: widget.searchFocusNode,
                          controller: _queryController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor:
                                Theme.of(context).colorScheme.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            hintText: Texts.translate('askMe', currentLanguage),
                            hintStyle: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 14,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Symbols.send, size: 20),
                              onPressed: _sendQuery,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendQuery(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? UtilsSapers().buildShimmerEffect(10)
                      : Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  child: _buildAnimatedText(),
                                ),
                              ),
                              if (_recommendedPosts.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  Texts.translate(
                                      'recommendedPosts', currentLanguage),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 40,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _recommendedPosts.length,
                                    itemBuilder: (context, index) {
                                      final post = _recommendedPosts[index];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: ActionChip(
                                          avatar:
                                              Icon(Symbols.article, size: 16),
                                          label: Text(
                                            _getPostTitle(post),
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                          onPressed: () =>
                                              PostPopup.show(context, post),
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

// Añade esta clase como parte de tu _SAPAIAssistantWidgetState
class PostPopup {
  static void show(BuildContext context, dynamic post) {
    final theme = Theme.of(context);
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
