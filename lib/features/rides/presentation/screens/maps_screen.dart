import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../shared/models/ride_model.dart';
import '../../../../shared/widgets/swipe_button.dart';

class MapsScreen extends StatefulWidget {
  final RideModel ride;

  const MapsScreen({super.key, required this.ride});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final MapsService _mapsService = MapsService();
  final LocationService _locationService = LocationService();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  DirectionsResult? _directionsResult;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionSubscription;
  bool _isFollowingUser = true;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _updateLocationAndRoute();
  }

  void _startLocationTracking() {
    _locationService.startLocationUpdates();
    _positionSubscription = _locationService.positionStream.listen((position) {
      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = newLocation;
        _updateMarkers();
      });

      if (_isFollowingUser) {
        _animateToPosition(newLocation);
      }
    });
  }

  Future<void> _updateLocationAndRoute() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final currentLocation = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentLocation = currentLocation;
        });

        await _getDirections();
        _updateMarkers();

        if (_currentLocation != null) {
          _animateToPosition(_currentLocation!);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to get location: $e');
    }
  }

  Future<void> _getDirections() async {
    if (_currentLocation == null) return;

    LatLng destination;
    if (widget.ride.status == 'assigned' || widget.ride.status == 'enRoute') {
      destination = LatLng(
        widget.ride.pickupLocation.latitude,
        widget.ride.pickupLocation.longitude,
      );
    } else if (widget.ride.status == 'arrived' ||
        widget.ride.status == 'inProgress') {
      destination = LatLng(
        widget.ride.dropLocation.latitude,
        widget.ride.dropLocation.longitude,
      );
    } else {
      return;
    }

    try {
      final result = await _mapsService.getDirections(
        origin: _currentLocation!,
        destination: destination,
      );

      if (result != null) {
        setState(() {
          _directionsResult = result;
          _updatePolylines();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to get directions: $e');
    }
  }

  void _updateMarkers() {
    final markers = _mapsService.createMarkers(
      currentLocation: _currentLocation,
      pickupLocation: LatLng(
        widget.ride.pickupLocation.latitude,
        widget.ride.pickupLocation.longitude,
      ),
      dropLocation: LatLng(
        widget.ride.dropLocation.latitude,
        widget.ride.dropLocation.longitude,
      ),
      customerName: widget.ride.employeeName,
    );

    setState(() {
      _markers = markers;
    });
  }

  void _updatePolylines() {
    if (_directionsResult == null) return;

    final polylinePoints = _mapsService.decodePolylinePoints(
      _directionsResult!.polylineEncoded,
    );

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: Theme.of(context).primaryColor,
          width: 5,
          patterns: [],
        ),
      };
    });
  }

  Future<void> _animateToPosition(LatLng position) async {
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 16.0),
      ),
    );
  }

  void _toggleFollowUser() {
    setState(() {
      _isFollowingUser = !_isFollowingUser;
    });

    if (_isFollowingUser && _currentLocation != null) {
      _animateToPosition(_currentLocation!);
    }
  }

  void _showRoute() async {
    if (_directionsResult == null) return;

    final controller = await _controller.future;

    // Calculate bounds to show entire route
    double minLat = _currentLocation!.latitude;
    double maxLat = _currentLocation!.latitude;
    double minLng = _currentLocation!.longitude;
    double maxLng = _currentLocation!.longitude;

    final polylinePoints = _mapsService.decodePolylinePoints(
      _directionsResult!.polylineEncoded,
    );

    for (final point in polylinePoints) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );

    setState(() {
      _isFollowingUser = false;
    });
  }

  void _openExternalNavigation() {
    LatLng destination;
    if (widget.ride.status == 'assigned' || widget.ride.status == 'enRoute') {
      destination = LatLng(
        widget.ride.pickupLocation.latitude,
        widget.ride.pickupLocation.longitude,
      );
    } else if (widget.ride.status == 'arrived' ||
        widget.ride.status == 'inProgress') {
      destination = LatLng(
        widget.ride.dropLocation.latitude,
        widget.ride.dropLocation.longitude,
      );
    } else {
      return;
    }

    _mapsService.launchNavigation(destination: destination);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _getNextActionText() {
    switch (widget.ride.status) {
      case 'assigned':
        return 'Start Pickup';
      case 'enRoute':
        return 'Arrived at Pickup';
      case 'arrived':
        return 'Picked Up Customer';
      case 'inProgress':
        return 'End Ride';
      default:
        return 'Continue';
    }
  }

  void _performNextAction() {
    switch (widget.ride.status) {
      case 'assigned':
        Navigator.of(context).pop();
        break;
      case 'enRoute':
        Navigator.of(context).pop();
        break;
      case 'arrived':
        Navigator.of(context).pop();
        break;
      case 'inProgress':
        Navigator.of(context).pop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navigation - ${widget.ride.employeeName}'),
        actions: [
          IconButton(
            icon: Icon(
              _isFollowingUser ? Icons.gps_fixed : Icons.gps_not_fixed,
            ),
            onPressed: _toggleFollowUser,
            tooltip: _isFollowingUser
                ? 'Stop following location'
                : 'Follow my location',
          ),
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: _showRoute,
            tooltip: 'Show full route',
          ),
          IconButton(
            icon: const Icon(Icons.navigation),
            onPressed: _openExternalNavigation,
            tooltip: 'Open in Maps app',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            initialCameraPosition: _initialPosition,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            trafficEnabled: true,
            buildingsEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Trip information card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.ride.status == 'inProgress'
                              ? Icons.location_on
                              : Icons.person_pin_circle,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.ride.status == 'inProgress'
                                ? 'Drop-off: ${widget.ride.dropLocation.address}'
                                : 'Pickup: ${widget.ride.pickupLocation.address}',
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (_directionsResult != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _directionsResult!.duration,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.straighten,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _directionsResult!.distance,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Action button
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: SwipeButton(
              onConfirm: _performNextAction,
              text: _getNextActionText(),
              backgroundColor: Theme.of(context).primaryColor,
              confirmText: 'Completed!',
            ),
          ),
        ],
      ),
    );
  }
}
