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
  List<PlatformFile> selectedFiles = [];
  bool isUploading = false;

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
        return Column(
          children: [
            InkWell(
              onTap: () => setState(() => isExpanded = !isExpanded),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.03,
                  vertical: 12,
                ),
                child: _buildPostContent(constraints),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1, thickness: 0.5),
              _buildReplySection(constraints),
            ],
            const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          ],
        );
      },
    );
  }

  Widget _buildPostContent(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAuthorAvatar(),
        SizedBox(width: constraints.maxWidth * 0.02),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderInfo(),
              const SizedBox(height: 4),
              _buildMainContent(),
              const SizedBox(height: 8),
              _buildPostFooter(constraints),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    return Row(
      children: [
        Text(
          widget.post.author,
          style: AppStyles().getTextStyle(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.post.module,
          style: AppStyles().getTextStyle(context).copyWith(
                color: Colors.grey,
                fontSize: 14,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          '·',
          style: AppStyles().getTextStyle(context).copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          UtilsSapers().formatTimestamp(widget.post.timestamp),
          style: AppStyles().getTextStyle(context).copyWith(
                color: Colors.grey,
                fontSize: 14,
              ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              constraints:
                  BoxConstraints(maxWidth: constraints.maxWidth * 0.95),
              child: Text(
                widget.post.content,
                style: AppStyles().getTextStyle(context).copyWith(
                      fontSize: 15,
                    ),
                maxLines: isExpanded ? null : 4,
                overflow: isExpanded ? null : TextOverflow.fade,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPostFooter(BoxConstraints constraints) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CommentButton(
          replyCount: widget.post.replyCount,
          // size: constraints.maxWidth * 0.04,
        ),
        const SizedBox(width: 16),
        SAPAttachmentsViewerHeader(
          reply: widget.post,
          onAttachmentOpen: (attachment) {
            if (attachment['url'] != null) {
              final Uri uri = Uri.parse(attachment['url']);
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    );
  }

  Widget _buildReplySection(BoxConstraints constraints) {
    return Container(
      width: constraints.maxWidth,
      padding: EdgeInsets.symmetric(
        horizontal: constraints.maxWidth * 0.03,
      ),
      child: Column(
        children: [
          _buildReplyInput(),
          _buildRepliesList(),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            seed: FirebaseAuth.instance.currentUser?.email ?? '',
            showBorder: true,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                TextEditorWithCode(textController: _replyController),
                const SizedBox(height: 8),
                _buildAttachmentUploadedReply(),
                const SizedBox(height: 8),
                _buildReplyActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.attach_file, size: 20),
          onPressed: () async {
            final files = await UtilsSapers().pickFiles(selectedFiles, context);
            if (files != null) {
              setState(() => selectedFiles = files);
            }
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
            onPressed: () => _handleReply(
              widget.post.id,
              UtilsSapers().getReplyId(context),
            ),
            width: 100,
            // height: 32,
            customColor: AppStyles().getButtonColor(context),
          ),
      ],
    );
  }

  Widget _buildRepliesList() {
    return StreamBuilder<List<SAPReply>>(
      stream: _firebaseService.getRepliesForPost(widget.post.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorMessage();
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final replies = snapshot.data!;
        if (replies.isEmpty) {
          return _buildEmptyRepliesMessage();
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 16),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: replies.length,
          separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
          itemBuilder: (_, index) => _buildReplyCard(replies[index]),
        );
      },
    );
  }

  Widget _buildReplyCard(SAPReply reply) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            seed: reply.author,
            showBorder: true,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.author,
                      style: AppStyles().getTextStyle(context).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      UtilsSapers().formatTimestamp(reply.timestamp),
                      style: AppStyles().getTextStyle(context).copyWith(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildCodeContent(reply.content),
                if (reply.attachments != null && reply.attachments!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: AttachmentsViewer(
                      reply: reply,
                      onAttachmentOpen: (attachment) {
                        if (attachment['url'] != null) {
                          final Uri uri = Uri.parse(attachment['url']);
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods remain the same
  Widget _buildAuthorAvatar() => UserProfileCardHover(
        post: widget.post,
        onProfileOpen: () {},
      );

  Widget _buildErrorMessage() => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            Texts.translate('passError', globalLanguage),
            style: AppStyles().getTextStyle(context),
          ),
        ),
      );

  Widget _buildEmptyRepliesMessage() => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            Texts.translate('serElPrimeroEnResponder', globalLanguage),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      );

  Widget _buildAttachmentUploadedReply() {
    if (selectedFiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '(${selectedFiles.length})',
          style: AppStyles().getTextStyle(context),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedFiles.map(_buildAttachmentChip).toList(),
        ),
      ],
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
          style: AppStyles().getTextStyle(context),
        ),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => setState(() => selectedFiles.remove(file)),
      ),
    );
  }

  Future<void> _handleReply(String postId, String replyId) async {
    if (_replyController.text.isEmpty && selectedFiles.isEmpty) return;

    if (AuthService().isUserLoggedIn(context)) {
      try {
        setState(() => isUploading = true);

        List<Map<String, dynamic>> attachmentsList = [];
        if (selectedFiles.isNotEmpty) {
          attachmentsList = await _firebaseService.addAttachments(
            postId,
            replyId,
            selectedFiles,
          );
        }

        await _firebaseService.createReply(
          widget.post.id,
          _replyController.text,
          widget.post.replyCount + 1,
          attachments: attachmentsList,
        );

        setState(() {
          isUploading = false;
          selectedFiles.clear();
        });
        _replyController.clear();

        if (mounted && _scrollController.hasClients) {
          await Future.delayed(const Duration(milliseconds: 100));
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
            content: Text(Texts.translate('passError', globalLanguage)),
          ),
        );
        setState(() {
          isUploading = false;
          selectedFiles.clear();
        });
      }
    }
  }

  Widget _buildCodeContent(String content) {
    if (content.isEmpty || !content.contains('```')) {
      return Text(
        content,
        style: AppStyles().getTextStyle(context).copyWith(fontSize: 15),
      );
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
            child: Text(
              part,
              style: AppStyles().getTextStyle(context).copyWith(fontSize: 15),
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (language.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    language.toUpperCase(),
                    style: AppStyles().getTextStyle(context),
                  ),
                ),
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: codeContent.trim()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          Texts.translate(
                              'copiarAlPortapapeles', globalLanguage),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip:
                      Texts.translate('copiarAlPortapapeles', globalLanguage),
                ),
              ],
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
