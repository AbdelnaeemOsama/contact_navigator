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
import 'package:contact_navigator/features/map/widgets/route_info_sheet.dart';

class MapTab extends StatefulWidget {
  final LatLng? focusLocation;
  const MapTab({super.key, this.focusLocation});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  LatLng? _currentLocation;
  LatLng? _focusedLocation;
  List<LatLng> _routePoints = [];
  RouteInfo? _currentRouteInfo;
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
    _searchFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
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
      setState(
        () => _locationMessage = 'Location permissions are permanently denied.',
      );
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
    _dismissKeyboard();
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

    context.read<VoiceAssistantService>().speak(
      contact.displayName ?? 'Unknown',
    );
  }

  Future<String?> _showTransportModePicker() async {
    _dismissKeyboard();

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose Transport Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How do you want to get there?',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeCard(
                        icon: Icons.directions_car_rounded,
                        label: 'Driving',
                        subtitle: 'By car',
                        color: AppColors.primaryBlue,
                        onTap: () {
                          _dismissKeyboard();
                          Navigator.pop(context, 'driving');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModeCard(
                        icon: Icons.directions_walk_rounded,
                        label: 'Walking',
                        subtitle: 'On foot',
                        color: Colors.green,
                        onTap: () {
                          _dismissKeyboard();
                          Navigator.pop(context, 'walking');
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LatLng? _getContactLocation(Contact contact) {
    for (var address in contact.addresses) {
      final link = contact.websites.isNotEmpty
          ? contact.websites.first.url
          : '';
      final parsed = MapUtils.parseLocationLink(
        link.isNotEmpty ? link : (address.formatted ?? ''),
      );
      if (parsed != null) return parsed;
    }
    return null;
  }

  Widget _buildSearchResults(ContactsState state) {
    if (state is! ContactsLoaded) return const SizedBox.shrink();
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const SizedBox.shrink();

    final allWithLocations = state.allContacts.where((contact) {
      return _getContactLocation(contact) != null;
    }).toList();

    final matching = allWithLocations.where((contact) {
      final name = (contact.displayName ?? '').toLowerCase();
      final phone = contact.phones.isNotEmpty
          ? contact.phones.first.number.replaceAll(RegExp(r'\D'), '')
          : '';
      return name.contains(query) || phone.contains(query);
    }).toList();

    if (matching.isEmpty) {
      return Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No contacts found with location',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      shadowColor: Colors.black26,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 250),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: matching.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final contact = matching[index];
            final name = contact.displayName ?? 'Unknown';
            final photo = contact.photo?.thumbnail;
            final loc = _getContactLocation(contact)!;

            return ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                backgroundImage: photo != null ? MemoryImage(photo) : null,
                child: photo == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlue,
                        ),
                      )
                    : null,
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlue,
                  fontSize: 15,
                ),
              ),
              subtitle: contact.phones.isNotEmpty
                  ? Text(
                      contact.phones.first.number,
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
              onTap: () {
                _dismissKeyboard();
                _mapController.move(loc, 15);
                setState(() {
                  _focusedLocation = loc;
                });
                _showContactPreview(contact, focusLatLng: loc);
                _searchController.clear();
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContactsBloc, ContactsState>(
      builder: (context, state) {
        List<Marker> markers = [];
        if (state is ContactsLoaded) {
          for (var contact in state.allContacts) {
            for (var address in contact.addresses) {
              final link = contact.websites.isNotEmpty
                  ? contact.websites.first.url
                  : '';
              final parsed = MapUtils.parseLocationLink(
                link.isNotEmpty ? link : (address.formatted ?? ''),
              );
              if (parsed != null) {
                markers.add(
                  Marker(
                    point: parsed,
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () =>
                          _showContactPreview(contact, focusLatLng: parsed),
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
                              ? const Icon(
                                  Icons.person,
                                  color: Color(0xFF33A1E5),
                                )
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
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _currentLocation ?? const LatLng(30.0444, 31.2357),
                  initialZoom: _currentLocation != null ? 15 : 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                              color: const Color(
                                0xFF33A1E5,
                              ).withValues(alpha: 0.15),
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
                      focusNode: _searchFocusNode,
                      onSubmitted: _searchPlace,
                      isSearching: _isSearching,
                      enabled: _currentRouteInfo == null,
                      onChanged: () => setState(() {}),
                      onClear: () {
                        _searchController.clear();
                        _dismissKeyboard();
                        setState(() {});
                      },
                    ),
                    if (_searchController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSearchResults(state),
                    ],
                    if (_locationMessage != null) ...[
                      const SizedBox(height: 12),
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.9),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_searching,
                                color: AppColors.primaryBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _locationMessage!,
                                  style: const TextStyle(
                                    color: AppColors.textBlue,
                                    fontSize: 13,
                                  ),
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
              // Route info bottom sheet
              if (_currentRouteInfo != null && _routePoints.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 110,
                  child: RouteInfoSheet(
                    routeInfo: _currentRouteInfo!,
                    isLoading: _isRouting,
                    onClose: _clearRoute,
                  ),
                ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_locationMessage != null &&
                  _locationMessage!.contains('settings'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton.small(
                    heroTag: 'open_location_settings',
                    onPressed: Geolocator.openAppSettings,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.settings,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              if (_routePoints.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton(
                    heroTag: 'clear_route',
                    onPressed: _clearRoute,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              FloatingActionButton(
                heroTag: 'current_location',
                onPressed: _getCurrentLocation,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.my_location,
                  color: AppColors.primaryBlue,
                ),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No results found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error finding location')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _focusedLocation = null;
      _currentRouteInfo = null;
    });
  }

  Future<void> _fetchRoute(LatLng dest, String profile) async {
    if (_currentLocation == null) return;

    _dismissKeyboard();
    setState(() => _isRouting = true);
    final routeInfo = await MapUtils.getRouteWithInfo(
      _currentLocation!,
      dest,
      profile: profile,
    );
    if (!mounted) return;

    setState(() {
      _isRouting = false;
      if (routeInfo != null) {
        _routePoints = routeInfo.points;
        _currentRouteInfo = routeInfo;
        _focusedLocation = dest;
      }
    });

    if (routeInfo != null && routeInfo.points.isNotEmpty) {
      _mapController.move(dest, 14);
      _dismissKeyboard();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not find a route.')));
    }
  }

  Future<void> _getDirections(Contact contact, LatLng? targetLatLng) async {
    LatLng? dest = targetLatLng;
    if (dest == null) {
      for (var address in contact.addresses) {
        final link = contact.websites.isNotEmpty
            ? contact.websites.first.url
            : '';
        dest = MapUtils.parseLocationLink(
          link.isNotEmpty ? link : (address.formatted ?? ''),
        );
        if (dest != null) break;
      }
    }

    if (dest == null || _currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to determine start or end location.'),
        ),
      );
      return;
    }

    // Close the contact preview sheet first
    Navigator.pop(context);
    _dismissKeyboard();

    // Show transport mode picker
    final profile = await _showTransportModePicker();
    if (profile == null) return;

    _dismissKeyboard();
    await _fetchRoute(dest, profile);
  }

  Future<void> _getDirectionsToLatLng(LatLng dest) async {
    if (_currentLocation == null) return;

    _dismissKeyboard();

    // Show transport mode picker
    final profile = await _showTransportModePicker();
    if (profile == null) return;

    _dismissKeyboard();
    await _fetchRoute(dest, profile);
  }
}
