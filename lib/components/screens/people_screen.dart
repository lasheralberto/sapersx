import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/user.dart' as app_user;
import 'package:sapers/components/widgets/user_avatar.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/user.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  late Stream<QuerySnapshot> _usersStream;
  UserInfoPopUp? currentUser;

  @override
  void initState() {
    super.initState();
    _usersStream =
        FirebaseFirestore.instance.collection('userinfo').snapshots();
    currentUser =
        Provider.of<AuthProviderSapers>(context, listen: false).userInfo;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildUserCard(BuildContext context, app_user.UserInfoPopUp user) {
    // En cualquier widget o servicio

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (user.specialty!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Chip(
                        label: Text(user.specialty.toString()),
                        backgroundColor:
                            AppStyles.colorAvatarBorder.withOpacity(0.1),
                      ),
                    ),
                  if (user.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        user.bio.toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: Theme.of(context).hintColor),
                      const SizedBox(width: 4),
                      Text(user!.location.toString(),
                          style: Theme.of(context).textTheme.bodySmall),
                      const Spacer(),
                      if (user.isExpert == true)
                        const Icon(Icons.verified,
                            color: Colors.blue, size: 18),
                    ],
                  ),
                ],
              ),
            ),
            _buildFollowButton(user),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(app_user.UserInfoPopUp user) {
    final currentUser = context.watch<app_user.UserInfoPopUp?>();
    final isFollowing = currentUser?.following?.contains(user.uid) ?? false;

    return IconButton(
      icon: Icon(
        isFollowing ? Icons.person_remove : Icons.person_add,
        color: isFollowing ? Colors.red : AppStyles.colorAvatarBorder,
      ),
      onPressed: () => _toggleFollowStatus(user.uid, isFollowing),
    );
  }

  void _toggleFollowStatus(String userId, bool isFollowing) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('userinfo').doc(currentUser.uid);

    if (isFollowing) {
      await userRef.update({
        'following': FieldValue.arrayRemove([userId])
      });
    } else {
      await userRef.update({
        'following': FieldValue.arrayUnion([userId])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs
              .map((doc) => app_user.UserInfoPopUp.fromMap(
                  doc.data() as Map<String, dynamic>))
              .where((user) =>
                  user.username.toLowerCase().contains(_searchQuery) ||
                  user.specialty!.toLowerCase().contains(_searchQuery) ||
                  user.bio!.toLowerCase().contains(_searchQuery) ||
                  user.location!.toLowerCase().contains(_searchQuery))
              .toList();
          if (users.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'No hay usuarios disponibles'
                    : 'No se encontraron resultados',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _buildUserCard(context, users[index]);
            },
          );
        },
      ),
    );
  }
}
