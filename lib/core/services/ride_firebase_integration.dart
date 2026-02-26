import 'package:driver_app/core/services/ride_tracking_service.dart';
import 'package:driver_app/shared/models/route_model.dart';

/// Helper class to integrate automatic Firebase saving into existing ride flow
/// This wraps your existing route operations and automatically saves to Firebase
class RideFirebaseIntegration {
  final RideTrackingService _trackingService = RideTrackingService();

  /// Call this when a new ride/route is created
  Future<void> onRideCreated({
    required RouteModel route,
    required String driverId,
  }) async {
    for (final ride in route.rides) {
      await _trackingService.createRide(
        rideId: ride.id,
        driverId: driverId,
        riderId: ride.passenger.id,
        rideDetails: {
          'routeId': route.id,
          'routeType': route.type.toString(),
          'passengerName': ride.passenger.fullName,
          'passengerPhone': ride.passenger.phoneNumber,
          'pickupAddress': ride.pickupAddress,
          'pickupLatitude': ride.pickupLatitude,
          'pickupLongitude': ride.pickupLongitude,
          'dropOffAddress': ride.dropOffAddress,
          'dropOffLatitude': ride.dropOffLatitude,
          'dropOffLongitude': ride.dropOffLongitude,
          'scheduledPickupTime': ride.scheduledPickupTime?.toIso8601String(),
          'scheduledDropOffTime': ride.scheduledDropOffTime?.toIso8601String(),
          'routeOrder': ride.routeOrder,
          'officeAddress': route.officeAddress,
        },
      );
    }
    print('✅ Route created in Firebase: ${route.id}');
  }

  /// Call this when driver starts navigating to pickup
  Future<void> onNavigateToPickup({
    required String rideId,
    required DateTime timestamp,
  }) async {
    await _trackingService.saveRideAction(
      rideId: rideId,
      actionType: 'navigating_to_pickup',
      actionData: {
        'navigatedToPickupAt': timestamp.toIso8601String(),
      },
    );

    await _trackingService.updateRideDetails(
      rideId: rideId,
      updates: {
        'navigatedToPickupAt': timestamp.toIso8601String(),
        'status': 'navigating_to_pickup',
      },
      changeReason: 'Driver started navigation to pickup',
    );
  }

  /// Call this when driver arrives at pickup location
  Future<void> onArriveAtPickup({
    required String rideId,
    required DateTime timestamp,
  }) async {
    await _trackingService.saveRideAction(
      rideId: rideId,
      actionType: 'arrived_at_pickup',
      actionData: {
        'arrivedAtPickupAt': timestamp.toIso8601String(),
      },
    );

    await _trackingService.updateRideDetails(
      rideId: rideId,
      updates: {
        'arrivedAtPickupAt': timestamp.toIso8601String(),
        'status': 'arrived_at_pickup',
      },
      changeReason: 'Driver arrived at pickup location',
    );
  }

  /// Call this when passenger is picked up
  Future<void> onPassengerPickedUp({
    required String rideId,
    required DateTime timestamp,
  }) async {
    await _trackingService.saveRideAction(
      rideId: rideId,
      actionType: 'passenger_picked_up',
      actionData: {
        'passengerPickedUpAt': timestamp.toIso8601String(),
      },
    );

    await _trackingService.updateRideDetails(
      rideId: rideId,
      updates: {
        'passengerPickedUpAt': timestamp.toIso8601String(),
        'status': 'passenger_on_board',
      },
      changeReason: 'Passenger picked up',
    );
  }

  /// Call this when driver starts navigating to destination
  Future<void> onNavigateToDestination({
    required String rideId,
    required DateTime timestamp,
  }) async {
    await _trackingService.saveRideAction(
      rideId: rideId,
      actionType: 'navigating_to_destination',
      actionData: {
        'navigatedToDestinationAt': timestamp.toIso8601String(),
      },
    );

    await _trackingService.updateRideDetails(
      rideId: rideId,
      updates: {
        'navigatedToDestinationAt': timestamp.toIso8601String(),
        'status': 'navigating_to_destination',
      },
      changeReason: 'Driver started navigation to destination',
    );
  }

  /// Call this when driver arrives at destination
  Future<void> onArriveAtDestination({
    required String rideId,
    required DateTime timestamp,
  }) async {
    await _trackingService.saveRideAction(
      rideId: rideId,
      actionType: 'arrived_at_destination',
      actionData: {
        'arrivedAtDestinationAt': timestamp.toIso8601String(),
      },
    );

    await _trackingService.updateRideDetails(
      rideId: rideId,
      updates: {
        'arrivedAtDestinationAt': timestamp.toIso8601String(),
        'status': 'arrived_at_destination',
      },
      changeReason: 'Driver arrived at destination',
    );
  }

  /// Call this when ride is completed
  Future<void> onRideCompleted({
    required String rideId,
    required DateTime timestamp,
    double? distance,
    int? duration,
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackingService.completeRide(
      rideId: rideId,
      completionData: {
        'rideCompletedAt': timestamp.toIso8601String(),
        'distance': distance,
        'duration': duration,
        if (additionalData != null) ...additionalData,
      },
    );
  }

  /// Call this when ride is cancelled
  Future<void> onRideCancelled({
    required String rideId,
    required String cancelledBy,
    required String reason,
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackingService.cancelRide(
      rideId: rideId,
      cancelledBy: cancelledBy,
      cancellationReason: reason,
      additionalData: additionalData,
    );
  }

  /// Call this when pickup address is changed
  Future<void> onPickupAddressChanged({
    required String rideId,
    required String newAddress,
    required double latitude,
    required double longitude,
  }) async {
    await _trackingService.updatePickupAddress(
      rideId: rideId,
      newAddress: newAddress,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Call this when drop-off address is changed
  Future<void> onDropOffAddressChanged({
    required String rideId,
    required String newAddress,
    required double latitude,
    required double longitude,
  }) async {
    await _trackingService.updateDropOffAddress(
      rideId: rideId,
      newAddress: newAddress,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Call this when pickup time is changed
  Future<void> onPickupTimeChanged({
    required String rideId,
    required DateTime newPickupTime,
  }) async {
    await _trackingService.updatePickupTime(
      rideId: rideId,
      newPickupTime: newPickupTime,
    );
  }

  /// Call this when drop-off time is changed
  Future<void> onDropOffTimeChanged({
    required String rideId,
    required DateTime newDropOffTime,
  }) async {
    await _trackingService.updateDropOffTime(
      rideId: rideId,
      newDropOffTime: newDropOffTime,
    );
  }

  /// Call this continuously during ride for GPS tracking
  Future<void> onLocationUpdate({
    required String rideId,
    required String driverId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
  }) async {
    await _trackingService.saveGPSTracking(
      rideId: rideId,
      driverId: driverId,
      latitude: latitude,
      longitude: longitude,
      speed: speed,
      heading: heading,
    );
  }

  /// Get complete ride details with all events
  Future<Map<String, dynamic>?> getRideDetails(String rideId) async {
    return await _trackingService.getRideDetails(rideId);
  }

  /// Get all events for a ride (full timeline)
  Future<List<Map<String, dynamic>>> getRideTimeline(String rideId) async {
    return await _trackingService.getRideEvents(rideId);
  }

  /// Get GPS tracking history for a ride
  Future<List<Map<String, dynamic>>> getRideRoute(String rideId) async {
    return await _trackingService.getRideGPSTracking(rideId);
  }
}
