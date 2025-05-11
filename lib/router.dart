import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/widgets/mustbeloggedsection.dart';
import 'package:sapers/components/widgets/user_list_peoplescreen.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/auth_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart' as app_user;
import 'package:sapers/models/user.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  late Stream<QuerySnapshot> _usersStream;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  app_user.UserInfoPopUp? currentUser;
  List<app_user.UserInfoPopUp> _users = [];
  app_user.UserInfoPopUp? _selectedUser;

  @override
  void initState() {
    super.initState();
    _initUsersStream();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _initUsersStream() {
    currentUser =
        Provider.of<AuthProviderSapers>(context, listen: false).userInfo;

    _usersStream = FirebaseFirestore.instance
        .collection('userinfo')
        .where('username', isNotEqualTo: currentUser?.username)
        .orderBy('username', descending: false)
        .snapshots();
  }

  String get _currentUserId =>
      Provider.of<AuthProviderSapers>(context, listen: false).userInfo?.uid ??
      '';

  void _refreshCurrentUser() {
    Provider.of<AuthProviderSapers>(context, listen: false).refreshUserInfo();
  }

  // Verificar si es una pantalla pequeña (móvil)
  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 1,
            right: 1,
            top: 1,
          ),
          child: currentUser == null
              ? LoginRequiredWidget(
                  onTap: () => AuthService().isUserLoggedIn(context),
                )
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  // Cambiar el tipo aquí
                  stream: FirebaseFirestore.instance
                      .collection('userinfo')
                      .where('username', isNotEqualTo: currentUser?.username)
                      .orderBy('username', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error!);
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    _users = snapshot.data!.docs.map((doc) {
                      final data = doc.data();
                      try {
                        return UserInfoPopUp.fromMap(data);
                      } catch (e) {
                        debugPrint('Error parsing user ${doc.id}: $e');
                        return UserInfoPopUp(
                          uid: doc.id,
                          username: 'Usuario inválido',
                          email: '',
                        );
                      }
                    }).toList();

                    final filteredUsers = _filterUsers(_users);

                    return UserListWidget(
                      users: filteredUsers,
                      currentUserId: _currentUserId,
                      onRefreshCurrentUser: _refreshCurrentUser,
                      onSelectUser: (user) => Navigator.pushNamed(
                        context,
                        '/profile',
                        arguments: user,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 20),
          Text(
            Texts.translate(
                'error_loading_users', LanguageProvider().currentLanguage),
            style: TextStyle(
                color: Colors.red[700],
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() => _initUsersStream()),
            child: Text(
                Texts.translate('retry', LanguageProvider().currentLanguage)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(Texts.translate(
              'finding_users', LanguageProvider().currentLanguage)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty
                ? Texts.translate(
                    'no_users_available', LanguageProvider().currentLanguage)
                : '${Texts.translate('no_users_found_for', LanguageProvider().currentLanguage)} "$_searchQuery"',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton.icon(
                onPressed: () => _searchController.clear(),
                icon: const Icon(Icons.refresh),
                label: Text(Texts.translate(
                    'clear_search', LanguageProvider().currentLanguage)),
              ),
            ),
        ],
      ),
    );
  }

  List<app_user.UserInfoPopUp> _parseUsers(List<QueryDocumentSnapshot> docs) {
    return docs
        .map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            app_user.UserInfoPopUp user = app_user.UserInfoPopUp.fromMap(data);
            return user;
          } catch (e) {
            debugPrint('Error parsing user ${doc.id}: $e');
            return app_user.UserInfoPopUp(
              uid: doc.id,
              username: 'Usuario inválido',
              email: '',
            );
          }
        })
        .where((user) => user.uid != _currentUserId)
        .toList();
  }

  List<app_user.UserInfoPopUp> _filterUsers(
      List<app_user.UserInfoPopUp> users) {
    if (_searchQuery.isEmpty) {
      return users;
    }

    return users.where((user) {
      final username = user.username.toLowerCase();
      final specialty = (user.specialty ?? '').toLowerCase();
      final bio = (user.bio ?? '').toLowerCase();
      final location = (user.location ?? '').toLowerCase();

      return username.contains(_searchQuery) ||
          specialty.contains(_searchQuery) ||
          bio.contains(_searchQuery) ||
          location.contains(_searchQuery);
    }).toList();
  }
}
