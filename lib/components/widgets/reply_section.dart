import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlighting/flutter_highlighting.dart';
import 'package:flutter_highlighting/themes/github.dart';

// Add other languages as needed
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/components/widgets/attachments_carousel.dart';
import 'package:sapers/components/widgets/attachmentsviewer.dart';
import 'package:sapers/components/widgets/custombutton.dart';
import 'package:sapers/components/widgets/like_button.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/text_editor.dart';

import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/auth_service.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/utils_sapers.dart';
import 'package:url_launcher/url_launcher.dart';

class ReplySection extends StatefulWidget {
  final SAPPost post;
  final Function()? onClose;

  const ReplySection({
    Key? key,
    required this.post,
    this.onClose,
  }) : super(key: key);

  @override
  State<ReplySection> createState() => _ReplySectionState();
}

class _ReplySectionState extends State<ReplySection> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<PlatformFile> selectedFiles = [];
  bool isUploading = false;
  Image? _pastedImage;
  bool _authorInReply = false;
  int voteIncrement = 0;

  // Colores personalizados
  static const _sectionBackground = Color(0xFFF3F3F3);
  static const _replyCardColor = Color(0xFFFFF3E0);
  static const _accentOrange = Color(0xFFFF9800);
  static const _borderColor = Color(0xFFFFE0B2);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleReply() async {
    if (_replyController.text.isEmpty && selectedFiles.isEmpty) return;

    bool isLoguedIn = AuthService().isUserLoggedIn(context);

    if (isLoguedIn) {
      try {
        setState(() => isUploading = true);

        List<Map<String, dynamic>> attachmentsList = [];
        UserInfoPopUp? userInfo =
            Provider.of<AuthProviderSapers>(context, listen: false).userInfo;

        if (selectedFiles.isNotEmpty) {
          attachmentsList = await _firebaseService.addAttachments(
              widget.post.id, '', userInfo!.username, selectedFiles);
        }

        await _firebaseService.createReply(userInfo!.username, widget.post.id,
            _replyController.text, widget.post.replyCount + 1,
            attachments: attachmentsList);

        setState(() {
          isUploading = false;
          selectedFiles.clear();
        });
        _replyController.clear();

        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 100));
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(Texts.translate(
                  'passError', LanguageProvider().currentLanguage))),
        );
        setState(() {
          isUploading = false;
          selectedFiles.clear();
        });
      }
    }
  }

  Widget _buildAttachmentUploadedReply() {
    if (selectedFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Archivos adjuntos (${selectedFiles.length})',
              style: const TextStyle(
                color: _accentOrange,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedFiles.map(_buildAttachmentChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorAvatar(SAPReply reply) {
    return UserProfileCardHover(
      isExpert: widget.post.isExpert,
      authorUsername: reply.author,
      onProfileOpen: () {
        // Opcional: Añade aquí lógica adicional cuando se abre el perfil
      },
    );
  }

  Widget _buildAttachmentChip(PlatformFile file) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Chip(
        label: Text(
          file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 12,
          ),
        ),
        backgroundColor: Colors.white,
        side: const BorderSide(color: _borderColor, width: 1),
        deleteIcon: const Icon(Icons.close, size: 16, color: _accentOrange),
        onDeleted: () => setState(() => selectedFiles.remove(file)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildReplyInput(),
        Divider(
          height: 30,
          thickness: 1,
          color: _borderColor.withOpacity(0.5),
          indent: 20,
          endIndent: 20,
        ),
        _buildRepliesList(),
      ],
    );
  }

  Widget _buildReplyInput() {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Define la combinación Ctrl+V (o Command+V en Mac) para disparar PasteIntent
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
            const PasteIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyV):
            const PasteIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          PasteIntent: CallbackAction<PasteIntent>(
            onInvoke: (PasteIntent intent) async {
              // Lee la imagen del portapapeles usando Pasteboard.image
              final imageBytes = await Pasteboard.image;
              if (imageBytes != null) {
                // Crea un PlatformFile a partir de los bytes obtenidos
                final file = PlatformFile(
                  name: 'pasted_image.png',
                  size: imageBytes.length,
                  bytes: imageBytes,
                );
                // Actualiza el estado para agregar el archivo a la lista de adjuntos
                // Asegúrate de que 'selectedFiles' es accesible desde el State
                setState(() {
                  selectedFiles.add(file);
                });
              } else {
                // Muestra un mensaje si no hay imagen en el portapapeles
                await Pasteboard.text.then((value) {
                  _replyController.text = value.toString();
                });
                setState(() {});
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(
                //       content:
                //           Text('No se encontró imagen en el portapapeles')),
                // );
              }
              return null;
            },
          ),
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextEditorWithCode(
                  textController: _replyController,
                  globalLanguage: LanguageProvider().currentLanguage,
                  onFilesSelected: (files) {
                    setState(() => selectedFiles.addAll(files));
                  },
                ),
              ),
              _buildAttachmentUploadedReply(),
              _buildReplyControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: isUploading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: _handleReply,
                    child: Text(
                      Texts.translate(
                          'responder', LanguageProvider().currentLanguage),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesList() {
    return StreamBuilder<List<SAPReply>>(
      stream: FirebaseService().getRepliesForPost(widget.post.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorMessage(snapshot.error.toString());
        }
        if (!snapshot.hasData) return _buildLoadingIndicator();

        final replies = snapshot.data!;
        return replies.isEmpty
            ? _buildEmptyRepliesMessage()
            : _buildRepliesListView(replies);
      },
    );
  }

  Widget _buildRepliesListView(List<SAPReply> replies) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: replies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) => _buildReplyCard(replies[index]),
    );
  }

  Widget _buildReplyCard(SAPReply reply) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _replyCardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _borderColor, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReplyHeader(reply),
                    const SizedBox(height: 16),
                    _buildCodeContent(reply.content ?? ''),
                    if (reply.attachments != null &&
                        reply.attachments!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ReplyAttachmentsCarousel(
                        reply: reply,
                        onAttachmentOpen: (attachment) {
                          if (attachment['url'] != null) {
                            launchUrl(
                              Uri.parse(attachment['url']),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    LikeButton(
                      postId: widget.post.id,
                      replyId: reply.id,
                      initialLikeCount: reply.replyVotes,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyHeader(SAPReply reply) {
    return Row(
      children: [
        _buildAuthorAvatar(reply),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reply.author, style: AppStyles().getTextStyle(context)),
              Text(
                UtilsSapers().formatTimestamp(reply.timestamp),
                style: AppStyles().getTextStyle(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodeContent(String content) {
    // Safety check for null or empty content
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    debugPrint(content.toString());
    // Debug print to verify content

    // If no code block markers are found, return the content as regular text
    if (!content.contains('```')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          content,
          style:
              AppStyles().getTextStyle(context, fontSize: AppStyles.fontSize),
        ),
      );
    }

    try {
      // Process content with code blocks
      final List<Widget> contentWidgets = [];
      bool insideCodeBlock = false;
      String currentBlockContent = '';

      // Split content by lines for more precise handling
      final lines = content.split('\n');
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];

        // Check for code block delimiters
        if (line.trim().startsWith('```')) {
          if (insideCodeBlock) {
            // End of code block
            contentWidgets.add(_buildCodeBlock(currentBlockContent));
            currentBlockContent = '';
            insideCodeBlock = false;
          } else {
            // Start of code block
            // Add any text before this code block
            if (currentBlockContent.isNotEmpty) {
              contentWidgets.add(Text(
                currentBlockContent,
                style: AppStyles()
                    .getTextStyle(context, fontSize: AppStyles.fontSize),
              ));
              currentBlockContent = '';
            }

            // Extract language if specified
            String language = line.trim().substring(3).trim();
            currentBlockContent = language.isNotEmpty ? language + '\n' : '';
            insideCodeBlock = true;
          }
        } else {
          // Add to current block content
          currentBlockContent += line + '\n';
        }
      }

      // Add any remaining content
      if (currentBlockContent.isNotEmpty) {
        if (insideCodeBlock) {
          contentWidgets.add(_buildCodeBlock(currentBlockContent));
        } else {
          contentWidgets.add(Text(
            currentBlockContent,
            style:
                AppStyles().getTextStyle(context, fontSize: AppStyles.fontSize),
          ));
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: contentWidgets,
      );
    } catch (e, stackTrace) {
      // If parsing fails, display the original content with error indication
      debugPrint('Error parsing code blocks: $e\n$stackTrace');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error rendering code blocks',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style:
                AppStyles().getTextStyle(context, fontSize: AppStyles.fontSize),
          ),
        ],
      );
    }
  }

  Widget _buildCodeBlock(String content) {
    try {
      String language = 'text';
      String codeContent = content;
      final lines = content.split('\n');

      if (lines.isNotEmpty) {
        final firstLine = lines[0].trim();
        if (firstLine.isNotEmpty && !firstLine.contains(' ')) {
          final extractedLang = firstLine.toLowerCase();

          // Lista blanca de lenguajes soportados
          const supportedLanguages = {
            'dart', 'python', 'javascript',
            'abap' // Añade abap si creaste el parser
          };

          language = supportedLanguages.contains(extractedLang)
              ? extractedLang
              : 'text';

          codeContent = lines.sublist(1).join('\n');
        }
      }

      // Si es ABAP y no tenemos soporte, forzar texto plano

      return _buildPlainText(codeContent);

      // Resto del código...
    } catch (e) {
      return _buildPlainText(content);
    }
  }

  Widget _buildPlainText(String code) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildHighlightedCode(String code, String language) {
    try {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: HighlightView(
          code,
          // Try with the provided language first
          languageId: language,
          theme: githubTheme,
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
          'Error using language "$language", falling back to "text": $e');
      try {
        // If the first language fails, try with plain text
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: HighlightView(
            code,
            languageId: 'text',
            theme: githubTheme,
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        );
      } catch (finalError) {
        // If all highlighting attempts fail, show plain text
        debugPrint('Highlighting completely failed: $finalError');
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        );
      }
    }
  }

  Widget _buildSyntaxHighlighter(String code, String language) {
    try {
      return HighlightView(
        code,
        languageId: language,
        theme: githubTheme,
        padding: const EdgeInsets.all(16),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      );
    } catch (e) {
      // Fallback if language not supported
      return HighlightView(
        code,
        languageId: 'text',
        theme: githubTheme,
        padding: const EdgeInsets.all(16),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      );
    }
  }

  Widget _buildCodeHeader(String language, String code) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _accentOrange,
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
            ),
            child: Text(
              language.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code.trim()));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    Texts.translate('copiarAlPortapapeles',
                        LanguageProvider().currentLanguage),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: Texts.translate(
                'copiarAlPortapapeles', LanguageProvider().currentLanguage),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          Texts.translate('passError', LanguageProvider().currentLanguage),
          style: AppStyles().getTextStyle(context),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyRepliesMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          Texts.translate(
              'serElPrimeroEnResponder', LanguageProvider().currentLanguage),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// Define un Intent personalizado para el paste
class PasteIntent extends Intent {
  const PasteIntent();
}
