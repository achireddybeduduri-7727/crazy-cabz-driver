import 'package:equatable/equatable.dart';
import '../../../../shared/models/route_model.dart';
import '../../../../shared/models/ride_model.dart';

abstract class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object?> get props => [];
}

class LoadActiveRoute extends RouteEvent {
  final String driverId;

  const LoadActiveRoute(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class LoadRouteHistory extends RouteEvent {
  final String driverId;
  final int page;
  final int limit;

  const LoadRouteHistory({
    required this.driverId,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [driverId, page, limit];
}

class StartRoute extends RouteEvent {
  final String routeId;

  const StartRoute(this.routeId);

  @override
  List<Object?> get props => [routeId];
}

class CompleteRoute extends RouteEvent {
  final String routeId;
  final String? notes;

  const CompleteRoute(this.routeId, {this.notes});

  @override
  List<Object?> get props => [routeId, notes];
}

class CancelRoute extends RouteEvent {
  final String routeId;
  final String reason;

  const CancelRoute({required this.routeId, required this.reason});

  @override
  List<Object?> get props => [routeId, reason];
}

class UpdateIndividualRideStatus extends RouteEvent {
  final String rideId;
  final IndividualRideStatus status;
  final Map<String, dynamic>? additionalData;

  const UpdateIndividualRideStatus({
    required this.rideId,
    required this.status,
    this.additionalData,
  });

  @override
  List<Object?> get props => [rideId, status, additionalData];
}

class MarkPassengerPresent extends RouteEvent {
  final String rideId;
  final bool isPresent;

  const MarkPassengerPresent({required this.rideId, required this.isPresent});

  @override
  List<Object?> get props => [rideId, isPresent];
}

class AddRouteTrackingPoint extends RouteEvent {
  final String routeId;
  final LocationPoint locationPoint;

  const AddRouteTrackingPoint({
    required this.routeId,
    required this.locationPoint,
  });

  @override
  List<Object?> get props => [routeId, locationPoint];
}

class SendOfficeTrackingUpdate extends RouteEvent {
  final String routeId;
  final Map<String, dynamic> trackingData;

  const SendOfficeTrackingUpdate({
    required this.routeId,
    required this.trackingData,
  });

  @override
  List<Object?> get props => [routeId, trackingData];
}

class SendEmergencyAlert extends RouteEvent {
  final String driverId;
  final String routeId;
  final double latitude;
  final double longitude;
  final String? message;

  const SendEmergencyAlert({
    required this.driverId,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    this.message,
  });

  @override
  List<Object?> get props => [driverId, routeId, latitude, longitude, message];
}

class CreateManualRoute extends RouteEvent {
  final RouteModel route;

  const CreateManualRoute(this.route);

  @override
  List<Object?> get props => [route];
}

class NavigateToPickup extends RouteEvent {
  final String pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;

  const NavigateToPickup({
    required this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
  });

  @override
  List<Object?> get props => [pickupAddress, pickupLatitude, pickupLongitude];
}

// Time-tracked ride events
class StartNavigationToPickup extends RouteEvent {
  final String rideId;
  final DateTime timestamp;

  StartNavigationToPickup({required this.rideId, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [rideId, timestamp];
}

class ArrivedAtPickup extends RouteEvent {
  final String rideId;
  final DateTime timestamp;

  ArrivedAtPickup({required this.rideId, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [rideId, timestamp];
}

class PassengerPickedUp extends RouteEvent {
  final String rideId;
  final DateTime timestamp;

  PassengerPickedUp({required this.rideId, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [rideId, timestamp];
}

class StartNavigationToDestination extends RouteEvent {
  final String rideId;
  final DateTime timestamp;

  StartNavigationToDestination({required this.rideId, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [rideId, timestamp];
}

class ArrivedAtDestination extends RouteEvent {
  final String rideId;
  final DateTime timestamp;

  ArrivedAtDestination({required this.rideId, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [rideId, timestamp];
}

class CompleteRideWithTimestamp extends RouteEvent {
  final String rideId;
  final DateTime timestamp;
  final String? notes;

  CompleteRideWithTimestamp({
    required this.rideId,
    DateTime? timestamp,
    this.notes,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [rideId, timestamp, notes];
}

class CompleteManualRoute extends RouteEvent {
  final String routeId;
  final String? completionNotes;
  final DateTime completedAt;

  const CompleteManualRoute({
    required this.routeId,
    this.completionNotes,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [routeId, completionNotes, completedAt];
}

class CancelManualRoute extends RouteEvent {
  final String routeId;
  final String cancellationReason;
  final DateTime cancelledAt;

  const CancelManualRoute({
    required this.routeId,
    required this.cancellationReason,
    required this.cancelledAt,
  });

  @override
  List<Object?> get props => [routeId, cancellationReason, cancelledAt];
}

class LoadRideHistory extends RouteEvent {
  final String driverId;

  const LoadRideHistory(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class CancelIndividualRide extends RouteEvent {
  final String rideId;
  final String cancellationReason;
  final DateTime cancelledAt;

  const CancelIndividualRide({
    required this.rideId,
    required this.cancellationReason,
    required this.cancelledAt,
  });

  @override
  List<Object?> get props => [rideId, cancellationReason, cancelledAt];
}

class UpdateRideAddress extends RouteEvent {
  final String rideId;
  final String? newPickupAddress;
  final double? newPickupLatitude;
  final double? newPickupLongitude;
  final String? newDropOffAddress;
  final double? newDropOffLatitude;
  final double? newDropOffLongitude;

  const UpdateRideAddress({
    required this.rideId,
    this.newPickupAddress,
    this.newPickupLatitude,
    this.newPickupLongitude,
    this.newDropOffAddress,
    this.newDropOffLatitude,
    this.newDropOffLongitude,
  });

  @override
  List<Object?> get props => [
    rideId,
    newPickupAddress,
    newPickupLatitude,
    newPickupLongitude,
    newDropOffAddress,
    newDropOffLatitude,
    newDropOffLongitude,
  ];
}
