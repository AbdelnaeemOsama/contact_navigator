import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'package:contact_navigator/core/utils/map_utils.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:contact_navigator/core/services/voice_service.dart';
import 'package:contact_navigator/features/map/widgets/map_search_bar.dart';
import 'package:contact_navigator/features/map/widgets/contact_preview_sheet.dart';

class MapTab extends StatefulWidget {
  final LatLng? focusLocation;
  const MapTab({super.key, this.focusLocation});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentLocation;
  LatLng? _focusedLocation;
  List<LatLng> _routePoints = [];
  bool _isRouting = false;
  bool _isSearching = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    if (widget.focusLocation != null) {
      _focusedLocation = widget.focusLocation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.focusLocation!, 15);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationMessage = 'Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationMessage = 'Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationMessage = 'Location permissions are permanently denied.');
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _locationMessage = null;
        });
        if (widget.focusLocation == null) {
          _mapController.move(_currentLocation!, 15);
        } else {
          _getDirectionsToLatLng(widget.focusLocation!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationMessage = 'Error getting location: $e');
      }
    }
  }

  void _showContactPreview(Contact contact, {LatLng? focusLatLng}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ContactPreviewSheet(
          contact: contact,
          focusLatLng: focusLatLng,
          isRouting: _isRouting,
          onGetDirections: _getDirections,
          onCopy: (text, label) => _copyToClipboard(context, text, label),
        );
      },
    );

    context.read<VoiceAssistantService>().speak(contact.displayName ?? 'Unknown');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContactsBloc, ContactsState>(
      builder: (context, state) {
        List<Marker> markers = [];
        if (state is ContactsLoaded) {
          for (var contact in state.allContacts) {
            for (var address in contact.addresses) {
              final link = contact.websites.isNotEmpty ? contact.websites.first.url : '';
              final parsed = MapUtils.parseLocationLink(link.isNotEmpty ? link : (address.formatted ?? ''));
              if (parsed != null) {
                markers.add(
                  Marker(
                    point: parsed,
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _showContactPreview(contact, focusLatLng: parsed),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          backgroundImage: contact.photo?.thumbnail != null
                              ? MemoryImage(contact.photo!.thumbnail!)
                              : null,
                          child: contact.photo?.thumbnail == null
                              ? const Icon(Icons.person, color: Color(0xFF33A1E5))
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
          }
        }

        if (_currentLocation != null) {
          markers.add(
            Marker(
              point: _currentLocation!,
              width: 30,
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation ?? const LatLng(30.0444, 31.2357),
                  initialZoom: _currentLocation != null ? 15 : 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.contact_navigator',
                  ),
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                  if (_focusedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _focusedLocation!,
                          width: 70,
                          height: 70,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF33A1E5),
                                width: 3,
                              ),
                              color: const Color(0xFF33A1E5).withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    MapSearchBar(
                      controller: _searchController,
                      onSubmitted: _searchPlace,
                      isSearching: _isSearching,
                      onChanged: () => setState(() {}),
                      onClear: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                    if (_locationMessage != null) ...[
                      const SizedBox(height: 12),
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.9),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.location_searching, color: AppColors.primaryBlue, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _locationMessage!,
                                  style: const TextStyle(color: AppColors.textBlue, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_locationMessage != null && _locationMessage!.contains('settings'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton.small(
                    heroTag: 'open_location_settings',
                    onPressed: Geolocator.openAppSettings,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.settings, color: AppColors.primaryBlue),
                  ),
                ),
              if (_routePoints.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton(
                    heroTag: 'clear_route',
                    onPressed: () {
                      setState(() {
                        _routePoints = [];
                        _focusedLocation = null;
                      });
                    },
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              FloatingActionButton(
                heroTag: 'current_location',
                onPressed: _getCurrentLocation,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: AppColors.primaryBlue),
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = LatLng(locations.first.latitude, locations.first.longitude);
        _mapController.move(loc, 15);
        if (mounted) {
          context.read<VoiceAssistantService>().speak('Found $query');
        }
        setState(() {
          _focusedLocation = loc;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No results found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error finding location')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _getDirections(Contact contact, LatLng? targetLatLng) async {
    LatLng? dest = targetLatLng;
    if (dest == null) {
      for (var address in contact.addresses) {
        final link = contact.websites.isNotEmpty ? contact.websites.first.url : '';
        dest = MapUtils.parseLocationLink(link.isNotEmpty ? link : (address.formatted ?? ''));
        if (dest != null) break;
      }
    }

    if (dest == null || _currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to determine start or end location.')),
      );
      return;
    }

    setState(() => _isRouting = true);
    final route = await MapUtils.getRoute(_currentLocation!, dest);
    if (mounted) {
      setState(() {
        _routePoints = route;
        _isRouting = false;
        _focusedLocation = dest;
      });
      if (route.isNotEmpty) {
        _mapController.move(dest, 14);
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not find a route.')));
      }
    }
  }

  Future<void> _getDirectionsToLatLng(LatLng dest) async {
    if (_currentLocation == null) return;
    setState(() => _isRouting = true);
    final route = await MapUtils.getRoute(_currentLocation!, dest);
    if (mounted) {
      setState(() {
        _routePoints = route;
        _isRouting = false;
        _focusedLocation = dest;
      });
      if (route.isNotEmpty) {
        _mapController.move(dest, 14);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find a route.')),
        );
      }
    }
  }
}
