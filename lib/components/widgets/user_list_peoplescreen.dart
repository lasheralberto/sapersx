import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sapers/components/widgets/user_card.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart' as app_user;

class UserListWidget extends StatelessWidget {
  final List<app_user.UserInfoPopUp> users;
  final String currentUserId;
  final Function() onRefreshCurrentUser;
  final Function(app_user.UserInfoPopUp) onSelectUser;
  final app_user.UserInfoPopUp? selectedUser;

  const UserListWidget({
    Key? key,
    required this.users,
    required this.currentUserId,
    required this.onRefreshCurrentUser,
    required this.onSelectUser,
    this.selectedUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final crossAxisCount = isSmallScreen ? 2 : 4;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return UserCard(
          user: user,
          onTap: () => onSelectUser.call(user),
        );
      },
    );
  }
}
