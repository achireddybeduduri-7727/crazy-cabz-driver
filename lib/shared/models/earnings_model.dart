class EarningsModel {
  String id;
  String rideId;
  String driverId;
  double baseFare;
  double distanceFare;
  double timeFare;
  double surgeFare;
  double tips;
  double tolls;
  double totalFare;
  double platformFee;
  double netEarnings;
  DateTime earnedAt;
  String paymentStatus; // pending, paid, cancelled
  String rideType; // regular, express, premium
  double distance; // in kilometers
  int duration; // in minutes
  String customerName;
  String pickupAddress;
  String dropAddress;

  EarningsModel({
    required this.id,
    required this.rideId,
    required this.driverId,
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgeFare,
    required this.tips,
    required this.tolls,
    required this.totalFare,
    required this.platformFee,
    required this.netEarnings,
    required this.earnedAt,
    required this.paymentStatus,
    required this.rideType,
    required this.distance,
    required this.duration,
    required this.customerName,
    required this.pickupAddress,
    required this.dropAddress,
  });

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      id: json['id'] ?? '',
      rideId: json['rideId'] ?? '',
      driverId: json['driverId'] ?? '',
      baseFare: (json['baseFare'] ?? 0.0).toDouble(),
      distanceFare: (json['distanceFare'] ?? 0.0).toDouble(),
      timeFare: (json['timeFare'] ?? 0.0).toDouble(),
      surgeFare: (json['surgeFare'] ?? 0.0).toDouble(),
      tips: (json['tips'] ?? 0.0).toDouble(),
      tolls: (json['tolls'] ?? 0.0).toDouble(),
      totalFare: (json['totalFare'] ?? 0.0).toDouble(),
      platformFee: (json['platformFee'] ?? 0.0).toDouble(),
      netEarnings: (json['netEarnings'] ?? 0.0).toDouble(),
      earnedAt: DateTime.parse(
        json['earnedAt'] ?? DateTime.now().toIso8601String(),
      ),
      paymentStatus: json['paymentStatus'] ?? 'pending',
      rideType: json['rideType'] ?? 'regular',
      distance: (json['distance'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? 0,
      customerName: json['customerName'] ?? '',
      pickupAddress: json['pickupAddress'] ?? '',
      dropAddress: json['dropAddress'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'driverId': driverId,
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'surgeFare': surgeFare,
      'tips': tips,
      'tolls': tolls,
      'totalFare': totalFare,
      'platformFee': platformFee,
      'netEarnings': netEarnings,
      'earnedAt': earnedAt.toIso8601String(),
      'paymentStatus': paymentStatus,
      'rideType': rideType,
      'distance': distance,
      'duration': duration,
      'customerName': customerName,
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
    };
  }

  EarningsModel copyWith({
    String? id,
    String? rideId,
    String? driverId,
    double? baseFare,
    double? distanceFare,
    double? timeFare,
    double? surgeFare,
    double? tips,
    double? tolls,
    double? totalFare,
    double? platformFee,
    double? netEarnings,
    DateTime? earnedAt,
    String? paymentStatus,
    String? rideType,
    double? distance,
    int? duration,
    String? customerName,
    String? pickupAddress,
    String? dropAddress,
  }) {
    return EarningsModel(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      baseFare: baseFare ?? this.baseFare,
      distanceFare: distanceFare ?? this.distanceFare,
      timeFare: timeFare ?? this.timeFare,
      surgeFare: surgeFare ?? this.surgeFare,
      tips: tips ?? this.tips,
      tolls: tolls ?? this.tolls,
      totalFare: totalFare ?? this.totalFare,
      platformFee: platformFee ?? this.platformFee,
      netEarnings: netEarnings ?? this.netEarnings,
      earnedAt: earnedAt ?? this.earnedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rideType: rideType ?? this.rideType,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      customerName: customerName ?? this.customerName,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropAddress: dropAddress ?? this.dropAddress,
    );
  }
}

class EarningsSummary {
  DateTime date;
  double totalEarnings;
  double netEarnings;
  double platformFees;
  double tips;
  int totalRides;
  double totalDistance;
  int totalTime; // in minutes
  double avgRating;

  EarningsSummary({
    required this.date,
    required this.totalEarnings,
    required this.netEarnings,
    required this.platformFees,
    required this.tips,
    required this.totalRides,
    required this.totalDistance,
    required this.totalTime,
    required this.avgRating,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      netEarnings: (json['netEarnings'] ?? 0.0).toDouble(),
      platformFees: (json['platformFees'] ?? 0.0).toDouble(),
      tips: (json['tips'] ?? 0.0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      totalDistance: (json['totalDistance'] ?? 0.0).toDouble(),
      totalTime: json['totalTime'] ?? 0,
      avgRating: (json['avgRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalEarnings': totalEarnings,
      'netEarnings': netEarnings,
      'platformFees': platformFees,
      'tips': tips,
      'totalRides': totalRides,
      'totalDistance': totalDistance,
      'totalTime': totalTime,
      'avgRating': avgRating,
    };
  }
}
