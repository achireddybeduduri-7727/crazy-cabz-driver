import 'package:equatable/equatable.dart';
import '../../../../shared/models/ride_model.dart';

abstract class RideState extends Equatable {
  const RideState();

  @override
  List<Object?> get props => [];
}

class RideInitial extends RideState {}

class RideLoading extends RideState {}

class RideLoaded extends RideState {
  final RideModel? activeRide;
  final List<RideModel>? rideHistory;
  final List<LocationPoint>? trackingPoints;

  const RideLoaded({this.activeRide, this.rideHistory, this.trackingPoints});

  @override
  List<Object?> get props => [activeRide, rideHistory, trackingPoints];

  RideLoaded copyWith({
    RideModel? activeRide,
    List<RideModel>? rideHistory,
    List<LocationPoint>? trackingPoints,
  }) {
    return RideLoaded(
      activeRide: activeRide ?? this.activeRide,
      rideHistory: rideHistory ?? this.rideHistory,
      trackingPoints: trackingPoints ?? this.trackingPoints,
    );
  }
}

class RideUpdating extends RideState {
  final RideModel currentRide;
  final String action;

  const RideUpdating({required this.currentRide, required this.action});

  @override
  List<Object?> get props => [currentRide, action];
}

class RideSuccess extends RideState {
  final RideModel ride;
  final String message;

  const RideSuccess({required this.ride, required this.message});

  @override
  List<Object?> get props => [ride, message];
}

class RideError extends RideState {
  final String message;
  final String? errorCode;

  const RideError({required this.message, this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

class EmergencyAlertSent extends RideState {
  final String message;

  const EmergencyAlertSent(this.message);

  @override
  List<Object?> get props => [message];
}

// Helper states for specific ride flow actions
class RideActionState extends RideState {
  final String rideId;
  final String action;
  final bool isLoading;
  final String? errorMessage;

  const RideActionState({
    required this.rideId,
    required this.action,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [rideId, action, isLoading, errorMessage];
}

class TrackingState extends RideState {
  final String rideId;
  final LocationPoint currentLocation;
  final List<LocationPoint> route;
  final double totalDistance;
  final int duration;

  const TrackingState({
    required this.rideId,
    required this.currentLocation,
    required this.route,
    required this.totalDistance,
    required this.duration,
  });

  @override
  List<Object?> get props => [
    rideId,
    currentLocation,
    route,
    totalDistance,
    duration,
  ];
}
