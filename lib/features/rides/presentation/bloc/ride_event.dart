import 'package:equatable/equatable.dart';
import '../../../../shared/models/ride_model.dart';

abstract class RideEvent extends Equatable {
  const RideEvent();

  @override
  List<Object?> get props => [];
}

class LoadActiveRide extends RideEvent {
  final String driverId;

  const LoadActiveRide(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class CreateRide extends RideEvent {
  final RideModel ride;

  const CreateRide(this.ride);

  @override
  List<Object?> get props => [ride];
}

class UpdateRideStatus extends RideEvent {
  final String rideId;
  final String status;
  final Map<String, dynamic>? additionalData;

  const UpdateRideStatus({
    required this.rideId,
    required this.status,
    this.additionalData,
  });

  @override
  List<Object?> get props => [rideId, status, additionalData];
}

class StartPickup extends RideEvent {
  final String rideId;

  const StartPickup(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class MarkArrived extends RideEvent {
  final String rideId;

  const MarkArrived(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class PickupCustomer extends RideEvent {
  final String rideId;

  const PickupCustomer(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class EndRide extends RideEvent {
  final String rideId;
  final String? notes;

  const EndRide({required this.rideId, this.notes});

  @override
  List<Object?> get props => [rideId, notes];
}

class CancelRide extends RideEvent {
  final String rideId;
  final String reason;

  const CancelRide({required this.rideId, required this.reason});

  @override
  List<Object?> get props => [rideId, reason];
}

class AddTrackingPoint extends RideEvent {
  final String rideId;
  final LocationPoint locationPoint;

  const AddTrackingPoint({required this.rideId, required this.locationPoint});

  @override
  List<Object?> get props => [rideId, locationPoint];
}

class LoadRideHistory extends RideEvent {
  final String driverId;
  final int page;
  final int limit;

  const LoadRideHistory({
    required this.driverId,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [driverId, page, limit];
}

class SendEmergencyAlert extends RideEvent {
  final String driverId;
  final String rideId;
  final double latitude;
  final double longitude;
  final String? message;

  const SendEmergencyAlert({
    required this.driverId,
    required this.rideId,
    required this.latitude,
    required this.longitude,
    this.message,
  });

  @override
  List<Object?> get props => [driverId, rideId, latitude, longitude, message];
}
