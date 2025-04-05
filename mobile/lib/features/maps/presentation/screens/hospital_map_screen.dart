import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medileger/features/maps/data/models/hospital_model.dart';
import 'package:medileger/features/maps/data/repositories/hospital_repository.dart';

class HospitalMapScreen extends ConsumerStatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  ConsumerState<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends ConsumerState<HospitalMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  // Default position (will be updated with user's location)
  static const _defaultPosition = LatLng(37.42796133580664, -122.085749655962);

  // Current camera position
  CameraPosition _cameraPosition = const CameraPosition(
    target: _defaultPosition,
    zoom: 14.0,
  );

  // Current user position
  LatLng? _currentPosition;

  // Search radius in kilometers
  double _searchRadius = 10.0;

  // Map markers
  Set<Marker> _markers = {};

  // Selected hospital
  Hospital? _selectedHospital;

  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Get user's current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _cameraPosition = CameraPosition(
          target: _currentPosition!,
          zoom: 14.0,
        );
      });

      // Move camera to current position
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));

      // Fetch nearby hospitals
      _fetchNearbyHospitals();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch nearby hospitals
  Future<void> _fetchNearbyHospitals() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
      _markers = {};
    });

    try {
      // Fetch hospitals using provider
      final hospitals = await ref.read(nearbyHospitalsProvider({
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'distance': _searchRadius,
      }).future);

      // Create markers
      final markers = hospitals.map((hospital) {
        final position = LatLng(
          hospital.latitude ?? 0,
          hospital.longitude ?? 0,
        );

        return Marker(
          markerId: MarkerId(hospital.id),
          position: position,
          infoWindow: InfoWindow(
            title: hospital.name ?? 'Unknown Hospital',
            snippet: hospital.distance != null
                ? '${hospital.distance!.toStringAsFixed(1)} km away'
                : '',
          ),
          onTap: () {
            setState(() {
              _selectedHospital = hospital;
            });
          },
        );
      }).toSet();

      // Add user location marker
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );

      setState(() {
        _markers = markers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching hospitals: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Search for location
  Future<void> _searchLocation(String query) async {
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final position = LatLng(location.latitude, location.longitude);

        setState(() {
          _currentPosition = position;
          _cameraPosition = CameraPosition(
            target: position,
            zoom: 14.0,
          );
        });

        final controller = await _mapController.future;
        controller
            .animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));

        // Fetch nearby hospitals
        _fetchNearbyHospitals();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching location: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _cameraPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController.complete(controller);
            },
          ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildSearchBar(context),
          ),

          // Loading Indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Bottom Sheet for Selected Hospital
          if (_selectedHospital != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildHospitalInfoCard(context),
            ),

          // Radius Slider
          Positioned(
            bottom: _selectedHospital != null ? 220 : 16,
            right: 16,
            child: _buildRadiusControl(context),
          ),

          // Current Location Button
          Positioned(
            bottom: _selectedHospital != null ? 220 : 16,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'location_button',
              mini: true,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  // Search Bar Widget
  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search locations...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: _searchLocation,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hospital Info Card
  Widget _buildHospitalInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hospital = _selectedHospital!;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hospital Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_hospital,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital.name ?? 'Unknown Hospital',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (hospital.distance != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${hospital.distance!.toStringAsFixed(1)} km away',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reputation: ${hospital.reputation}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedHospital = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Hospital Details
                Row(
                  children: [
                    _buildInfoItem(
                      context,
                      'Contact',
                      hospital.email,
                      Icons.email,
                    ),
                    _buildInfoItem(
                      context,
                      'Wallet',
                      _truncateWalletAddress(hospital.walletAddress),
                      Icons.account_balance_wallet,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                        onPressed: () {
                          // TODO: Open directions in maps app
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Opening directions...')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Radius Control Widget
  Widget _buildRadiusControl(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_searchRadius.toStringAsFixed(1)} km',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 100,
              width: 40,
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  value: _searchRadius,
                  activeColor: colorScheme.primary,
                  onChanged: (value) {
                    setState(() {
                      _searchRadius = value;
                    });
                  },
                  onChangeEnd: (value) {
                    _fetchNearbyHospitals();
                  },
                ),
              ),
            ),
            const Icon(Icons.radar),
          ],
        ),
      ),
    );
  }

  // Helper widget for hospital details
  Widget _buildInfoItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Truncate wallet address for display
  String _truncateWalletAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}
