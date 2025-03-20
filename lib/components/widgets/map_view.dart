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
  MapViewPeopleScreen(
      {super.key,
      required this.selectedUser,
      required this.onMapCreated,
      required this.isSmallScreen,
      required this.showMap,
      required this.users});

  @override
  State<MapViewPeopleScreen> createState() => _MapViewPeopleScreenState();
}

class _MapViewPeopleScreenState extends State<MapViewPeopleScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // Ubicación predeterminada para el mapa
  final LatLng _defaultLocation =
      const LatLng(40.416775, -3.703790); // Madrid, España

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _updateMarkers();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    // Make sure to set to null before disposing
    final controller = _mapController;
    _mapController = null;
    controller?.dispose();
  }

  void _updateMarkers() {
    if (!mounted) {
      return;
    }

    ///setState(() {
    _markers = widget.users
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
    //   });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.selectedUser?.latitude != null &&
            widget.selectedUser?.longitude != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(widget.selectedUser?.latitude as double,
                  widget.selectedUser?.longitude as double),
              14.0,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Stack(
            children: [
              GoogleMap(
                onMapCreated: (map) {
                  _mapController = map;
                  widget.onMapCreated!(map);
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
                                authorUsername: widget.selectedUser!.username,
                                isExpert:
                                    widget.selectedUser!.isExpert ?? false,
                                onProfileOpen: () {},
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (widget.selectedUser?.latitude != null &&
                                        widget.selectedUser?.longitude !=
                                            null) {
                                      _mapController?.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                          LatLng(
                                              widget.selectedUser?.latitude
                                                  as double,
                                              widget.selectedUser?.longitude
                                                  as double),
                                          14.0,
                                        ),
                                      );
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.selectedUser!.username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (widget.selectedUser!.specialty
                                              ?.isNotEmpty ??
                                          false)
                                        Text(
                                          widget.selectedUser!.specialty!,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    widget.selectedUser = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (widget.selectedUser!.bio?.isNotEmpty ?? false)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                widget.selectedUser!.bio!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (widget.selectedUser!.latitude != null &&
                              widget.selectedUser!.longitude != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Text(widget.selectedUser?.location ?? ''),
                                  // Text(
                                  //   '${widget.selectedUser!.latitude!.toStringAsFixed(6)}, ${widget.selectedUser!.longitude!.toStringAsFixed(6)}',
                                  //   style: const TextStyle(fontSize: 12),
                                  // ),
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
      ),
    );
    ;
  }
}
