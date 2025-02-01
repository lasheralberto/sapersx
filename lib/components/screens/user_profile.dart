import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sapers/components/widgets/expert_profile_card.dart';
import 'package:sapers/components/widgets/profile_header.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
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

  // Función que combina ambos datos en una sola estructura
  Future<UserInfoPopUp?> _loadUserProfileData() async {
    final profileFuture =
        await _firebaseService.getUserInfoByEmail(widget.userinfo!.email);

    return profileFuture;
    // Combina los datos en una sola clase
    // return UserInfoPopUp(username: userInfo.username, email: userInfo.email, bio: userInfo.bio, location: userInfo.location, website: userInfo.website, isExpert: userInfo.isExpert, specialty: userInfo.specialty, hourlyRate: userInfo.hourlyRate, joinDate: userInfo.joinDate, isAvailable: userInfo.isAvailable, experience: userInfo.experience, reviews: userInfo.reviews);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles().getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: AppStyles().getBackgroundColor(context),
            elevation: 0,
            pinned: true,
            title: Text(
              widget.userinfo!.username,
              style: AppStyles().getTextStyle(context),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: TwitterColors.darkGray,
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Profile Header y Expert Profile Card
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
                      } else {
                        final data = snapshot.data!;
                        return ResponsiveProfileLayout(data: data);
                      }
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

class ResponsiveProfileLayout extends StatelessWidget {
  final UserInfoPopUp data;

  const ResponsiveProfileLayout({
    required this.data,
    super.key,
  });
  Widget _buildSendMessageDialog(BuildContext context, String username) {
    final TextEditingController messageController = TextEditingController();
    final Color backgroundColor = Colors.white; // Color base suave
    bool isMessageSending = false;

    return AlertDialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: AppStyles().getCardElevation(context),
      title: Center(
        child: isMessageSending == true
            ? AppStyles().progressIndicatorButton()
            : Text(
                'Enviar mensaje',
                style: AppStyles().getTextStyle(
                  context,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      content: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            // Sombra inferior/derecha para efecto "sombra"
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: messageController,
          decoration: InputDecoration(
            hintText: 'Escribe tu mensaje aquí...',
            hintStyle: AppStyles().getTextStyle(context,
                fontSize: 14, fontWeight: FontWeight.w300),
            border: InputBorder.none,
          ),
          maxLines: 3,
          style: AppStyles().getTextStyle(context, fontSize: 16),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            final message = messageController.text.trim();
            if (message.isNotEmpty) {
              // Obtener el usuario que envía el mensaje
              UserInfoPopUp? fromUser = await FirebaseService()
                  .getUserInfoByEmail(
                      FirebaseAuth.instance.currentUser!.email!);
              // Envía el mensaje a Firebase
              isMessageSending = true;
              final success = await FirebaseService().sendMessage(
                  to: username, message: message, from: fromUser!.username);
              if (success) {
                isMessageSending = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Mensaje enviado correctamente')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al enviar el mensaje')),
                );
              }
            }
            Navigator.of(context).pop();
          },
          style: AppStyles().getButtonStyle(context),
          child: Text(
            'Enviar',
            style: AppStyles().getTextStyle(
              context,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Nueva sección de mensajes
  Widget _buildMessagesSection(BuildContext context, profile) {
    return Card(
      color: AppStyles().getCardColor(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          _buildSendMessageDialog(context, profile.username),
                    );
                  },
                  child: Icon(Icons.add),
                ),
                const SizedBox(width: 8),
                Text(
                  Texts.translate('mensajes', globalLanguage),
                  style: AppStyles().getTextStyle(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseService().getMessages(profile.username),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                final messages = snapshot.data?.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: messages!.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    // Convertir y formatear el timestamp
                    final Timestamp firestoreTimestamp = message['timestamp'];
                    final DateTime dateTime = firestoreTimestamp.toDate();
                    final String formattedDate =
                        DateFormat('dd-MM-yyyy HH:mm').format(dateTime);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Remitente
                              Text(
                                message['from'],
                                style: AppStyles().getTextStyle(
                                  context,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Mensaje
                              Text(
                                message['message'],
                                style: AppStyles()
                                    .getTextStyle(context, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              // Timestamp formateado
                              Text(
                                formattedDate,
                                style: AppStyles().getTextStyle(
                                  context,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definimos un breakpoint para cambiar entre layouts
    final bool isDesktop = MediaQuery.of(context).size.width > 768;

    // Layout responsive que cambia entre Row y Column
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isDesktop) {
          // Layout de escritorio (Row)
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 2,
                child: Column(
                  children: [
                    ProfileHeader(profile: data),
                    _buildMessagesSection(context, data)
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (data.isExpert == true)
                Expanded(
                  child: SAPExpertProfile(
                    profile: data,
                  ),
                ),
            ],
          );
        } else {
          // Layout móvil (Column)
          return Column(
            children: [
              ProfileHeader(profile: data),
              const SizedBox(height: 16),
              if (data.isExpert == true)
                SAPExpertProfile(
                  profile: data,
                ),
            ],
          );
        }
      },
    );
  }
}
