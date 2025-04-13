import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/screens/feed.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/snackbar.dart';
import 'package:sapers/components/widgets/stacked_avatars.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool isOwner = false;
  bool isMember = false;
  UserInfoPopUp? currentUser;
  bool? isLoading = true;
  bool _isUploading = false;
  late TabController _tabController;
  final LanguageProvider _languageProvider = LanguageProvider();
  late Future<List<PlatformFile>?> _selectedFilesChat;

  @override
  void initState() {
    super.initState();
    isLoading = true;

    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      setState(() {});
    });
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    await _loadCurrentUser();

    if (mounted) {
      await _checkProjectPermissions();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null || firebaseUser.email == null) {
        setState(() => currentUser = null);
        return;
      }

      final user =
          Provider.of<AuthProviderSapers>(context, listen: false).userInfo;
      setState(() => currentUser = user);
    } catch (e) {
      setState(() => currentUser = null);
    }
  }

  Future<void> _checkProjectPermissions() async {
    if (currentUser == null) {
      setState(() {
        isOwner = false;
        isMember = false;
        isLoading = false;
      });
      return;
    }

    final ownerCheck = await isOwnerCheck();
    final memberCheck = await _isMemberUser();

    if (mounted) {
      setState(() {
        isOwner = ownerCheck;
        if (isOwner) {
          isMember = true;
        } else {
          isMember = memberCheck;
        }
        isLoading = false;
      });
    }
  }

  Future<bool> isOwnerCheck() async {
    return currentUser?.username == widget.project.createdBy;
  }

  Future<bool> _isMemberUser() async {
    if (currentUser?.username == null) {
      return false; // Usar userId en lugar de username
    }

    try {
      return await FirebaseService().isProjectMember(widget.project.projectid,
          currentUser!.username // Enviar userId en lugar de username
          );
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading == true
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            backgroundColor: AppStyles.scaffoldColor,
            body: Column(
              children: [
                Expanded(
                  child: NestedScrollView(
                      body: TabBarView(controller: _tabController, children: [
                        _buildProjectDescription(context),
                        _buildChatSection(context),
                        _attachmentSection(),
                      ]),
                      headerSliverBuilder:
                          (BuildContext context, bool innerBoxIsScrolled) {
                        return [
                          SliverAppBar(
                            expandedHeight:
                                MediaQuery.of(context).size.height * 0.3,
                            pinned: true,
                            flexibleSpace: FlexibleSpaceBar(
                              background: _buildHeader(context),
                            ),
                            leading: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => context.canPop()
                                    ? context.pop()
                                    : context.push('/home')
                                // Navigator.pop(context),
                                ),
                            actions: [
                              if (isOwner)
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editProjectDetails(context),
                                ),
                            ],
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: SliverTabBarDelegate(
                              TabBar(
                                isScrollable: false,
                                tabAlignment: TabAlignment.center,
                                indicatorSize: TabBarIndicatorSize.tab,
                                controller: _tabController,
                                indicator: const BoxDecoration(
                                  image: DecorationImage(
                                    alignment: Alignment.center,
                                    opacity: 0.8,
                                    scale: 1,
                                    image: AssetImage(AppStyles.tabMarkerImage),
                                    fit: BoxFit.scaleDown,
                                  ),
                                ),
                                labelColor: AppStyles.colorAvatarBorder,
                                unselectedLabelColor:
                                    Theme.of(context).disabledColor,
                                indicatorColor: AppStyles.colorAvatarBorder,
                                dividerColor: Colors.transparent,
                                tabs: [
                                  _buildTab(
                                      true,
                                      Texts.translate('descripcionTab',
                                          LanguageProvider().currentLanguage),
                                      Icons.abc),
                                  _buildTab(
                                      true,
                                      Texts.translate('chatTab',
                                          LanguageProvider().currentLanguage),
                                      Icons.chat),
                                  _buildTab(
                                      true,
                                      Texts.translate('filesTab',
                                          LanguageProvider().currentLanguage),
                                      Icons.file_copy_sharp),
                                ],
                              ),
                            ),
                          ),
                        ];
                      }),
                ),
              ],
            ),
            bottomSheet: _buildChatInput(),
            resizeToAvoidBottomInset: true,
            floatingActionButton: _tabController.index == 2
                ? FloatingActionButton(
                    onPressed: () async {
                      setState(() {
                        _isUploading = true;
                      });
                      final uploadedFiles = await FirebaseService()
                          .pickAndUploadFileProject(widget.project.projectid,
                              currentUser!.username.toString());

                      if (uploadedFiles.isNotEmpty && mounted) {
                        setState(() {
                          _isUploading = false;
                        });
                      } else {
                        setState(() {
                          _isUploading = false;
                        });
                      }
                    },
                    child: const Icon(Icons.upload),
                  )
                : const SizedBox.shrink());
  }

  Widget _attachmentSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirebaseService().getAttachments(widget.project.projectid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
              height: 20,
              width: 20,
              child:
                  Center(child: AppStyles().progressIndicatorButton(context)));
        }
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return _buildAttachments(snapshot.data!);
        }
        return const Center(child: Text('No hay archivos adjuntos'));
      },
    );
  }

  Widget uploadProgressIndicator(UploadTask task) {
    return StreamBuilder<TaskSnapshot>(
      stream: task.snapshotEvents,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final progress =
              snapshot.data!.bytesTransferred / snapshot.data!.totalBytes;
          return CircularProgressIndicator(value: progress);
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _handleFileTap(Map<String, dynamic> file) async {
    final String url = file['url'];

    if (await canLaunchUrl(Uri.parse(url))) {
      try {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank', // Solo para web: abre en nueva pestaña
        );
      } catch (e) {
        _showErrorSnackBar('No se pudo abrir el archivo');
      }
    } else {
      _showErrorSnackBar('No se puede visualizar este tipo de archivo');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAttachments(List<Map<String, dynamic>> attachments) {
    return _isUploading == true
        ? SizedBox(
            height: 20,
            width: 20,
            child: Center(child: AppStyles().progressIndicatorButton(context)),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              final file = attachments[index];
              final type = file['type']?.split('/').first ?? 'file';
              final extension =
                  (file['extension'] as String?)?.toLowerCase() ?? 'file';

              return Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _handleFileTap(file),
                  splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  hoverColor: Theme.of(context).hoverColor,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icono con badge de extensión
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            // Icono principal
                            _buildFileIcon(type, extension),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Nombre del archivo
                        Tooltip(
                          message: file['name'],
                          child: Text(
                            file['name'],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Tamaño y tipo
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildFileIcon(String type, String extension) {
    IconData icon;
    Color color;

    switch (type) {
      case 'image':
        icon = Icons.image_outlined;
        color = Colors.amber;
        break;
      case 'video':
        icon = Icons.videocam_outlined;
        color = Colors.red;
        break;
      case 'audio':
        icon = Icons.audiotrack_outlined;
        color = Colors.blue;
        break;
      default:
        switch (extension) {
          case 'pdf':
            icon = Icons.picture_as_pdf_outlined;
            color = Colors.red;
            break;
          case 'doc':
          case 'docx':
            icon = Icons.article_outlined;
            color = Colors.blue;
            break;
          case 'xls':
          case 'xlsx':
            icon = Icons.table_chart_outlined;
            color = Colors.green;
            break;
          case 'zip':
          case 'rar':
            icon = Icons.archive_outlined;
            color = Colors.orange;
            break;
          default:
            icon = Icons.insert_drive_file_outlined;
            color = Colors.grey;
        }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Icon(icon, color: color, size: 40),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'image':
        return Colors.amber.shade700;
      case 'video':
        return Colors.red.shade600;
      case 'audio':
        return Colors.blue.shade600;
      case 'application':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(bytes > 1024 ? 1 : 0)} ${suffixes[i]}';
  }

  Widget _buildChatInput() {
    if (isMember != false && currentUser != null && _tabController.index == 1) {
      return _buildMessageInput();
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildTab(bool text, String texto, IconData icon) {
    return Tab(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 80), // Reducir de 100 a 80
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8), // Añadir padding horizontal
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: text == true
                  ? Text(texto, style: Theme.of(context).textTheme.bodySmall)
                  : Icon(
                      icon,
                      size: 20,
                    )),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles().getProjectCardColor(widget.project.projectid),
            AppStyles().getProjectCardColor(widget.project.projectid),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                widget.project.projectName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: StackedAvatars(members: widget.project.members),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProjectDescription(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: AppStyles().getCardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
      ),
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Texts.translate(
                  'projectDescr', _languageProvider.currentLanguage),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              widget.project.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatSection(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
              child: Text(
                Texts.translate(
                    'projectChat', _languageProvider.currentLanguage),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: _firebaseService
                  .getProjectChatStream(widget.project.projectid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text(Texts.translate(
                          'noMessagesChat', LanguageProvider().currentLanguage)));
                }

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final data = message.data() as Map<String, dynamic>;
                    return _buildMessageItem(data, context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> data, BuildContext context) {
    final isCurrentUser = data['senderName'] == currentUser?.username;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            UserProfileCardHover(
              authorUsername: data['senderName'],
              isExpert: false,
              onProfileOpen: () {},
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppStyles().getProjectCardColor(widget.project.projectid)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['senderName'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['text'],
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm')
                        .format((data['timestamp'] as Timestamp).toDate()),
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser)
            ProfileAvatar(
              seed: currentUser!.username,
              size: 22,
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.all(8), // Margen externo para mejor espaciado
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end, // Alinea los elementos al final
        children: [
          IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: () async {
                final filesUploaded =
                    await FirebaseService().pickAndUploadFileProject(
                  widget.project.projectid,
                  currentUser!.username.toString(),
                );
                if (filesUploaded.isNotEmpty && mounted) {
//showSnackBar('Archivo subido correctamente');
//show snackbar
                  SnackBarCustom()
                      .showSuccessSnackBar(context, widget.project.projectid);
                }
              }),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 5, // Máximo de líneas permitidas
              minLines: 1, // Mínimo de líneas inicial
              decoration: InputDecoration(
                hintText: Texts.translate(
                    'writeYourMessage', LanguageProvider().currentLanguage),
                border:
                    const UnderlineInputBorder(), // Sin bordes para un look limpio
                filled: true,

                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: IconButton(
              icon: const Icon(
                Icons.send,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await _firebaseService.sendProjectMessage(
      projectId: widget.project.projectid,
      text: _messageController.text,
      senderId: currentUser!.uid,
      senderName: currentUser!.username,
      senderPhoto: currentUser!.username ?? '',
    );

    _messageController.clear();
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _editProjectDetails(BuildContext context) {
    // Implementar lógica para editar detalles del proyecto
  }
}
