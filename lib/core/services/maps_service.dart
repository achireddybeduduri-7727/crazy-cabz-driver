import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// import 'package:maps_launcher/maps_launcher.dart'; // Temporarily disabled

class MapsService {
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();

  final Dio _dio = Dio();

  // Google Maps API Key (you'll need to add this to your project)
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  /// Get directions between two points
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'key': _apiKey,
        'mode': 'driving',
        'traffic_model': 'best_guess',
        'departure_time': 'now',
      };

      if (waypoints != null && waypoints.isNotEmpty) {
        queryParams['waypoints'] = waypoints
            .map((point) => '${point.latitude},${point.longitude}')
            .join('|');
      }

      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return DirectionsResult.fromJson(data['routes'][0]);
        }
      }
      return null;
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  /// Get estimated travel time and distance
  Future<RouteInfo?> getRouteInfo({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/distancematrix/json',
        queryParameters: {
          'origins': '${origin.latitude},${origin.longitude}',
          'destinations': '${destination.latitude},${destination.longitude}',
          'key': _apiKey,
          'mode': 'driving',
          'traffic_model': 'best_guess',
          'departure_time': 'now',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' &&
            data['rows'].isNotEmpty &&
            data['rows'][0]['elements'].isNotEmpty) {
          final element = data['rows'][0]['elements'][0];
          if (element['status'] == 'OK') {
            return RouteInfo(
              distance: element['distance']['text'],
              distanceValue: element['distance']['value'],
              duration: element['duration']['text'],
              durationValue: element['duration']['value'],
              durationInTraffic: element['duration_in_traffic']?['text'],
              durationInTrafficValue: element['duration_in_traffic']?['value'],
            );
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting route info: $e');
      return null;
    }
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(LatLng coordinates) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  /// Get coordinates from address (geocoding)
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
      return null;
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }

  /// Launch external navigation app
  Future<void> launchNavigation({
    required LatLng destination,
    String? destinationTitle,
  }) async {
    try {
      // TODO: Re-enable when maps_launcher package is added
      // await MapsLauncher.launchCoordinates(
      //   destination.latitude,
      //   destination.longitude,
      //   destinationTitle ?? 'Destination',
      // );
      print(
        'Navigation launch requested: ${destination.latitude}, ${destination.longitude}',
      );
    } catch (e) {
      print('Error launching navigation: $e');
    }
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Get current location
  Future<LatLng?> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Create polyline from encoded string
  List<LatLng> decodePolylinePoints(String encoded) {
    final decoded = decodePolyline(encoded);
    return decoded
        .map((point) => LatLng(point.first.toDouble(), point.last.toDouble()))
        .toList();
  }

  /// Create map markers
  Set<Marker> createMarkers({
    LatLng? currentLocation,
    LatLng? pickupLocation,
    LatLng? dropLocation,
    String? customerName,
  }) {
    Set<Marker> markers = {};

    if (currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    if (pickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: pickupLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: customerName != null ? 'Customer: $customerName' : null,
          ),
        ),
      );
    }

    if (dropLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop_location'),
          position: dropLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Drop Location'),
        ),
      );
    }

    return markers;
  }

  /// Create polyline for route
  Set<Polyline> createPolylines(List<LatLng> routePoints) {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: const Color(0xFF2E7D7F), // App primary color
        width: 4,
        patterns: [],
      ),
    };
  }

  /// Get camera bounds for multiple points
  CameraUpdate getCameraBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      100.0, // padding
    );
  }
}

// Data models for maps
class DirectionsResult {
  final String polylineEncoded;
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final LatLngBounds bounds;

  DirectionsResult({
    required this.polylineEncoded,
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.bounds,
  });

  factory DirectionsResult.fromJson(Map<String, dynamic> json) {
    final polylineEncoded = json['overview_polyline']['points'];
    final polylinePoints = MapsService().decodePolylinePoints(polylineEncoded);

    final leg = json['legs'][0];
    final distance = leg['distance']['text'];
    final duration = leg['duration']['text'];

    final bounds = LatLngBounds(
      southwest: LatLng(
        json['bounds']['southwest']['lat'],
        json['bounds']['southwest']['lng'],
      ),
      northeast: LatLng(
        json['bounds']['northeast']['lat'],
        json['bounds']['northeast']['lng'],
      ),
    );

    return DirectionsResult(
      polylineEncoded: polylineEncoded,
      polylinePoints: polylinePoints,
      distance: distance,
      duration: duration,
      bounds: bounds,
    );
  }
}

class RouteInfo {
  final String distance;
  final int distanceValue; // in meters
  final String duration;
  final int durationValue; // in seconds
  final String? durationInTraffic;
  final int? durationInTrafficValue; // in seconds

  RouteInfo({
    required this.distance,
    required this.distanceValue,
    required this.duration,
    required this.durationValue,
    this.durationInTraffic,
    this.durationInTrafficValue,
  });
}
