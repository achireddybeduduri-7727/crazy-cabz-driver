import 'dart:math';
import '../../../shared/models/route_model.dart';
import '../../../shared/models/ride_model.dart';
import '../data/route_repository.dart';

class RouteUseCase {
  final RouteRepository _routeRepository = RouteRepository();

  Future<RouteModel?> getActiveRoute({required String driverId}) async {
    try {
      final response = await _routeRepository.getActiveRoute(
        driverId: driverId,
      );
      if (response['data'] != null) {
        return RouteModel.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      // Log the error but don't throw - return null for "no active route"
      print('⚠️ Error getting active route: $e');
      // Only throw if it's a critical error (not a 404 or "not found")
      if (!e.toString().contains('404') &&
          !e.toString().toLowerCase().contains('no active route') &&
          !e.toString().toLowerCase().contains('not found')) {
        throw Exception('Failed to get active route: $e');
      }
      return null;
    }
  }

  Future<List<RouteModel>> getRouteHistory({
    required String driverId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _routeRepository.getRouteHistory(
        driverId: driverId,
        page: page,
        limit: limit,
      );
      final List<dynamic> routesData = response['data']['routes'];
      return routesData.map((json) => RouteModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get route history: $e');
    }
  }

  Future<RouteModel> startRoute({required String routeId}) async {
    try {
      final response = await _routeRepository.startRoute(routeId: routeId);
      return RouteModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to start route: $e');
    }
  }

  Future<RouteModel> completeRoute({
    required String routeId,
    String? notes,
  }) async {
    try {
      final response = await _routeRepository.completeRoute(
        routeId: routeId,
        notes: notes,
      );
      return RouteModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to complete route: $e');
    }
  }

  Future<RouteModel> cancelRoute({
    required String routeId,
    required String reason,
  }) async {
    try {
      final response = await _routeRepository.cancelRoute(
        routeId: routeId,
        reason: reason,
      );
      return RouteModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to cancel route: $e');
    }
  }

  Future<IndividualRide> updateIndividualRideStatus({
    required String rideId,
    required IndividualRideStatus status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _routeRepository.updateIndividualRideStatus(
        rideId: rideId,
        status: status.name,
        additionalData: additionalData,
      );
      return IndividualRide.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to update individual ride status: $e');
    }
  }

  Future<IndividualRide> markPassengerPresent({
    required String rideId,
    required bool isPresent,
  }) async {
    try {
      final response = await _routeRepository.markPassengerPresent(
        rideId: rideId,
        isPresent: isPresent,
      );
      return IndividualRide.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to mark passenger presence: $e');
    }
  }

  Future<void> addRouteTrackingPoint({
    required String routeId,
    required LocationPoint locationPoint,
  }) async {
    try {
      await _routeRepository.addRouteTrackingPoint(
        routeId: routeId,
        locationPoint: locationPoint,
      );
    } catch (e) {
      throw Exception('Failed to add route tracking point: $e');
    }
  }

  Future<void> sendOfficeTrackingUpdate({
    required String routeId,
    required Map<String, dynamic> trackingData,
  }) async {
    try {
      await _routeRepository.sendOfficeTrackingUpdate(
        routeId: routeId,
        trackingData: trackingData,
      );
    } catch (e) {
      throw Exception('Failed to send office tracking update: $e');
    }
  }

  Future<void> sendEmergencyAlert({
    required String driverId,
    required String routeId,
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    try {
      await _routeRepository.sendEmergencyAlert(
        driverId: driverId,
        routeId: routeId,
        latitude: latitude,
        longitude: longitude,
        message: message,
      );
    } catch (e) {
      throw Exception('Failed to send emergency alert: $e');
    }
  }

  // Business logic methods for route flow
  bool canStartRoute(RouteModel route) {
    return route.status == RouteStatus.scheduled;
  }

  bool canCompleteRoute(RouteModel route) {
    return route.status == RouteStatus.inProgress && route.isComplete;
  }

  bool canCancelRoute(RouteModel route) {
    return route.status == RouteStatus.scheduled ||
        route.status == RouteStatus.inProgress;
  }

  // Individual ride business logic
  bool canUpdateRideStatus(
    IndividualRide ride,
    IndividualRideStatus newStatus,
  ) {
    switch (newStatus) {
      case IndividualRideStatus.enRoute:
        return ride.status == IndividualRideStatus.scheduled;
      case IndividualRideStatus.arrived:
        return ride.status == IndividualRideStatus.enRoute;
      case IndividualRideStatus.pickedUp:
        return ride.status == IndividualRideStatus.arrived && ride.isPresent;
      case IndividualRideStatus.completed:
        return ride.status == IndividualRideStatus.pickedUp;
      case IndividualRideStatus.cancelled:
        return ride.status != IndividualRideStatus.completed;
      default:
        return false;
    }
  }

  double calculateRouteDistance(List<LocationPoint> trackingPoints) {
    if (trackingPoints.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < trackingPoints.length; i++) {
      totalDistance += _haversineDistance(
        trackingPoints[i - 1].latitude,
        trackingPoints[i - 1].longitude,
        trackingPoints[i].latitude,
        trackingPoints[i].longitude,
      );
    }
    return totalDistance;
  }

  int calculateRouteDuration({required DateTime startTime, DateTime? endTime}) {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  // Haversine formula for calculating distance between two points
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Route optimization helpers
  List<IndividualRide> optimizePickupOrder(
    List<IndividualRide> rides,
    double startLatitude,
    double startLongitude,
  ) {
    if (rides.length <= 1) return rides;

    final optimizedRides = <IndividualRide>[];
    final remainingRides = List<IndividualRide>.from(rides);

    double currentLat = startLatitude;
    double currentLon = startLongitude;

    while (remainingRides.isNotEmpty) {
      IndividualRide? nearestRide;
      double shortestDistance = double.infinity;
      int nearestIndex = 0;

      for (int i = 0; i < remainingRides.length; i++) {
        final ride = remainingRides[i];
        final distance = _haversineDistance(
          currentLat,
          currentLon,
          ride.pickupLatitude,
          ride.pickupLongitude,
        );

        if (distance < shortestDistance) {
          shortestDistance = distance;
          nearestRide = ride;
          nearestIndex = i;
        }
      }

      if (nearestRide != null) {
        optimizedRides.add(
          nearestRide.copyWith(routeOrder: optimizedRides.length + 1),
        );
        currentLat = nearestRide.pickupLatitude;
        currentLon = nearestRide.pickupLongitude;
        remainingRides.removeAt(nearestIndex);
      }
    }

    return optimizedRides;
  }

  // Estimate arrival times based on route order and traffic
  List<IndividualRide> calculateEstimatedTimes(
    List<IndividualRide> rides,
    DateTime startTime, {
    double averageSpeedKmh = 25,
    int stopDurationMinutes = 3,
  }) {
    final updatedRides = <IndividualRide>[];
    var currentTime = startTime;

    for (int i = 0; i < rides.length; i++) {
      final ride = rides[i];

      if (i > 0) {
        // Calculate travel time to this pickup from previous location
        final previousRide = rides[i - 1];
        final distance = _haversineDistance(
          previousRide.pickupLatitude,
          previousRide.pickupLongitude,
          ride.pickupLatitude,
          ride.pickupLongitude,
        );

        final travelTimeMinutes = (distance / averageSpeedKmh * 60).round();
        currentTime = currentTime.add(
          Duration(minutes: travelTimeMinutes + stopDurationMinutes),
        );
      }

      final updatedRide = ride.copyWith(scheduledPickupTime: currentTime);

      updatedRides.add(updatedRide);
    }

    return updatedRides;
  }
}
