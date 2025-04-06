// GoRouter configuration
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/screens/feed.dart';
import 'package:sapers/components/screens/project_screen.dart';
import 'package:sapers/components/screens/user_profile.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/auth_provider.dart' as zauth;
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/user.dart';

final router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      name: 'home',
      path: '/home',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const AuthWrapper(),
      ),
    ),
    GoRoute(
      name: 'project-detail',
      path: '/project/:projectId',
      pageBuilder: (context, state) {
        final project = state.extra as Project;
        return MaterialPage(
          key: state.pageKey,
          child: ProjectDetailScreen(project: project),
        );
      },
    ),
    GoRoute(
      name: 'profile',
      path: '/profile/:username',
      pageBuilder: (context, state) {
        final username = state.pathParameters['username']!;
        final authProvider = context.read<zauth.AuthProviderSapers>();

        if (authProvider.userInfo?.username == username) {
          return MaterialPage(
            key: ValueKey('profile_$username'),
            child: UserProfilePage(userinfo: authProvider.userInfo!),
          );
        }

        return MaterialPage(
          key: ValueKey('profile_$username'),
          child: FutureBuilder<UserInfoPopUp?>(
            future: FirebaseService().getUserInfoByUsername(username),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Scaffold(
                  appBar: AppBar(),
                  body: const Center(child: Text('Usuario no encontrado')),
                );
              }
              return UserProfilePage(userinfo: snapshot.data!);
            },
          ),
        );
      },
    ),
  ],
  errorPageBuilder: (context, state) => MaterialPage(
    key: state.pageKey,
    child: Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('Error: ${state.error}')),
    ),
  ),
);
