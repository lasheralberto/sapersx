import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sapers/components/widgets/invitation_item.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';

class ProjectInvitationSection extends StatefulWidget {
  final UserInfoPopUp profile;

  const ProjectInvitationSection({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  State<ProjectInvitationSection> createState() =>
      _ProjectInvitationSectionState();
}

class _ProjectInvitationSectionState extends State<ProjectInvitationSection> {
  bool isMessageSending = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppStyles().getCardColor(context),
      elevation: AppStyles().getCardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildSendMessageDialog(context),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  Texts.translate(
                      'projects', LanguageProvider().currentLanguage),
                  style: AppStyles().getTextStyle(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 500,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService().getMessages(widget.profile!.username),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        Texts.translate(
                            'noMessages', LanguageProvider().currentLanguage),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 24,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final message = snapshot.data!.docs[index];
                      final dateTime =
                          (message['timestamp'] as Timestamp).toDate();
                      final formattedDate =
                          DateFormat('dd-MM-yyyy HH:mm').format(dateTime);

                      return InvitationItem(
                        message: message,
                        formattedDate: formattedDate,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendMessageDialog(BuildContext context) {
    final messageController = TextEditingController();
    String? selectedProject;
    Project? selectedProjectObj;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (isMessageSending)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.mail_outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        Texts.translate('send_project_invitation',
                            LanguageProvider().currentLanguage),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Selector
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseService()
                            .getCreatedProjectsForUser(widget.profile.username),
                        builder: (context, snapshot) {
                          final projects = snapshot.data?.docs
                                  .map((doc) => Project.fromMap(
                                      doc.data() as Map<String, dynamic>,
                                      doc.id))
                                  .toList() ??
                              [];

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).cardColor,
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.2),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedProject,
                                hint: Text(
                                  Texts.translate('selectProject',
                                      LanguageProvider().currentLanguage),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .hintColor
                                          .withOpacity(0.7)),
                                ),
                                items: projects.map((project) {
                                  return DropdownMenuItem(
                                    value: project.projectid,
                                    child: Text(project.projectName),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() {
                                  selectedProject = value;
                                  selectedProjectObj = projects.firstWhere(
                                    (p) => p.projectid == value,
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Message Input
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).cardColor,
                          border: Border.all(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.2),
                          ),
                        ),
                        child: TextField(
                          controller: messageController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: Texts.translate('writeYourMessage',
                                LanguageProvider().currentLanguage),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        Texts.translate(
                            'cancel', LanguageProvider().currentLanguage),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: selectedProject == null || isMessageSending
                          ? null
                          : () async {
                              final message = messageController.text.trim();
                              if (message.isEmpty) return;

                              setState(() => isMessageSending = true);
                              try {
                                await FirebaseService().sendProjectInvitation(
                                  to: widget.profile.username,
                                  message: message,
                                  from: widget.profile.username,
                                  projectId: selectedProject!,
                                  projectName: selectedProjectObj!.projectName,
                                );
                                Navigator.pop(context);
                              } finally {
                                setState(() => isMessageSending = false);
                              }
                            },
                      child: Text(
                        Texts.translate('sendInvitation',
                            LanguageProvider().currentLanguage),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
