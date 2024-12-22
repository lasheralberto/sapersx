import 'package:flutter/material.dart';
import 'package:sapers/components/widgets/expert_profile_card.dart';
import 'package:sapers/components/widgets/profile_header.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
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
                child: ProfileHeader(profile: data),
              ),
              const SizedBox(width: 16),
              if (data.isExpert == true)
                Expanded(
                  child: SAPExpertProfile(
                    profile: data as UserInfoPopUp,
                  ),
                ),
            ],
          );
        } else {
          // Layout móvil (Column)
          return Column(
            children: [
              ProfileHeader(profile: data as UserInfoPopUp),
              const SizedBox(height: 16),
              if (data?.isExpert == true)
                SAPExpertProfile(
                  profile: data as UserInfoPopUp,
                ),
            ],
          );
        }
      },
    );
  }
}
