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
import 'package:sapers/components/widgets/reply_section.dart';
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
  final Function(bool) onExpandChanged; // Callback para devolver el valor

  const PostCard({
    super.key,
    required this.onExpandChanged,
    required this.post,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isExpanded = false;

  int counter = 0;

  @override
  void dispose() {
    super.dispose();
  }

// Dentro de _PostCardState en PostCard
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          color: AppStyles().getCardColor(context),
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPostHeader(constraints.maxWidth, widget.post.id),
              if (isExpanded) // Muestra replies solo cuando está expandido
                ReplySection(
                  post: widget.post,
                  maxWidth: constraints.maxWidth,
                  postId: widget.post.id,

                  replyId: '', // O usa widget.post.id si es necesario
                  postAuthor: widget.post.author,
                  replyCount: widget.post.replyCount,
                  firebaseService:
                      FirebaseService(), // Asegúrate de inyectar el servicio
                  globalLanguage: 'es', // O obtén el lenguaje del contexto
                ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostHeader(double maxWidth, String postId) {
    return InkWell(
      onTap: () {
        setState(() => isExpanded = !isExpanded);
        widget.onExpandChanged(isExpanded);
      },
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
                  _buildHeaderPostInfo(),
                  const SizedBox(height: 2),
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
                          if (attachment['url'] != null) {
                            launchUrl(
                              Uri.parse(attachment['url']),
                              mode: LaunchMode.externalApplication,
                            );
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

  Widget _buildHeaderPostInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 6),

            // Módulo dentro de una burbuja redondeada
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200], // Color de fondo de la burbuja
                borderRadius: BorderRadius.circular(8), // Bordes redondeados
              ),
              child: Text(
                widget.post.module,
                style: AppStyles().getTextStyle(context).copyWith(
                      fontSize: 12, // Tamaño más pequeño
                      fontWeight: FontWeight.bold, // Resaltado
                    ),
              ),
            ),

            const SizedBox(width: 10),
            Text(widget.post.title,
                style: AppStyles().getTextStyle(context,
                    fontSize: AppStyles.fontSizeMedium,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 5),
        Row(
          children: [
            SizedBox(width: 10),
            Text(widget.post.author,
                style: AppStyles().getTextStyle(context,
                    fontSize: AppStyles.fontSize, fontWeight: FontWeight.w100)),
            SizedBox(width: 10),
            _buildTimestamp(widget.post),
          ],
        ),
        Divider(
          thickness: 0.0,
        )
      ],
    );
  }

  Widget _buildPostContent() {
    return Text(
      widget.post.content,
      style: AppStyles().getTextStyle(context),
      maxLines: isExpanded ? null : 4,
      overflow: isExpanded ? TextOverflow.visible : TextOverflow.fade,
    );
  }

  Widget _buildTimestamp(post) {
    // Formatear la fecha y hora
    final formattedDate = UtilsSapers().formatTimestamp(post.timestamp);

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          formattedDate,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class ReplyBottomSheet extends StatefulWidget {
  final Function(String) onSubmitted;
  final String? hintText;

  const ReplyBottomSheet({
    super.key,
    required this.onSubmitted,
    this.hintText,
  });

  @override
  State<ReplyBottomSheet> createState() => _ReplyBottomSheetState();
}

class _ReplyBottomSheetState extends State<ReplyBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isNotEmpty) {
      widget.onSubmitted(text);
      _controller.clear();
      setState(() {
        _isComposing = false;
      });
      Navigator.pop(context); // Cierra el bottom sheet después de enviar
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: widget.hintText ?? 'Escribe tu respuesta...',
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.hintColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (text) {
                      setState(() {
                        _isComposing = text.trim().isNotEmpty;
                      });
                    },
                    onSubmitted: _handleSubmitted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed: _isComposing
                      ? () => _handleSubmitted(_controller.text)
                      : null,
                  icon: Icon(
                    Icons.send_rounded,
                    color: _isComposing
                        ? theme.colorScheme.primary
                        : theme.disabledColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
