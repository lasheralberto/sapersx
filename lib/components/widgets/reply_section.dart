import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlighting/flutter_highlighting.dart';
import 'package:flutter_highlighting/themes/github.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:sapers/components/widgets/attachmentsviewer.dart';
import 'package:sapers/components/widgets/custombutton.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/text_editor.dart';
import 'package:sapers/components/widgets/user_hover_card.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:url_launcher/url_launcher.dart';

class ReplySection extends StatefulWidget {
  final SAPPost post;
  final double maxWidth;
  final String postId;
  final int replyCount;
  final String replyId;

  final String postAuthor;
  final FirebaseService firebaseService;
  final String globalLanguage;

  const ReplySection({
    Key? key,
    required this.post,
    required this.maxWidth,
    required this.postId,
    required this.replyId,
    required this.replyCount,
    required this.postAuthor,
    required this.firebaseService,
    required this.globalLanguage,
  }) : super(key: key);

  @override
  State<ReplySection> createState() => _ReplySectionState();
}

class _ReplySectionState extends State<ReplySection> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseService _firebaseService = FirebaseService();
  List<PlatformFile> selectedFiles = [];
  bool isUploading = false;
  Image? _pastedImage;

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

  Future<void> _handleReply(String postId, String replyId) async {
    if (_replyController.text.isEmpty && selectedFiles.isEmpty) return;

    bool isLoguedIn = AuthService().isUserLoggedIn(context);

    if (isLoguedIn) {
      try {
        setState(() => isUploading = true);

        List<Map<String, dynamic>> attachmentsList = [];
        UserInfoPopUp? userInfo = await FirebaseService()
            .getUserInfoByEmail(FirebaseAuth.instance.currentUser!.email!);
        if (selectedFiles.isNotEmpty) {
          attachmentsList = await _firebaseService.addAttachments(
              postId, replyId, userInfo!.username, selectedFiles);
        }

        await _firebaseService.createReply(userInfo!.username, widget.postId,
            _replyController.text, widget.replyCount + 1,
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
          SnackBar(content: Text(Texts.translate('passError', globalLanguage))),
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
      decoration: BoxDecoration(
        color: _replyCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
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

  Widget _buildAuthorAvatar(reply) {
    return UserProfileCardHover(
      post: reply,
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
        side: BorderSide(color: _borderColor, width: 1),
        deleteIcon: Icon(Icons.close, size: 16, color: _accentOrange),
        onDeleted: () => setState(() => selectedFiles.remove(file)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _sectionBackground,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildReplyInput(widget.postId, widget.replyId),
          Divider(
            height: 30,
            thickness: 1,
            color: _borderColor.withOpacity(0.5),
            indent: 20,
            endIndent: 20,
          ),
          _buildRepliesList(),
        ],
      ),
    );
  }

  Widget _buildReplyInput(String postId, String replyId) {
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('No se encontró imagen en el portapapeles')),
                );
              }
              return null;
            },
          ),
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: _accentOrange.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextEditorWithCode(textController: _replyController),
                ),
                _buildAttachmentUploadedReply(),
                _buildReplyControls(postId, replyId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyControls(String postId, String replyId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: _accentOrange),
            onPressed: () async {
              await UtilsSapers()
                  .pickFiles(selectedFiles, context)
                  .then((value) {
                if (value != null) {
                  setState(() => selectedFiles = value);
                }
              });
            },
            tooltip: Texts.translate('addAttachment', globalLanguage),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _accentOrange.withOpacity(isUploading ? 0 : 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
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
                    onPressed: () => _handleReply(postId, replyId),
                    child: Text(
                      Texts.translate('responder', globalLanguage),
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
      stream: widget.firebaseService.getRepliesForPost(widget.postId),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return _buildErrorMessage(snapshot.error.toString());
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
    return Container(
      decoration: BoxDecoration(
        color: _replyCardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _accentOrange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
                _buildCodeContent(reply.content),
                if (reply.attachments != null &&
                    reply.attachments!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AttachmentsViewer(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyHeader(SAPReply reply) {
    return Row(
      children: [
        _buildAuthorAvatar(reply),
        // ProfileAvatar(
        //   seed: reply.author,
        //   showBorder: true,
        //   size: AppStyles.avatarSize - 10,
        // ),
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
    if (content.isEmpty || !content.contains('```')) {
      return Text(content,
          style:
              AppStyles().getTextStyle(context, fontSize: AppStyles.fontSize));
    }

    final parts = content.split('```');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.asMap().entries.map((entry) {
        final index = entry.key;
        final part = entry.value.trim();

        if (index % 2 == 0 && part.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(part,
                style: AppStyles()
                    .getTextStyle(context, fontSize: AppStyles.fontSize)),
          );
        } else if (index % 2 == 1) {
          return _buildCodeBlock(part);
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildCodeBlock(String code) {
    final codeLines = code.split('\n');
    final language = codeLines.isNotEmpty ? codeLines[0].trim() : '';
    final codeContent =
        language.isNotEmpty ? codeLines.sublist(1).join('\n') : code;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (language.isNotEmpty) _buildCodeHeader(language, codeContent),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              codeContent,
              languageId: 'abap',
              theme: githubTheme,
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
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
              style: TextStyle(
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
                    Texts.translate(
                        'copiarAlPortapapeles', widget.globalLanguage),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip:
                Texts.translate('copiarAlPortapapeles', widget.globalLanguage),
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
          Texts.translate('passError', widget.globalLanguage),
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
          Texts.translate('serElPrimeroEnResponder', widget.globalLanguage),
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
