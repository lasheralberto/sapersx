import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/widgets/expert_profile_card.dart';
import 'package:sapers/components/widgets/invitation_item.dart';
import 'package:sapers/components/widgets/profile_header.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/user_reviews.dart';

class UserProfilePage extends StatefulWidget {
  final UserInfoPopUp? userinfo;

  const UserProfilePage({
    super.key,
    required this.userinfo,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<UserInfoPopUp?> userProfileData;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    userProfileData = _loadUserProfileData();
  }

  Future<UserInfoPopUp?> _loadUserProfileData() async {
    return widget.userinfo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles().getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppStyles().getBackgroundColor(context),
            elevation: 0,
            pinned: true,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: TwitterColors.darkGray,
                onPressed: () => context.pop()
                // context.canPop() ? context.pop() : context.go('/home'),
                ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  FutureBuilder<UserInfoPopUp?>(
                    future: userProfileData,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar los datos: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (!snapshot.hasData) {
                        return const Center(
                          child:
                              Text('No se encontró información del usuario.'),
                        );
                      }
                      return ResponsiveProfileLayout(data: snapshot.data!);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResponsiveProfileLayout extends StatefulWidget {
  final UserInfoPopUp data;

  const ResponsiveProfileLayout({
    required this.data,
    super.key,
  });

  @override
  State<ResponsiveProfileLayout> createState() =>
      _ResponsiveProfileLayoutState();
}

class _ResponsiveProfileLayoutState extends State<ResponsiveProfileLayout> {
  UserInfoPopUp? userFrom;
  String? selectedProject;
  bool isMessageSending = false;

  @override
  void initState() {
    super.initState();
    _getUserFrom();
  }

  Future<void> _getUserFrom() async {
    final user =
        Provider.of<AuthProviderSapers>(context, listen: false).userInfo;
    ;
    setState(() {
      userFrom = user;
    });
  }

  Widget _buildSendMessageDialog(BuildContext context, UserInfoPopUp profile) {
    final messageController = TextEditingController();
    final backgroundColor = Colors.white;
    String? selectedProject;
    Project? selectedProjectObj;

    return StatefulBuilder(
      builder: (context, setState) => Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          title: isMessageSending
              ? AppStyles().progressIndicatorButton()
              : Text(
                  Texts.translate('send_project_invitation',
                      LanguageProvider().currentLanguage),
                  style: AppStyles().getTextStyle(
                    context,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Texts.translate('selectProject',
                              LanguageProvider().currentLanguage),
                          style: AppStyles().getTextStyle(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseService()
                              .getCreatedProjectsForUser(userFrom!.username),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No projects yet',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              );
                            }

                            // Convertir los documentos en objetos Project
                            final projects = snapshot.data!.docs
                                .map((doc) => Project.fromMap(
                                    doc.data() as Map<String, dynamic>, doc.id))
                                .toList();

                            return Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedProject,
                                underline: const SizedBox(),
                                hint: Text(
                                  Texts.translate('selectProject',
                                      LanguageProvider().currentLanguage),
                                  style: AppStyles().getTextStyle(context),
                                ),
                                items: projects.map((project) {
                                  return DropdownMenuItem<String>(
                                    value: project.projectid,
                                    child: Text(
                                      project.projectName,
                                      style: AppStyles().getTextStyle(context),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    selectedProject = value;
                                    // Buscar y asignar el objeto completo correspondiente
                                    selectedProjectObj = projects.firstWhere(
                                      (project) => project.projectid == value,
                                    );
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          Texts.translate('writeYourMessage',
                              LanguageProvider().currentLanguage),
                          style: AppStyles().getTextStyle(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: messageController,
                              decoration: InputDecoration(
                                hintText: Texts.translate('writeYourMessage',
                                    LanguageProvider().currentLanguage),
                                hintStyle: AppStyles().getTextStyle(
                                  context,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: AppStyles()
                                  .getTextStyle(context, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: selectedProject == null
                        ? null
                        : () async {
                            final message = messageController.text.trim();
                            if (message.isNotEmpty) {
                              setState(() {
                                isMessageSending = true;
                              });
                              try {
                                final success = await FirebaseService()
                                    .sendProjectInvitation(
                                  to: profile.username,
                                  message: message,
                                  from: userFrom!.username,
                                  projectId: selectedProject!,
                                  projectName: selectedProjectObj!.projectName,
                                );
                                Navigator.pop(context);
                              } catch (e) {
                                // Manejo de errores...
                              } finally {
                                setState(() {
                                  isMessageSending = false;
                                });
                              }
                            }
                          },
                    child: Text(
                      Texts.translate(
                          'sendInvitation', LanguageProvider().currentLanguage),
                      style: AppStyles().getTextStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesSection(BuildContext context, UserInfoPopUp profile) {
    return Card(
      color: AppStyles().getCardColor(context),
      elevation: AppStyles().getCardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                      builder: (context) =>
                          _buildSendMessageDialog(context, profile),
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
              height: 300,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService().getMessages(profile.username),
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

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 2,
                child: Column(
                  children: [
                    ProfileHeader(profile: widget.data),
                    _buildMessagesSection(context, widget.data)
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (widget.data.isExpert == true)
                Expanded(
                  child: SAPExpertProfile(profile: widget.data),
                ),
            ],
          );
        }

        return Column(
          children: [
            ProfileHeader(profile: widget.data),
            _buildMessagesSection(context, widget.data),
            const SizedBox(height: 16),
            if (widget.data.isExpert == true)
              SAPExpertProfile(profile: widget.data),
          ],
        );
      },
    );
  }
}
