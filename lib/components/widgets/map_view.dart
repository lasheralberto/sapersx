import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sapers/components/widgets/user_profile_hover.dart';
import 'package:sapers/models/user.dart';

class MapViewPeopleScreen extends StatefulWidget {
  UserInfoPopUp? selectedUser;
  Function(bool) showMap;
  final bool? isSmallScreen;
  List<UserInfoPopUp> users = [];
  void Function(GoogleMapController controller)? onMapCreated;
  MapViewPeopleScreen({
    super.key,
    required this.selectedUser,
    required this.onMapCreated,
    required this.isSmallScreen,
    required this.showMap,
    required this.users,
  });

  @override
  State<MapViewPeopleScreen> createState() => _MapViewPeopleScreenState();
}

class _MapViewPeopleScreenState extends State<MapViewPeopleScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  // Ubicación predeterminada para el mapa
  final LatLng _defaultLocation =
      const LatLng(40.416775, -3.703790); // Madrid, España

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  @override
  void didUpdateWidget(MapViewPeopleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar marcadores si la lista de usuarios cambia
    if (widget.users != oldWidget.users) {
      _updateMarkers();
    }
  }

  @override
  void dispose() {
    final controller = _mapController;
    _mapController = null;
    controller?.dispose();
    super.dispose();
  }

  Future<void> _updateMarkers() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Crear un conjunto temporal de marcadores
      final Set<Marker> newMarkers = widget.users
          .where((user) => user.latitude != null && user.longitude != null)
          .map((user) => Marker(
                markerId: MarkerId(user.uid),
                position: LatLng(user.latitude!, user.longitude!),
              
                onTap: () {
                  setState(() {
                    widget.selectedUser = user;
                  });
                },
              ))
          .toSet();

      // Actualizar el estado con los nuevos marcadores
      if (mounted) {
        setState(() {
          _markers = newMarkers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _centerMapOnUser(UserInfoPopUp user) {
    if (user.latitude != null &&
        user.longitude != null &&
        _mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(user.latitude!, user.longitude!),
          14.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Stack(
          children: [
            // Mapa principal
            GoogleMap(
              onMapCreated: (map) {
                setState(() {
                  _mapController = map;
                });
                widget.onMapCreated!(map);
                // Actualizar marcadores cuando el mapa esté listo
                _updateMarkers();
              },
              initialCameraPosition: CameraPosition(
                target: _defaultLocation,
                zoom: 5,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              compassEnabled: true,
              mapToolbarEnabled: true,
            ),

            // Indicador de carga
            if (_isLoading)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Cargando ubicaciones...",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),

            // Contador de usuarios en el mapa
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "${_markers.length} usuarios",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Botón de actualizar
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: "refreshMap",
                onPressed: _updateMarkers,
                backgroundColor: Colors.white,
                child: const Icon(Icons.refresh, color: Colors.black87),
              ),
            ),

            // Tarjeta informativa si un usuario está seleccionado
            if (widget.selectedUser != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UserProfileCardHover(
                              authorUsername: widget.selectedUser!.username,
                              isExpert: widget.selectedUser!.isExpert ?? false,
                              onProfileOpen: () {},
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.selectedUser!.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.selectedUser!.specialty
                                          ?.isNotEmpty ??
                                      false)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        widget.selectedUser!.specialty!,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Botón para centrar en el usuario
                                IconButton(
                                  icon: const Icon(Icons.center_focus_strong),
                                  tooltip: "Centrar en el mapa",
                                  onPressed: () =>
                                      _centerMapOnUser(widget.selectedUser!),
                                ),
                                // Botón para cerrar la tarjeta
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: "Cerrar",
                                  onPressed: () {
                                    setState(() {
                                      widget.selectedUser = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (widget.selectedUser!.bio?.isNotEmpty ?? false)
                          Container(
                            margin: const EdgeInsets.only(top: 12.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.selectedUser!.bio!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                        if (widget.selectedUser!.latitude != null &&
                            widget.selectedUser!.longitude != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 18, color: Colors.redAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.selectedUser?.location ??
                                        'Ubicación no especificada',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
}
