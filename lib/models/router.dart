// GoRouter configuration
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/screens/feed.dart';
import 'package:sapers/components/screens/project_screen.dart';
import 'package:sapers/components/screens/user_profile.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/user.dart';

final router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      name: 'home',
      path: '/home',
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      name: 'project-detail',
      path: '/project/:projectId',
      builder: (context, state) {
        final project = state.extra as Project; // Para pasar el objeto completo
        return ProjectDetailScreen(project: project);
      },
    ),
    GoRoute(
      name: 'profile',
      path: '/profile/:username', // Cambiado a user=:username
      builder: (context, state) {
        final username =
            state.pathParameters['username']; // Obtener el parámetro

        return FutureBuilder<UserInfoPopUp?>(
          future: FirebaseService().getUserInfoByUsername(username ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('Usuario no encontrado'));
            }

            final userInfo = snapshot.data;
            if (userInfo == null) {
              return const Center(child: Text('Usuario no encontrado'));
            }
            return UserProfilePage(userinfo: userInfo);
          },
        );
      },
    ),
  ],
);
