import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:sapers/components/widgets/attachmentsviewer.dart';
import 'package:sapers/components/widgets/attachmentsviewer_header.dart';
import 'package:sapers/components/widgets/commentButton.dart';
import 'package:sapers/components/widgets/custombutton.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/styles.dart';
import 'package:flutter_highlighting/flutter_highlighting.dart';
import 'package:flutter_highlighting/themes/github.dart';
import 'package:flutter_highlighting/themes/vs.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/components/widgets/text_editor.dart';
import 'package:sapers/components/widgets/profile_header.dart';
import 'package:url_launcher/url_launcher.dart';

class PostCard extends StatefulWidget {
  final SAPPost post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isExpanded = false;
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _replyFocusNode = FocusNode();
  final FirebaseService _firebaseService = FirebaseService();

  String _imageUrl = ''; // Para guardar la URL de la imagen pegada

  List<PlatformFile> selectedFiles = [];
  bool isUploading = false;
  int counter = 0;

  // Función para detectar imágenes en el portapapeles
  Future<void> _handlePaste() async {
    final ClipboardData? clipboardData = await Clipboard.getData('text/plain');

    if (clipboardData != null && clipboardData.text != null) {
      final text = clipboardData.text!;
      if (text.contains('data:image')) {
        // Si el portapapeles contiene una imagen en formato base64
        setState(() {
          _imageUrl = text; // Asignamos la URL base64 a la variable
        });
      }
    }
  }

  // Función para insertar imágenes en el texto del TextField
  void _insertImage() {
    if (_imageUrl.isNotEmpty) {
      _replyController.text = _replyController.text + ' $_imageUrl';
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          color: AppStyles().getCardColor(context),
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPostHeader(constraints.maxWidth, widget.post.id),
              if (isExpanded) ...[
                const Divider(height: 1),
                _buildReplySection(constraints.maxWidth, widget.post.id,
                    UtilsSapers().getReplyId()),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleReply(String postId, String replyId) async {
    if (_replyController.text.isEmpty && selectedFiles.isEmpty) return;

    bool isLoguedIn = AuthService().isUserLoggedIn(context);

    if (isLoguedIn) {
      try {
        setState(() {
          isUploading = true;
        });

        List<Map<String, dynamic>> attachmentsList = [];
        if (selectedFiles.isNotEmpty) {
          attachmentsList = await _firebaseService.addAttachments(
              postId, replyId, selectedFiles);
        }

        await _firebaseService.createReply(
            widget.post.id, _replyController.text, widget.post.replyCount + 1,
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
    if (selectedFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attachments (${selectedFiles.length})',
              style: AppStyles().getTextStyle(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedFiles
                .map((file) => _buildAttachmentChip(file))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentChip(PlatformFile file) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Chip(
        backgroundColor: Colors.white,
        label: Text(
          file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStyles().getButtontTextStyle(context),
        ),
        side: BorderSide.none,
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () {
          setState(() {
            selectedFiles.remove(file);
          });
        },
      ),
    );
  }

  // Update the reply input section
  Widget _buildReplyInput(String postId, String replyId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextEditorWithCode(textController: _replyController),
          const SizedBox(height: 12),
          _buildAttachmentUploadedReply(),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () async {
                    await UtilsSapers()
                        .pickFiles(selectedFiles, context)
                        .then((value) {
                      if (value != null) {
                        setState(() {
                          selectedFiles = value;
                        });
                      }
                    });
                  },
                  tooltip: Texts.translate('addAttachment', globalLanguage),
                ),
                const SizedBox(width: 8),
                if (isUploading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  CustomButton(
                    text: Texts.translate('responder', globalLanguage),
                    onPressed: () => _handleReply(postId, replyId),
                    width: 120,
                    customColor: AppStyles().getButtonColor(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostHeader(double maxWidth, String postId) {
    return InkWell(
      onTap: () => setState(() => isExpanded = !isExpanded),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAuthorAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorInfo(),
                  const SizedBox(height: 8),
                  _buildPostContent(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CommentButton(replyCount: widget.post.replyCount),
                      SAPAttachmentsViewerHeader(
                        reply: widget.post,
                        onAttachmentOpen: (attachment) {
                          // Manejar la apertura del archivo
                          if (attachment['url'] != null) {
                            final Uri uri = Uri.parse(attachment['url']);
                            launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorAvatar() {
    return UserProfileCardHover(
      post: widget.post,
      onProfileOpen: () {
        // Opcional: Añade aquí lógica adicional cuando se abre el perfil
      },
    );
  }

  Widget _buildAuthorInfo() {
    return Row(
      children: [
        Text(widget.post.author, style: AppStyles().getTextStyle(context)),
        const SizedBox(width: 8),
        Text(widget.post.module, style: AppStyles().getTextStyle(context)),
      ],
    );
  }

  Widget _buildPostContent() {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.post.content,
          style: AppStyles().getTextStyle(context),
          maxLines: isExpanded ? null : 4,
        ),
      ],
    );

    if (!isExpanded) {
      return ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.white, Colors.transparent],
            stops: [0.0, 0.8, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: content,
      );
    }

    return content;
  }

  Widget _buildReplySection(double maxWidth, postid, replyId) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildReplyInput(postid, replyId),
          _buildRepliesList(),
        ],
      ),
    );
  }

  Widget _buildRepliesList() {
    return StreamBuilder<List<SAPReply>>(
      stream: _firebaseService.getRepliesForPost(widget.post.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorMessage(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final replies = snapshot.data!;
        if (replies.isEmpty) {
          return _buildEmptyRepliesMessage();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(10),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: replies.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) => _buildReplyCard(replies[index]),
        );
      },
    );
  }

  Widget _buildErrorMessage(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          Texts.translate('passError', globalLanguage),
          style: AppStyles().getTextStyle(context),
        ),
      ),
    );
  }

  Widget _buildEmptyRepliesMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          Texts.translate('serElPrimeroEnResponder', globalLanguage),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyCard(SAPReply reply) {
    return Card(
      color: AppStyles().getCardColor(context),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReplyHeader(reply),
            const SizedBox(height: 12),
            _buildCodeContent(reply.content),
            if (reply.attachments != null && reply.attachments!.isNotEmpty) ...[
              const SizedBox(height: 12),
              AttachmentsViewer(
                reply: reply,
                onAttachmentOpen: (attachment) {
                  if (attachment['url'] != null) {
                    final Uri uri = Uri.parse(attachment['url']);
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyHeader(SAPReply reply) {
    return Row(
      children: [
        ProfileAvatar(
            seed: reply.author,
            showBorder: true,
            size: AppStyles.avatarSize - 10),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  reply
                      .author, // Changed from widget.post.author to reply.author
                  style: AppStyles().getTextStyle(context)),
              Text(_formatTimestamp(reply.timestamp),
                  style: AppStyles().getTextStyle(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodeContent(String content) {
    if (content.isEmpty || !content.contains('```')) {
      return Text(content, style: const TextStyle(fontSize: 15));
    }

    final parts = content.split('```');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: parts.asMap().entries.map((entry) {
        final index = entry.key;
        final part = entry.value.trim();

        if (index % 2 == 0 && part.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(part, style: const TextStyle(fontSize: 15)),
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
        color: Colors.white,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
            ),
            child: Text(
              language.toUpperCase(),
              style: AppStyles().getTextStyle(context),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code.trim()));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      Texts.translate('copiarAlPortapapeles', globalLanguage)),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: Texts.translate('copiarAlPortapapeles', globalLanguage),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return Texts.translate('now', globalLanguage);
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
