import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sapers/components/widgets/mustbeloggedsection.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/auth_service.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart' as app_user;
import 'package:sapers/models/styles.dart';

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
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _showMap = true; // Flag para alternar entre lista y mapa en móvil

  // Ubicación predeterminada para el mapa
  final LatLng _defaultLocation =
      const LatLng(40.416775, -3.703790); // Madrid, España

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
    _mapController?.dispose();
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
        .snapshots();
  }

  String get _currentUserId =>
      Provider.of<AuthProviderSapers>(context, listen: false).userInfo?.uid ??
      '';

  void _refreshCurrentUser() {
    Provider.of<AuthProviderSapers>(context, listen: false).refreshUserInfo();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMarkers();
  }

  void _updateMarkers() {
    setState(() {
      _markers = _users
          .where((user) => user.latitude != null && user.longitude != null)
          .map((user) => Marker(
                markerId: MarkerId(user.uid),
                position: LatLng(user.latitude!, user.longitude!),
                onTap: () {
                  setState(() {
                    _selectedUser = user;
                  });
                },
              ))
          .toSet();
    });
  }

  void _selectUserOnMap(app_user.UserInfoPopUp user) {
    setState(() {
      _selectedUser = user;
      // En dispositivos móviles, cambiar automáticamente a la vista del mapa
      if (_isSmallScreen(context)) {
        _showMap = true;
      }
    });

    if (user.latitude != null && user.longitude != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(user.latitude!, user.longitude!),
          14.0,
        ),
      );
    }
  }

  // Verificar si es una pantalla pequeña (móvil)
  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = _isSmallScreen(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 1,
            right: 1,
            top: 1,
          ),
          child: Column(
            children: [
              // Barra de búsqueda (comentada en el código original)
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: TextField(
              //     controller: _searchController,
              //     decoration: InputDecoration(
              //       hintText: Texts.translate(
              //           'search_users', LanguageProvider().currentLanguage),
              //       prefixIcon: const Icon(Icons.search),
              //       border: OutlineInputBorder(
              //         borderRadius:
              //             BorderRadius.circular(AppStyles.borderRadiusValue),
              //       ),
              //     ),
              //   ),
              // ),

              // Solo mostrar botones de navegación en pantallas pequeñas
              if (isSmallScreen)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showMap = false),
                          icon: const Icon(Icons.people),
                          label: Text(Texts.translate(
                              'users', LanguageProvider().currentLanguage)),
                          style: TextButton.styleFrom(
                            backgroundColor: !_showMap
                                ? Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1)
                                : null,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showMap = true),
                          icon: const Icon(Icons.map),
                          label: Text(Texts.translate(
                              'map', LanguageProvider().currentLanguage)),
                          style: TextButton.styleFrom(
                            backgroundColor: _showMap
                                ? Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1)
                                : null,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: currentUser == null
                    ? LoginRequiredWidget(
                        onTap: () {
                          AuthService().isUserLoggedIn(context);
                        },
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: _usersStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _buildErrorState(snapshot.error!);
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingState();
                          } else if (snapshot.connectionState ==
                              ConnectionState.none) {
                            return _buildErrorState(
                                'No se pudo cargar los datos');
                          }

                          if (snapshot.hasData) {
                            _users = _parseUsers(snapshot.data!.docs);
                            final filteredUsers = _filterUsers(_users);

                            // Actualizar marcadores cuando los usuarios cambien
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _updateMarkers();
                            });

                            return filteredUsers.isEmpty
                                ? _buildEmptyState()
                                : isSmallScreen
                                    ? _buildMobileLayout(filteredUsers)
                                    : _buildDesktopLayout(filteredUsers);
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      // FAB para volver a la lista desde el mapa (solo en móvil)
      floatingActionButton: isSmallScreen && _showMap && _selectedUser != null
          ? FloatingActionButton(
              mini: true,
              onPressed: () => setState(() => _selectedUser = null),
              child: const Icon(Icons.arrow_back),
            )
          : null,
    );
  }

  // Layout para móvil que alterna entre lista y mapa
  Widget _buildMobileLayout(List<app_user.UserInfoPopUp> users) {
    return _showMap ? _buildMapView() : _buildUserList(users);
  }

  // Layout para escritorio que muestra lista y mapa lado a lado
  Widget _buildDesktopLayout(List<app_user.UserInfoPopUp> users) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lista de usuarios (lado izquierdo)
        Expanded(
          flex: 1,
          child: _buildUserList(users),
        ),
        // Mapa (lado derecho)
        Expanded(
          flex: 1,
          child: _buildMapView(),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _defaultLocation,
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              compassEnabled: true,
            ),

            // Tarjeta informativa si un usuario está seleccionado
            if (_selectedUser != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            UserProfileCardHover(
                              authorUsername: _selectedUser!.username,
                              isExpert: _selectedUser!.isExpert ?? false,
                              onProfileOpen: () {},
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedUser!.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_selectedUser!.specialty?.isNotEmpty ??
                                      false)
                                    Text(
                                      _selectedUser!.specialty!,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedUser = null;
                                });
                              },
                            ),
                          ],
                        ),
                        if (_selectedUser!.bio?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _selectedUser!.bio!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (_selectedUser!.latitude != null &&
                            _selectedUser!.longitude != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selectedUser!.latitude!.toStringAsFixed(6)}, ${_selectedUser!.longitude!.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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

  Widget _buildUserList(List<app_user.UserInfoPopUp> users) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _UserListItem(
          user: user,
          currentUserId: _currentUserId,
          onUpdate: _refreshCurrentUser,
          onSelect: () => _selectUserOnMap(user),
          isSelected: _selectedUser?.uid == user.uid,
          isSmallScreen: _isSmallScreen(context),
          key: ValueKey(user.uid),
        );
      },
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

class _UserListItem extends StatefulWidget {
  final app_user.UserInfoPopUp user;
  final String currentUserId;
  final VoidCallback onUpdate;
  final VoidCallback onSelect;
  final bool isSelected;
  final bool isSmallScreen;

  const _UserListItem({
    required this.user,
    required this.currentUserId,
    required this.onUpdate,
    required this.onSelect,
    this.isSelected = false,
    this.isSmallScreen = false,
    super.key,
  });

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  bool _isLoading = false;
  bool? _isFollowing;
  late Stream<DocumentSnapshot> _currentUserStream;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 0),
      elevation: 0,
      color: widget.isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
      ),
      child: InkWell(
        onTap: widget.onSelect,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        child: Padding(
          padding: EdgeInsets.all(widget.isSmallScreen ? 16.0 : 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserProfileCardHover(
                    authorUsername: widget.user.username,
                    isExpert: widget.user.isExpert ?? false,
                    onProfileOpen: () {},
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.user.username,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.user.specialty?.isNotEmpty ?? false)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Chip(
                                  label: Text(widget.user.specialty!),
                                  backgroundColor: AppStyles.colorAvatarBorder
                                      .withOpacity(0.1),
                                  labelStyle: const TextStyle(fontSize: 12),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                          ],
                        ),
                        if (widget.user.location?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14,
                                    color: Theme.of(context).hintColor),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.user.location!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Coordenadas
                        if (widget.user.latitude != null &&
                            widget.user.longitude != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.gps_fixed,
                                    size: 14,
                                    color: Theme.of(context).hintColor),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${widget.user.latitude!.toStringAsFixed(5)}, ${widget.user.longitude!.toStringAsFixed(5)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.user.bio?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.user.bio!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildUserStats(context),
                  // Botón para ver en el mapa
                  if (widget.user.latitude != null &&
                      widget.user.longitude != null)
                    OutlinedButton.icon(
                      onPressed: widget.onSelect,
                      icon: const Icon(Icons.map, size: 16),
                      label: Text(widget.isSmallScreen
                          ? "" // En móvil, solo mostrar el ícono
                          : Texts.translate('view_on_map',
                              LanguageProvider().currentLanguage)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserStats(BuildContext context) {
    return Row(
      children: [
        _buildStatItem(context, (widget.user.followers?.length ?? 0).toString(),
            'seguidores'),
        const SizedBox(width: 16),
        _buildStatItem(context, (widget.user.following?.length ?? 0).toString(),
            'siguiendo'),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String count, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          Texts.translate(label, LanguageProvider().currentLanguage),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
