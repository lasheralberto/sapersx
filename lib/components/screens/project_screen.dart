import 'package:avatar_stack/animated_avatar_stack.dart';
import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/stacked_avatars.dart';
import 'package:sapers/components/widgets/user_hover_card.dart';
import 'package:sapers/models/message_project.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/styles.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context).size;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header con información del proyecto
          SliverAppBar(
            expandedHeight: mediaQuery.height / 2,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(context),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Lista de mensajes
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mensajes del Proyecto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildMessagesList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getProjectColor(project.projectid),
            _getProjectColor(project.projectid).withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Text(
              project.projectName.toUpperCase(),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetadataRow(
              icon: Icons.person_outline,
              text: project.createdBy,
              context: context,
              light: true,
            ),
            const SizedBox(height: 8),
            _buildMetadataRow(
              icon: Icons.calendar_today_outlined,
              text: project.createdIn,
              context: context,
              light: true,
            ),
            const SizedBox(height: 16),
            _buildMetadataRow(
              icon: Icons.description,
              text: project.description,
              context: context,
              light: true,
            ),
            const SizedBox(
              height: 16,
            ),
            _buildMembersList(context, project.members),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow({
    required IconData icon,
    required String text,
    required BuildContext context,
    bool light = false,
  }) {
    final color = light
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align to top for multiline text
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.8)),
        const SizedBox(width: 8),
        Expanded(
          // Added Expanded widget to allow text wrapping
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color.withOpacity(0.8),
                ),
            softWrap: true, // Ensure text wraps
            overflow: TextOverflow.ellipsis, // Add ellipsis when text overflows
            maxLines: 10, // Limit to 3 lines - adjust as needed
          ),
        ),
      ],
    );
  }

  Widget _buildMembersList(BuildContext context, List<String> projectMembers) {
    return SizedBox(
      height: 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Miembros:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StackedAvatars(
              members: projectMembers,
              overlap: 0.3,
              maxDisplayed: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .where('invitationUid', isEqualTo: project.projectid)
          // .where('accepted', isEqualTo: true)
          //.orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar los mensajes'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data?.docs ?? [];

        if (messages.isEmpty) {
          return const Center(
            child: Text('No hay mensajes para este proyecto'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = MessageProject.fromSnapshot(messages[index]);
            return _MessageCard(message: message);
          },
        );
      },
    );
  }

  Color _getProjectColor(String projectId) {
    final colors = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
    ];
    return colors[projectId.hashCode % colors.length];
  }
}

class _MessageCard extends StatelessWidget {
  final MessageProject message;

  const _MessageCard({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: AppStyles.postCardReplyColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (message.accepted == true)
                            const Icon(
                              Icons.verified_outlined,
                              color: Colors.green,
                            ),
                          if (message.accepted == false)
                            const Icon(
                              Icons.question_mark_sharp,
                              color: AppStyles.colorAvatarBorder,
                            ),
                          const SizedBox(width: 10),
                          Text(
                            message.author,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            message.destiny,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDate(message.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message.content,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
