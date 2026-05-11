import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/core/utils/map_utils.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddressPage extends StatefulWidget {
  final String? initialAddress;
  final String? initialLink;
  final String? initialType;

  const AddressPage({super.key, this.initialAddress, this.initialLink, this.initialType});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  late String selectedType;
  late final TextEditingController _addressController;
  late final TextEditingController _linkController;
  final MapController _mapController = MapController();

  LatLng? _selectedLocation;
  bool _isLocating = false;
  bool _isGeocoding = false;
  bool _isResolvingLink = false;

  @override
  void initState() {
    super.initState();
    selectedType = widget.initialType ?? 'Home';
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
    _linkController = TextEditingController(text: widget.initialLink ?? '');

    // If we have an existing link, try to parse coordinates from it
    if (widget.initialLink != null && widget.initialLink!.isNotEmpty) {
      final parsed = MapUtils.parseLocationLink(widget.initialLink!);
      if (parsed != null) {
        _selectedLocation = parsed;
        // Jump the map once the widget is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _mapController.move(parsed, 16);
        });
      }
    }

    // Auto-parse whenever the link field changes
    _linkController.addListener(_onLinkChanged);
  }

  void _onLinkChanged() {
    final text = _linkController.text.trim();
    if (text.isEmpty) return;
    // Debounce: only parse when text looks like a URL (has http)
    if (!text.startsWith('http')) return;
    final parsed = MapUtils.parseLocationLink(text);
    if (parsed != null) {
      _moveToLocation(parsed, updateLink: false);
      _reverseGeocode(parsed);
    }
  }

  @override
  void dispose() {
    _linkController.removeListener(_onLinkChanged);
    _addressController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _saveAndReturn() {
    // When saving, generate the OSM link from the selected location
    String link = _linkController.text.trim();
    if (_selectedLocation != null) {
      link = MapUtils.generateOsmLink(_selectedLocation!);
    }

    Navigator.pop(context, {
      'type': selectedType,
      'address': _addressController.text.trim(),
      'link': link,
    });
  }

  /// Move the map to a location and drop a pin
  void _moveToLocation(LatLng location, {bool updateLink = true}) {
    setState(() {
      _selectedLocation = location;
    });
    _mapController.move(location, 16);
    if (updateLink) {
      _linkController.text = MapUtils.generateOsmLink(location);
    }
  }

  /// Reverse geocode: coordinates -> human-readable address
  Future<void> _reverseGeocode(LatLng location) async {
    setState(() => _isGeocoding = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea!,
          if (p.country != null && p.country!.isNotEmpty) p.country!,
        ];
        _addressController.text = parts.join(', ');
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  /// Forward geocode: address text -> coordinates
  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isGeocoding = true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        _moveToLocation(latLng);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location found for that address')),
        );
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find that location')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  /// Use GPS to get current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission permanently denied. Open settings to enable.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      _moveToLocation(latLng);
      await _reverseGeocode(latLng);
    } catch (e) {
      debugPrint('GPS error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get current location')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Parse a pasted link and jump the map to it
  Future<void> _parseAndJumpToLink() async {
    final link = _linkController.text.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a location link first')),
      );
      return;
    }

    setState(() => _isResolvingLink = true);
    try {
      final parsed = await MapUtils.resolveAndParseLocationLink(link);
      if (parsed != null && mounted) {
        _moveToLocation(parsed, updateLink: false);
        _reverseGeocode(parsed);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not parse coordinates from that link')),
        );
      }
    } finally {
      if (mounted) setState(() => _isResolvingLink = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultCenter = _selectedLocation ?? const LatLng(30.0444, 31.2357);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF004080),
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Address',
          style: TextStyle(
            color: Color(0xFF004080),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveAndReturn,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF33A1E5),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _addressController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _searchAddress,
                  decoration: InputDecoration(
                    hintText: 'Search street, City, State...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 20.0, right: 12.0),
                      child: Icon(
                        Icons.search,
                        color: Color(0xFF9E9E9E),
                        size: 24,
                      ),
                    ),
                    suffixIcon: _isGeocoding
                        ? const Padding(
                            padding: EdgeInsets.all(14.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF33A1E5)),
                            onPressed: () => _searchAddress(_addressController.text),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Segmented Control
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildTabItem('Home'),
                    _buildTabItem('Work'),
                    _buildTabItem('Other'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Interactive Map
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: defaultCenter,
                      initialZoom: _selectedLocation != null ? 16 : 13,
                      onTap: (tapPosition, latLng) {
                        _moveToLocation(latLng);
                        _reverseGeocode(latLng);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.contact_navigator',
                      ),
                      if (_selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 50,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Action Buttons Row
              Row(
                children: [
                  // GPS Button
                  GestureDetector(
                    onTap: _isLocating ? null : _getCurrentLocation,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF33A1E5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF33A1E5).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLocating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.my_location,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Show on Map / Parse Link Button
                  Expanded(
                    child: GestureDetector(
                      onTap: _parseAndJumpToLink,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF33A1E5),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF33A1E5).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isResolvingLink 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.link, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              _isResolvingLink ? 'Resolving...' : 'Show on Map',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Input Location Link field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _linkController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'Paste Google Maps or location link here',
                    hintStyle: TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
              ),
              // Show coordinates if a location is selected
              if (_selectedLocation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF33A1E5).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pin_drop, color: Color(0xFF33A1E5), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: Color(0xFF004080),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String title) {
    bool isSelected = selectedType == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF33A1E5) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
