import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/utils_sapers.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  String _selectedModule = 'FI';
  final bool _isQuestion = false;
  AppStyles styles = AppStyles();
  List<PlatformFile> selectedFiles = [];
  final List<String> _tags = [];
  String postId = '';
  String replyId = '';
  late SAPPost newPost;
  bool isLoadingPost = false;

  final List<String> _modules = Modules.modules;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Widget _buildAttachmentUploadedReply() {
    if (selectedFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      constraints: const BoxConstraints(maxWidth: 100),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFiles.remove(file);
                    });
                  },
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: _tags.map((tag) => _buildTagChip(tag)).toList(),
    );
  }

  Widget _buildTagChip(String tag) {
    return Chip(
      label: Text(tag),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () => _removeTag(tag),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _handleTagsInput(String value) {
    if (value.contains(' ')) {
      final newTag = value.trim().replaceAll(' ', '');
      if (newTag.isNotEmpty && !_tags.contains(newTag)) {
        setState(() {
          _tags.add(newTag);
          _tagsController.clear();
        });
      }
    }
  }

  Future<void> _createPost() async {
    setState(() {
      isLoadingPost = true;
    });

    final UserInfoPopUp? user =
        Provider.of<AuthProviderSapers>(context, listen: false).userInfo;

    setState(() {
      postId = UtilsSapers().generateSimpleUID();
      replyId = UtilsSapers().getReplyId(context);
    });

    if (selectedFiles.isNotEmpty) {
      var filesNewPost = await FirebaseService().addAttachments(
        postId,
        replyId,
        user!.username,
        selectedFiles,
      );

      setState(() {
        newPost = SAPPost(
            id: postId,
            lang: LanguageProvider().currentLanguage,
            title: _titleController.text,
            content: _descriptionController.text,
            author: user.username.toString(),
            timestamp: DateTime.now(),
            module: _selectedModule,
            isQuestion: _isQuestion,
            tags: _tags,
            isExpert: user.isExpert as bool,
            attachments: filesNewPost,
            replyCount: 0);
      });
    } else {
      setState(() {
        newPost = SAPPost(
            lang: LanguageProvider().currentLanguage,
            id: postId,
            title: _titleController.text,
            content: _descriptionController.text,
            author: user!.username.toString(),
            timestamp: DateTime.now(),
            module: _selectedModule,
            isExpert: user.isExpert as bool,
            isQuestion: _isQuestion,
            tags: _tags,
            replyCount: 0);
      });
    }

    setState(() {
      isLoadingPost = false;
    });

    Navigator.pop(context, newPost);
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Texts.translate('crearNuevoPost', LanguageProvider().currentLanguage),
          style: AppStyles().getTextStyle(
            context,
            fontSize: AppStyles.fontSizeMedium,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: isLoadingPost
                ? Center(child: AppStyles().progressIndicatorCreatePostButton())
                : FilledButton(
                    style: AppStyles().getButtonStyle(context),
                    onPressed: _createPost,
                    child: Text(Texts.translate(
                        'publicar', LanguageProvider().currentLanguage)),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 800, // Ancho máximo para tablets y desktop
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: styles.getInputDecoration(
                              Texts.translate(
                                  'titulo', LanguageProvider().currentLanguage),
                              null,
                              context,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            textAlign: TextAlign.start,
                            controller: _descriptionController,
                            decoration: styles.getInputDecoration(
                              Texts.translate('descripcion',
                                  LanguageProvider().currentLanguage),
                              null,
                              context,
                            ),
                            maxLines: (mediaQuery.height * 0.3 / 24).round(),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _tagsController,
                            decoration: styles.getInputDecoration(
                              '${Texts.translate('tags', LanguageProvider().currentLanguage)} (${Texts.translate('separarConEspacios', LanguageProvider().currentLanguage)})',
                              null,
                              context,
                            ),
                            onChanged: _handleTagsInput,
                          ),
                          const SizedBox(height: 8),
                          _buildTagChips(),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedModule,
                            decoration: styles.getInputDecoration(
                              Texts.translate('moduloSAP',
                                  LanguageProvider().currentLanguage),
                              null,
                              context,
                            ),
                            items: _modules.map((String module) {
                              return DropdownMenuItem<String>(
                                value: module,
                                child: Text(module),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedModule = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.attach_file),
                                onPressed: () async {
                                  var files =
                                      await UtilsSapers().pickFiles(context);
                                  if (files != null) {
                                    setState(() {
                                      selectedFiles = files;
                                    });
                                  }
                                },
                                tooltip: Texts.translate('addAttachment',
                                    LanguageProvider().currentLanguage),
                              ),
                              Expanded(child: _buildAttachmentUploadedReply()),
                            ],
                          ),
                          const SizedBox(
                              height:
                                  50), // Espacio adicional al final para mejor UX
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Botón flotante para dispositivos móviles
     
    );
  }
}
