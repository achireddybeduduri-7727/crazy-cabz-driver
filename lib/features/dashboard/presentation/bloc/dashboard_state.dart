import 'package:equatable/equatable.dart';
import '../../../../shared/models/ride_model.dart';

class DashboardStats {
  final int todayRides;
  final double todayEarnings;
  final int weeklyRides;
  final double weeklyEarnings;
  final int totalRides;
  final double totalEarnings;
  final double rating;
  final int completedRides;
  final int cancelledRides;
  final Duration onlineTime;
  final double averageRideDistance;

  const DashboardStats({
    required this.todayRides,
    required this.todayEarnings,
    required this.weeklyRides,
    required this.weeklyEarnings,
    required this.totalRides,
    required this.totalEarnings,
    required this.rating,
    required this.completedRides,
    required this.cancelledRides,
    required this.onlineTime,
    required this.averageRideDistance,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todayRides: json['todayRides'] ?? 0,
      todayEarnings: (json['todayEarnings'] ?? 0.0).toDouble(),
      weeklyRides: json['weeklyRides'] ?? 0,
      weeklyEarnings: (json['weeklyEarnings'] ?? 0.0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      completedRides: json['completedRides'] ?? 0,
      cancelledRides: json['cancelledRides'] ?? 0,
      onlineTime: Duration(minutes: json['onlineTimeMinutes'] ?? 0),
      averageRideDistance: (json['averageRideDistance'] ?? 0.0).toDouble(),
    );
  }
}

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final RideModel? activeRide;
  final DashboardStats stats;
  final bool isDriverOnline;
  final List<RideModel> recentRides;
  final String driverStatus;

  const DashboardLoaded({
    this.activeRide,
    required this.stats,
    required this.isDriverOnline,
    required this.recentRides,
    required this.driverStatus,
  });

  @override
  List<Object?> get props => [
    activeRide,
    stats,
    isDriverOnline,
    recentRides,
    driverStatus,
  ];

  DashboardLoaded copyWith({
    RideModel? activeRide,
    DashboardStats? stats,
    bool? isDriverOnline,
    List<RideModel>? recentRides,
    String? driverStatus,
  }) {
    return DashboardLoaded(
      activeRide: activeRide ?? this.activeRide,
      stats: stats ?? this.stats,
      isDriverOnline: isDriverOnline ?? this.isDriverOnline,
      recentRides: recentRides ?? this.recentRides,
      driverStatus: driverStatus ?? this.driverStatus,
    );
  }
}

class DashboardError extends DashboardState {
  final String message;
  final String? errorCode;

  const DashboardError({required this.message, this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

class DashboardStatusUpdating extends DashboardState {
  final bool isGoingOnline;

  const DashboardStatusUpdating({required this.isGoingOnline});

  @override
  List<Object?> get props => [isGoingOnline];
}

class DashboardStatusUpdated extends DashboardState {
  final bool isOnline;
  final String message;

  const DashboardStatusUpdated({required this.isOnline, required this.message});

  @override
  List<Object?> get props => [isOnline, message];
}
