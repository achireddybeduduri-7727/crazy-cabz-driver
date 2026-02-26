import 'package:hive/hive.dart';

part 'ride_model.g.dart';

enum RideStatus { assigned, enRoute, arrived, inProgress, completed, cancelled }

@HiveType(typeId: 3)
class RideModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String driverId;

  @HiveField(2)
  String employeeName;

  @HiveField(3)
  String employeePhone;

  @HiveField(4)
  LocationInfo pickupLocation;

  @HiveField(5)
  LocationInfo dropLocation;

  @HiveField(6)
  double fare;

  @HiveField(7)
  String status;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime? startedAt;

  @HiveField(10)
  DateTime? arrivedAt;

  @HiveField(11)
  DateTime? pickedUpAt;

  @HiveField(12)
  DateTime? completedAt;

  @HiveField(13)
  List<LocationPoint>? trackingPoints;

  @HiveField(14)
  double? distance;

  @HiveField(15)
  int? duration; // in minutes

  @HiveField(16)
  String? notes;

  RideModel({
    required this.id,
    required this.driverId,
    required this.employeeName,
    required this.employeePhone,
    required this.pickupLocation,
    required this.dropLocation,
    required this.fare,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.arrivedAt,
    this.pickedUpAt,
    this.completedAt,
    this.trackingPoints,
    this.distance,
    this.duration,
    this.notes,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      employeePhone: json['employeePhone'] ?? '',
      pickupLocation: LocationInfo.fromJson(json['pickupLocation'] ?? {}),
      dropLocation: LocationInfo.fromJson(json['dropLocation'] ?? {}),
      fare: (json['fare'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      arrivedAt: json['arrivedAt'] != null
          ? DateTime.parse(json['arrivedAt'])
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      trackingPoints: (json['trackingPoints'] as List?)
          ?.map((e) => LocationPoint.fromJson(e))
          .toList(),
      distance: json['distance']?.toDouble(),
      duration: json['duration'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'employeeName': employeeName,
      'employeePhone': employeePhone,
      'pickupLocation': pickupLocation.toJson(),
      'dropLocation': dropLocation.toJson(),
      'fare': fare,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'arrivedAt': arrivedAt?.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'trackingPoints': trackingPoints?.map((e) => e.toJson()).toList(),
      'distance': distance,
      'duration': duration,
      'notes': notes,
    };
  }

  RideModel copyWith({
    String? id,
    String? driverId,
    String? employeeName,
    String? employeePhone,
    LocationInfo? pickupLocation,
    LocationInfo? dropLocation,
    double? fare,
    String? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? arrivedAt,
    DateTime? pickedUpAt,
    DateTime? completedAt,
    List<LocationPoint>? trackingPoints,
    double? distance,
    int? duration,
    String? notes,
  }) {
    return RideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      employeeName: employeeName ?? this.employeeName,
      employeePhone: employeePhone ?? this.employeePhone,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      fare: fare ?? this.fare,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      completedAt: completedAt ?? this.completedAt,
      trackingPoints: trackingPoints ?? this.trackingPoints,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
    );
  }
}

@HiveType(typeId: 4)
class LocationInfo extends HiveObject {
  @HiveField(0)
  double latitude;

  @HiveField(1)
  double longitude;

  @HiveField(2)
  String address;

  @HiveField(3)
  String? landmark;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      landmark: json['landmark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'landmark': landmark,
    };
  }

  LocationInfo copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? landmark,
  }) {
    return LocationInfo(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
    );
  }
}

@HiveType(typeId: 5)
class LocationPoint extends HiveObject {
  @HiveField(0)
  double latitude;

  @HiveField(1)
  double longitude;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  double? speed;

  @HiveField(4)
  double? bearing;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.bearing,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      speed: json['speed']?.toDouble(),
      bearing: json['bearing']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'bearing': bearing,
    };
  }
}
