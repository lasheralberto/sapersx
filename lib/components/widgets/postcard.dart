import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/widgets/attachments_carousel.dart';
import 'package:sapers/components/widgets/attachmentsviewer_header.dart';
import 'package:sapers/components/widgets/commentButton.dart';
import 'package:sapers/components/widgets/reply_section.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/auth_service.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/lifecycle_mixin.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/utils_sapers.dart';
import 'package:sapers/models/vote.dart';
import 'package:url_launcher/url_launcher.dart';

class PostCard extends StatefulWidget {
  final SAPPost post;
  final Function(bool) onExpandChanged; // Callback para devolver el valor
  final Function(String?) tagPressed;
  final String? selectedTag; // Add this line

  const PostCard({
    super.key,
    required this.onExpandChanged,
    required this.tagPressed,
    required this.post,
    this.selectedTag, // Add this line
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isExpanded = false;
  bool _showComments = false;

  void _expandPost() {
    setState(() {
      _isExpanded = true;
      _showComments = true;
      widget.onExpandChanged(true);
    });
  }

  Widget _buildTag(String tag, BuildContext context) {
    final bool isSelected = tag ==
        widget.post.tags.firstWhere(
          (t) => t == widget.selectedTag,
          orElse: () => '',
        );

    return InkWell(
      onTap: () {
        if (isSelected) {
          widget.tagPressed(null);
        } else {
          widget.tagPressed(tag);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Chip(
          avatar: isSelected
              ? const Icon(Icons.close, size: 16, color: Colors.deepOrange)
              : null,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected ? Colors.deepOrange : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ],
          ),
          backgroundColor: isSelected
              ? Colors.deepOrange.withOpacity(0.1)
              : Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
            side: BorderSide(
              color: isSelected
                  ? Colors.deepOrange.withOpacity(0.5)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.9),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.post.isExpert
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildPostHeader(context),
          _buildPostContent(context),
          const Divider(),
          // Bottom section with comments and votes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CommentButton(
                  replyCount: widget.post.replyCount,
                  iconSize: 15,
                  iconColor: AppStyles.colorAvatarBorder,
                  onPressed: _expandPost, // Add this line
                ),
                const SizedBox(width: 16),
                _buildVoteButtons(context),
              ],
            ),
          ),
          if (_showComments)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ReplySection(
                post: widget.post,
                onClose: () => setState(() => _showComments = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) {
    return InkWell(
      onTap: () => widget.onExpandChanged(true),
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
                  _buildHeaderPostInfo(context),
                  const SizedBox(height: 8),
                  // Moved attachments viewer to top right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
      isExpert: widget.post.isExpert,
      authorUsername: widget.post.author,
      onProfileOpen: () {
        // Opcional: Añade aquí lógica adicional cuando se abre el perfil
      },
    );
  }

  Widget _buildHeaderPostInfo(context) {
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
              child: Text(widget.post.module,
                  style: AppStyles().getTextStyle(context)),
            ),

            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.post.title,
                style: AppStyles().getTextStyle(context,
                    fontSize: AppStyles.fontSizeMedium,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow
                    .ellipsis, // Muestra "..." si el texto es muy largo
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(widget.post.author,
                  style: AppStyles().getTextStyle(context,
                      fontSize: AppStyles.fontSize,
                      fontWeight: FontWeight.w100)),
            ),
            const SizedBox(width: 10),
            _buildTimestamp(widget.post),
          ],
        ),
      ],
    );
  }

  Widget _buildPostContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content section with different background
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  widget.post.content,
                  style: AppStyles().getTextStyle(context),
                  maxLines: _isExpanded ? null : 4,
                ),
              ),
              if (!_isExpanded)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _expandPost, // Change this line
                    child: Text(
                      Texts.translate(
                          'verMas', LanguageProvider().currentLanguage),
                      style: TextStyle(
                        color: AppStyles.colorAvatarBorder,
                        fontSize: AppStyles.fontSize,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Attachments and tags section
        Container(
          color: Colors.grey.withOpacity(0.05),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AttachmentsCarousel(
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
              if (widget.post.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.post.tags
                        .map((tag) => _buildTag(tag, context))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
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

  Widget _buildVoteButtons(BuildContext context) {
    final user = Provider.of<AuthProviderSapers>(context).userInfo;

    return StreamBuilder<Map<String, dynamic>>(
      stream: FirebaseService().getPostVotesStream(widget.post.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(width: 80, child: Center(child: Text('...')));
        }

        final votes = snapshot.data!;
        final upvoters = List<String>.from(votes['upvoters'] ?? []);
        final downvoters = List<String>.from(votes['downvoters'] ?? []);

        VoteType currentVote = VoteType.none;
        if (user != null) {
          if (upvoters.contains(user.username)) {
            currentVote = VoteType.up;
          } else if (downvoters.contains(user.username)) {
            currentVote = VoteType.down;
          }
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                iconSize: 15,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.arrow_upward,
                  color:
                      currentVote == VoteType.up ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  bool isUserLoggedIn = AuthService().isUserLoggedIn(context);
                  if (!isUserLoggedIn) return;

                  FirebaseService().handleVote(
                    widget.post.id,
                    user?.username ?? '',
                    currentVote == VoteType.up ? VoteType.none : VoteType.up,
                  );
                }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '${(votes['upvotes'] ?? 0) - (votes['downvotes'] ?? 0)}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            IconButton(
                iconSize: 15,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.arrow_downward,
                  color:
                      currentVote == VoteType.down ? Colors.red : Colors.grey,
                ),
                onPressed: () {
                  bool isUserLoggedIn = AuthService().isUserLoggedIn(context);
                  if (!isUserLoggedIn) return;

                  FirebaseService().handleVote(
                    widget.post.id,
                    user?.username ?? '',
                    currentVote == VoteType.down
                        ? VoteType.none
                        : VoteType.down,
                  );
                }),
          ],
        );
      },
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

    return SafeArea(
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
              child: TextField(
                controller: _controller,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: widget.hintText ??
                      Texts.translate('escribeRespuesta',
                          LanguageProvider().currentLanguage),
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
    );
  }
}
