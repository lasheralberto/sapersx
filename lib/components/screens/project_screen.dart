import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/stacked_avatars.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/user.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final UserInfoPopUp userinfo;

  ProjectDetailScreen({
    Key? key,
    required this.userinfo,
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

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    isOwnerCheck().then((value) => setState(() => isOwner = value));
    isMemberUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _firebaseService
        .getUserInfoByEmail(FirebaseAuth.instance.currentUser!.email!);
    setState(() => currentUser = user);
  }

  Future<bool> isOwnerCheck() async {
    return widget.project.createdBy == currentUser?.username;
  }

  Future<void> isMemberUser() async {
    var isMemberUser = await FirebaseService()
        .isProjectMember(widget.project.projectid, currentUser!.username);

    setState(() => isMember = isMemberUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.3,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(context),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
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
          isMember == false ? SizedBox.shrink() : _buildMessageInput(),
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
              'Descripción del Proyecto',
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
          'Chat del Proyecto',
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
    final isCurrentUser = data['senderId'] == currentUser?.username;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            ProfileAvatar(
              seed: currentUser!.username,
              size: 20,
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
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send,
                color:
                    AppStyles().getProjectCardColor(widget.project.projectid)),
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
