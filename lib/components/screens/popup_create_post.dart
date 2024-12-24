import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/posts.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({super.key});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedModule = 'FI';
  final bool _isQuestion = false;
  AppStyles styles = AppStyles();
  List<PlatformFile> selectedFiles = [];
  String postId = '';
  String replyId = '';
  late SAPPost newPost;
  bool? isLoadingPost = false;

  final List<String> _modules = Modules.modules;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
          onTap: () {}, // Opcional: manejar tap en el archivo
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

  @override
  Widget build(BuildContext context) {
    var mediaquery = MediaQuery.of(context).size;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
            maxWidth: mediaquery.width / 1.5, maxHeight: mediaquery.height),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    // Añadido Flexible
                    child: Text(
                        Texts.translate('crearNuevoPost', globalLanguage),
                        style: AppStyles().getTextStyle(context)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _titleController,
                  decoration: styles.getInputDecoration(
                      Texts.translate('titulo', globalLanguage),
                      null,
                      context)),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: styles.getInputDecoration(
                    Texts.translate('descripcion', globalLanguage),
                    null,
                    context),
                maxLines: (mediaquery.height * 0.4 / 24).round(),
              ),
              const SizedBox(height: 16),
              // Modificado el dropdown para ser responsivo
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: mediaquery.width / 4,
                  minWidth:
                      10, // Ancho mínimo para evitar que sea demasiado pequeño
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedModule,
                  decoration: styles.getInputDecoration(
                      Texts.translate('moduloSAP', globalLanguage),
                      null,
                      context),
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
              ),
              const SizedBox(height: 16),
              // Botones envueltos en Wrap para que se ajusten automáticamente
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8, // Espacio horizontal entre botones
                runSpacing:
                    8, // Espacio vertical cuando los botones saltan de línea
                children: [
                  TextButton(
                    style: AppStyles().getButtonStyle(context),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      Texts.translate('cancelar', globalLanguage),
                      style: AppStyles().getButtontTextStyle(context),
                    ),
                  ),
                  FilledButton(
                    style: AppStyles().getButtonStyle(context),
                    onPressed: () async {
                      setState(() {
                        isLoadingPost = true;
                      });
                      final UserInfoPopUp? user = await FirebaseService()
                          .getUserInfoByEmail(FirebaseAuth
                              .instance.currentUser!.email
                              .toString());

                      setState(() {
                        postId = DateTime.now().toString();
                        replyId = UtilsSapers().getReplyId(context);
                      });

                      if (selectedFiles.isNotEmpty) {
                        var filesNewPost =
                            await FirebaseService().addAttachments(
                          postId,
                          replyId,
                          selectedFiles,
                        );

                        setState(() {
                          newPost = SAPPost(
                              id: postId,
                              title: _titleController.text,
                              content: _descriptionController.text,
                              author: user!.username.toString(),
                              timestamp: DateTime.now(),
                              module: _selectedModule,
                              isQuestion: _isQuestion,
                              tags: [],
                              attachments: filesNewPost,
                              replyCount: 0);
                        });
                      } else {
                        setState(() {
                          newPost = SAPPost(
                              id: postId,
                              title: _titleController.text,
                              content: _descriptionController.text,
                              author: user!.username.toString(),
                              timestamp: DateTime.now(),
                              module: _selectedModule,
                              isQuestion: _isQuestion,
                              tags: [],
                              replyCount: 0);
                        });
                      }

                      setState(() {
                        isLoadingPost = false;
                      });
                      Navigator.pop(context, newPost);
                    },
                    child: isLoadingPost == true
                        ? AppStyles().progressIndicatorButton()
                        : Text(Texts.translate('publicar', globalLanguage)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () async {
                      var files =
                          await UtilsSapers().pickFiles(selectedFiles, context);
                      setState(() {
                        selectedFiles = files;
                      });
                    },
                    tooltip: Texts.translate('addAttachment', globalLanguage),
                  ),
                  _buildAttachmentUploadedReply()
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
