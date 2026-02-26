import 'dart:math';
import '../../../shared/models/ride_model.dart';
import '../data/ride_repository.dart';

class RideUseCase {
  final RideRepository _rideRepository = RideRepository();

  Future<RideModel> createRide(RideModel ride) async {
    try {
      final response = await _rideRepository.createRide(
        driverId: ride.driverId,
        ride: ride,
      );
      return RideModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to create ride: $e');
    }
  }

  Future<RideModel> updateRideStatus({
    required String rideId,
    required String status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _rideRepository.updateRideStatus(
        rideId: rideId,
        status: status,
        additionalData: additionalData,
      );
      return RideModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to update ride status: $e');
    }
  }

  Future<void> addTrackingPoint({
    required String rideId,
    required LocationPoint locationPoint,
  }) async {
    try {
      await _rideRepository.addTrackingPoint(
        rideId: rideId,
        locationPoint: locationPoint,
      );
    } catch (e) {
      throw Exception('Failed to add tracking point: $e');
    }
  }

  Future<RideModel> completeRide({
    required String rideId,
    required double totalDistance,
    required int duration,
    String? notes,
  }) async {
    try {
      final response = await _rideRepository.completeRide(
        rideId: rideId,
        totalDistance: totalDistance,
        duration: duration,
        notes: notes,
      );
      return RideModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to complete ride: $e');
    }
  }

  Future<RideModel> cancelRide({
    required String rideId,
    required String reason,
  }) async {
    try {
      final response = await _rideRepository.cancelRide(
        rideId: rideId,
        reason: reason,
      );
      return RideModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to cancel ride: $e');
    }
  }

  Future<List<RideModel>> getRideHistory({
    required String driverId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _rideRepository.getRideHistory(
        driverId: driverId,
        page: page,
        limit: limit,
      );
      final List<dynamic> ridesData = response['data']['rides'];
      return ridesData.map((json) => RideModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get ride history: $e');
    }
  }

  Future<RideModel?> getActiveRide({required String driverId}) async {
    try {
      final response = await _rideRepository.getActiveRide(driverId: driverId);
      if (response['data'] != null) {
        return RideModel.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get active ride: $e');
    }
  }

  Future<void> sendEmergencyAlert({
    required String driverId,
    required String rideId,
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    try {
      await _rideRepository.sendEmergencyAlert(
        driverId: driverId,
        rideId: rideId,
        latitude: latitude,
        longitude: longitude,
        message: message,
      );
    } catch (e) {
      throw Exception('Failed to send emergency alert: $e');
    }
  }

  // Business logic methods for ride flow
  bool canStartPickup(RideModel ride) {
    return ride.status == 'assigned';
  }

  bool canArrive(RideModel ride) {
    return ride.status == 'enRoute';
  }

  bool canPickUp(RideModel ride) {
    return ride.status == 'arrived';
  }

  bool canEndRide(RideModel ride) {
    return ride.status == 'inProgress';
  }

  double calculateDistance(List<LocationPoint> route) {
    if (route.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < route.length; i++) {
      totalDistance += _haversineDistance(
        route[i - 1].latitude,
        route[i - 1].longitude,
        route[i].latitude,
        route[i].longitude,
      );
    }
    return totalDistance;
  }

  int calculateDuration({required DateTime startTime, DateTime? endTime}) {
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
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
