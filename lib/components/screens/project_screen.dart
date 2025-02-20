import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/stacked_avatars.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  ProjectDetailScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool isOwner = false;
  bool isMember = false;
  UserInfoPopUp? currentUser;
  bool? isLoading = true;

  @override
  void initState() {
    super.initState();
    isLoading = true;
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
          await _firebaseService.getUserInfoByEmail(firebaseUser.email!);
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
    if (currentUser?.username == null)
      return false; // Usar userId en lugar de username

    try {
      return await FirebaseService().isProjectMember(widget.project.projectid,
          currentUser!.username! // Enviar userId en lugar de username
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
            body: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProjectDescription(context),
                              const SizedBox(height: 30),
                              _buildChatSection(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMember != false && currentUser != null)
                  _buildMessageInput(),
                if (isMember == false && currentUser != null)
                    Padding(
                    padding:const EdgeInsets.all(50.0),
                    child: Center(
                      child: Text(
                          Texts.translate('notMember', globalLanguage),)
                    ),
                  )
              ],
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Texts.translate('projectDescr', globalLanguage),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
         Texts.translate('projectChat', globalLanguage),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 15),
        StreamBuilder<QuerySnapshot>(
          stream:
              _firebaseService.getProjectChatStream(widget.project.projectid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No hay mensajes'));
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
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> data, BuildContext context) {
    final isCurrentUser = data['senderName'] == currentUser?.username;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            ProfileAvatar(
              seed: data['senderName'],
              size: 22,
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
      padding: const EdgeInsets.all(20.0),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppStyles.borderRadiusValue),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: _sendMessage,
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
      senderId: currentUser!.uid!,
      senderName: currentUser!.username!,
      senderPhoto: currentUser!.username ?? '',
    );

    _messageController.clear();
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _editProjectDetails(BuildContext context) {
    // Implementar lógica para editar detalles del proyecto
  }
}
