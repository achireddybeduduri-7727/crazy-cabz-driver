import 'package:equatable/equatable.dart';
import 'passenger_model.dart';
import 'ride_model.dart';

enum RouteType { morning, evening }

enum RouteStatus { scheduled, started, inProgress, completed, cancelled }

class RouteModel extends Equatable {
  final String id;
  final String driverId;
  final RouteType type;
  final RouteStatus status;
  final DateTime scheduledTime;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String officeAddress;
  final double officeLatitude;
  final double officeLongitude;
  final List<IndividualRide> rides;
  final List<LocationPoint> routeTrackingPoints;
  final double? totalDistance;
  final int? totalDuration;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RouteModel({
    required this.id,
    required this.driverId,
    required this.type,
    required this.status,
    required this.scheduledTime,
    this.startedAt,
    this.completedAt,
    required this.officeAddress,
    required this.officeLatitude,
    required this.officeLongitude,
    required this.rides,
    this.routeTrackingPoints = const [],
    this.totalDistance,
    this.totalDuration,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      type: RouteType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RouteType.morning,
      ),
      status: RouteStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RouteStatus.scheduled,
      ),
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      officeAddress: json['office_address'] as String,
      officeLatitude: (json['office_latitude'] as num).toDouble(),
      officeLongitude: (json['office_longitude'] as num).toDouble(),
      rides: (json['rides'] as List<dynamic>)
          .map((rideJson) => IndividualRide.fromJson(rideJson))
          .toList(),
      routeTrackingPoints: json['route_tracking_points'] != null
          ? (json['route_tracking_points'] as List<dynamic>)
                .map((pointJson) => LocationPoint.fromJson(pointJson))
                .toList()
          : [],
      totalDistance: json['total_distance'] != null
          ? (json['total_distance'] as num).toDouble()
          : null,
      totalDuration: json['total_duration'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'type': type.name,
      'status': status.name,
      'scheduled_time': scheduledTime.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'office_address': officeAddress,
      'office_latitude': officeLatitude,
      'office_longitude': officeLongitude,
      'rides': rides.map((ride) => ride.toJson()).toList(),
      'route_tracking_points': routeTrackingPoints
          .map((point) => point.toJson())
          .toList(),
      'total_distance': totalDistance,
      'total_duration': totalDuration,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  RouteModel copyWith({
    String? id,
    String? driverId,
    RouteType? type,
    RouteStatus? status,
    DateTime? scheduledTime,
    DateTime? startedAt,
    DateTime? completedAt,
    String? officeAddress,
    double? officeLatitude,
    double? officeLongitude,
    List<IndividualRide>? rides,
    List<LocationPoint>? routeTrackingPoints,
    double? totalDistance,
    int? totalDuration,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RouteModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      officeAddress: officeAddress ?? this.officeAddress,
      officeLatitude: officeLatitude ?? this.officeLatitude,
      officeLongitude: officeLongitude ?? this.officeLongitude,
      rides: rides ?? this.rides,
      routeTrackingPoints: routeTrackingPoints ?? this.routeTrackingPoints,
      totalDistance: totalDistance ?? this.totalDistance,
      totalDuration: totalDuration ?? this.totalDuration,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  int get totalPassengers => rides.length;

  int get completedRides => rides
      .where((ride) => ride.status == IndividualRideStatus.completed)
      .length;

  int get pendingRides => rides
      .where(
        (ride) =>
            ride.status == IndividualRideStatus.scheduled ||
            ride.status == IndividualRideStatus.enRoute,
      )
      .length;

  bool get isComplete =>
      rides.every((ride) => ride.status == IndividualRideStatus.completed);

  List<IndividualRide> get nextRides => rides
      .where(
        (ride) =>
            ride.status == IndividualRideStatus.scheduled ||
            ride.status == IndividualRideStatus.enRoute,
      )
      .toList();

  @override
  List<Object?> get props => [
    id,
    driverId,
    type,
    status,
    scheduledTime,
    startedAt,
    completedAt,
    officeAddress,
    officeLatitude,
    officeLongitude,
    rides,
    routeTrackingPoints,
    totalDistance,
    totalDuration,
    notes,
    createdAt,
    updatedAt,
  ];
}

enum IndividualRideStatus {
  scheduled,
  enRoute,
  arrived,
  pickedUp,
  completed,
  cancelled,
}

enum TimelineEventType {
  navigatedToPickup,
  arrivedAtPickup,
  passengerPickedUp,
  navigatedToDestination,
  arrivedAtDestination,
  rideCompleted,
}

class RideTimelineEvent extends Equatable {
  final TimelineEventType type;
  final DateTime timestamp;
  final String description;
  final int? duration; // Duration in minutes from previous event

  const RideTimelineEvent({
    required this.type,
    required this.timestamp,
    required this.description,
    this.duration,
  });

  @override
  List<Object?> get props => [type, timestamp, description, duration];

  String get formattedTime {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }

  String get formattedDuration {
    if (duration == null) return '';
    if (duration! < 60) return '${duration}m';
    final hours = duration! ~/ 60;
    final minutes = duration! % 60;
    return '${hours}h ${minutes}m';
  }
}

class IndividualRide extends Equatable {
  final String id;
  final String routeId;
  final PassengerModel passenger;
  final IndividualRideStatus status;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropOffAddress;
  final double dropOffLatitude;
  final double dropOffLongitude;
  final DateTime? scheduledPickupTime;
  final DateTime? actualPickupTime;
  final DateTime? scheduledDropOffTime;
  final DateTime? actualDropOffTime;

  // Detailed time tracking for each action
  final DateTime?
  navigatedToPickupAt; // When driver pressed "Navigate to Pickup"
  final DateTime? arrivedAtPickupAt; // When driver pressed "Arrived at Pickup"
  final DateTime? passengerPickedUpAt; // When passenger was picked up
  final DateTime?
  navigatedToDestinationAt; // When driver pressed "Navigate to Destination"
  final DateTime? arrivedAtDestinationAt; // When driver reached destination
  final DateTime? rideCompletedAt; // When ride was completed

  final int routeOrder;
  final double? distance;
  final int? duration;
  final List<LocationPoint> trackingPoints;
  final String? passengerNotes;
  final bool isPresent;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const IndividualRide({
    required this.id,
    required this.routeId,
    required this.passenger,
    required this.status,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropOffAddress,
    required this.dropOffLatitude,
    required this.dropOffLongitude,
    this.scheduledPickupTime,
    this.actualPickupTime,
    this.scheduledDropOffTime,
    this.actualDropOffTime,

    // Time tracking fields
    this.navigatedToPickupAt,
    this.arrivedAtPickupAt,
    this.passengerPickedUpAt,
    this.navigatedToDestinationAt,
    this.arrivedAtDestinationAt,
    this.rideCompletedAt,

    required this.routeOrder,
    this.distance,
    this.duration,
    this.trackingPoints = const [],
    this.passengerNotes,
    this.isPresent = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory IndividualRide.fromJson(Map<String, dynamic> json) {
    return IndividualRide(
      id: json['id'] as String,
      routeId: json['route_id'] as String,
      passenger: PassengerModel.fromJson(json['passenger']),
      status: IndividualRideStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => IndividualRideStatus.scheduled,
      ),
      pickupAddress: json['pickup_address'] as String,
      pickupLatitude: (json['pickup_latitude'] as num).toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num).toDouble(),
      dropOffAddress: json['drop_off_address'] as String,
      dropOffLatitude: (json['drop_off_latitude'] as num).toDouble(),
      dropOffLongitude: (json['drop_off_longitude'] as num).toDouble(),
      scheduledPickupTime: json['scheduled_pickup_time'] != null
          ? DateTime.parse(json['scheduled_pickup_time'] as String)
          : null,
      actualPickupTime: json['actual_pickup_time'] != null
          ? DateTime.parse(json['actual_pickup_time'] as String)
          : null,
      scheduledDropOffTime: json['scheduled_drop_off_time'] != null
          ? DateTime.parse(json['scheduled_drop_off_time'] as String)
          : null,
      actualDropOffTime: json['actual_drop_off_time'] != null
          ? DateTime.parse(json['actual_drop_off_time'] as String)
          : null,

      // Time tracking fields
      navigatedToPickupAt: json['navigated_to_pickup_at'] != null
          ? DateTime.parse(json['navigated_to_pickup_at'] as String)
          : null,
      arrivedAtPickupAt: json['arrived_at_pickup_at'] != null
          ? DateTime.parse(json['arrived_at_pickup_at'] as String)
          : null,
      passengerPickedUpAt: json['passenger_picked_up_at'] != null
          ? DateTime.parse(json['passenger_picked_up_at'] as String)
          : null,
      navigatedToDestinationAt: json['navigated_to_destination_at'] != null
          ? DateTime.parse(json['navigated_to_destination_at'] as String)
          : null,
      arrivedAtDestinationAt: json['arrived_at_destination_at'] != null
          ? DateTime.parse(json['arrived_at_destination_at'] as String)
          : null,
      rideCompletedAt: json['ride_completed_at'] != null
          ? DateTime.parse(json['ride_completed_at'] as String)
          : null,

      routeOrder: json['route_order'] as int,
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
      duration: json['duration'] as int?,
      trackingPoints: json['tracking_points'] != null
          ? (json['tracking_points'] as List<dynamic>)
                .map((pointJson) => LocationPoint.fromJson(pointJson))
                .toList()
          : [],
      passengerNotes: json['passenger_notes'] as String?,
      isPresent: json['is_present'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_id': routeId,
      'passenger': passenger.toJson(),
      'status': status.name,
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'drop_off_address': dropOffAddress,
      'drop_off_latitude': dropOffLatitude,
      'drop_off_longitude': dropOffLongitude,
      'scheduled_pickup_time': scheduledPickupTime?.toIso8601String(),
      'actual_pickup_time': actualPickupTime?.toIso8601String(),
      'scheduled_drop_off_time': scheduledDropOffTime?.toIso8601String(),
      'actual_drop_off_time': actualDropOffTime?.toIso8601String(),

      // Time tracking fields
      'navigated_to_pickup_at': navigatedToPickupAt?.toIso8601String(),
      'arrived_at_pickup_at': arrivedAtPickupAt?.toIso8601String(),
      'passenger_picked_up_at': passengerPickedUpAt?.toIso8601String(),
      'navigated_to_destination_at': navigatedToDestinationAt
          ?.toIso8601String(),
      'arrived_at_destination_at': arrivedAtDestinationAt?.toIso8601String(),
      'ride_completed_at': rideCompletedAt?.toIso8601String(),

      'route_order': routeOrder,
      'distance': distance,
      'duration': duration,
      'tracking_points': trackingPoints.map((point) => point.toJson()).toList(),
      'passenger_notes': passengerNotes,
      'is_present': isPresent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  IndividualRide copyWith({
    String? id,
    String? routeId,
    PassengerModel? passenger,
    IndividualRideStatus? status,
    String? pickupAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    String? dropOffAddress,
    double? dropOffLatitude,
    double? dropOffLongitude,
    DateTime? scheduledPickupTime,
    DateTime? actualPickupTime,
    DateTime? scheduledDropOffTime,
    DateTime? actualDropOffTime,

    // Time tracking fields
    DateTime? navigatedToPickupAt,
    DateTime? arrivedAtPickupAt,
    DateTime? passengerPickedUpAt,
    DateTime? navigatedToDestinationAt,
    DateTime? arrivedAtDestinationAt,
    DateTime? rideCompletedAt,

    int? routeOrder,
    double? distance,
    int? duration,
    List<LocationPoint>? trackingPoints,
    String? passengerNotes,
    bool? isPresent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IndividualRide(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      passenger: passenger ?? this.passenger,
      status: status ?? this.status,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      dropOffAddress: dropOffAddress ?? this.dropOffAddress,
      dropOffLatitude: dropOffLatitude ?? this.dropOffLatitude,
      dropOffLongitude: dropOffLongitude ?? this.dropOffLongitude,
      scheduledPickupTime: scheduledPickupTime ?? this.scheduledPickupTime,
      actualPickupTime: actualPickupTime ?? this.actualPickupTime,
      scheduledDropOffTime: scheduledDropOffTime ?? this.scheduledDropOffTime,
      actualDropOffTime: actualDropOffTime ?? this.actualDropOffTime,

      // Time tracking fields
      navigatedToPickupAt: navigatedToPickupAt ?? this.navigatedToPickupAt,
      arrivedAtPickupAt: arrivedAtPickupAt ?? this.arrivedAtPickupAt,
      passengerPickedUpAt: passengerPickedUpAt ?? this.passengerPickedUpAt,
      navigatedToDestinationAt:
          navigatedToDestinationAt ?? this.navigatedToDestinationAt,
      arrivedAtDestinationAt:
          arrivedAtDestinationAt ?? this.arrivedAtDestinationAt,
      rideCompletedAt: rideCompletedAt ?? this.rideCompletedAt,

      routeOrder: routeOrder ?? this.routeOrder,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      trackingPoints: trackingPoints ?? this.trackingPoints,
      passengerNotes: passengerNotes ?? this.passengerNotes,
      isPresent: isPresent ?? this.isPresent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    routeId,
    passenger,
    status,
    pickupAddress,
    pickupLatitude,
    pickupLongitude,
    dropOffAddress,
    dropOffLatitude,
    dropOffLongitude,
    scheduledPickupTime,
    actualPickupTime,
    scheduledDropOffTime,
    actualDropOffTime,
    navigatedToPickupAt,
    arrivedAtPickupAt,
    passengerPickedUpAt,
    navigatedToDestinationAt,
    arrivedAtDestinationAt,
    rideCompletedAt,
    routeOrder,
    distance,
    duration,
    trackingPoints,
    passengerNotes,
    isPresent,
    createdAt,
    updatedAt,
  ];

  // Timeline calculation methods

  /// Duration from navigation to pickup until arrival at pickup (in minutes)
  int? get navigationToPickupDuration {
    if (navigatedToPickupAt == null || arrivedAtPickupAt == null) return null;
    return arrivedAtPickupAt!.difference(navigatedToPickupAt!).inMinutes;
  }

  /// Duration waiting at pickup location (in minutes)
  int? get waitingAtPickupDuration {
    if (arrivedAtPickupAt == null || passengerPickedUpAt == null) return null;
    return passengerPickedUpAt!.difference(arrivedAtPickupAt!).inMinutes;
  }

  /// Duration from pickup to destination navigation (in minutes)
  int? get navigationToDestinationDuration {
    if (navigatedToDestinationAt == null || arrivedAtDestinationAt == null) {
      return null;
    }
    return arrivedAtDestinationAt!
        .difference(navigatedToDestinationAt!)
        .inMinutes;
  }

  /// Total ride duration from start to completion (in minutes)
  int? get totalRideDuration {
    if (navigatedToPickupAt == null || rideCompletedAt == null) return null;
    return rideCompletedAt!.difference(navigatedToPickupAt!).inMinutes;
  }

  /// Get ride timeline as a list of timeline events
  List<RideTimelineEvent> get timeline {
    List<RideTimelineEvent> events = [];

    if (navigatedToPickupAt != null) {
      events.add(
        RideTimelineEvent(
          type: TimelineEventType.navigatedToPickup,
          timestamp: navigatedToPickupAt!,
          description: 'Started navigation to pickup location',
        ),
      );
    }

    if (arrivedAtPickupAt != null) {
      events.add(
        RideTimelineEvent(
          type: TimelineEventType.arrivedAtPickup,
          timestamp: arrivedAtPickupAt!,
          description: 'Arrived at pickup location',
          duration: navigationToPickupDuration,
        ),
      );
    }

    if (passengerPickedUpAt != null) {
      events.add(
        RideTimelineEvent(
          type: TimelineEventType.passengerPickedUp,
          timestamp: passengerPickedUpAt!,
          description: 'Passenger picked up',
          duration: waitingAtPickupDuration,
        ),
      );
    }

    if (navigatedToDestinationAt != null) {
      events.add(
        RideTimelineEvent(
          type: TimelineEventType.navigatedToDestination,
          timestamp: navigatedToDestinationAt!,
          description: 'Started navigation to destination',
        ),
      );
    }

    if (arrivedAtDestinationAt != null) {
      events.add(
        RideTimelineEvent(
          type: TimelineEventType.arrivedAtDestination,
          timestamp: arrivedAtDestinationAt!,
          description: 'Arrived at destination',
          duration: navigationToDestinationDuration,
        ),
      );
    }

    // Note: Removed 'rideCompleted' event from timeline as per user request
    // Ride completion is tracked via status, not timeline events

    return events;
  }

  /// Check if ride has complete timeline data
  bool get hasCompleteTimeline {
    return navigatedToPickupAt != null &&
        arrivedAtPickupAt != null &&
        passengerPickedUpAt != null &&
        navigatedToDestinationAt != null &&
        arrivedAtDestinationAt != null &&
        rideCompletedAt != null;
  }
}
