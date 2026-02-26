import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {
  final String driverId;

  const LoadDashboardData(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class RefreshDashboard extends DashboardEvent {
  final String driverId;

  const RefreshDashboard(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class UpdateDriverStatusOnline extends DashboardEvent {
  final String driverId;

  const UpdateDriverStatusOnline(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class UpdateDriverStatusOffline extends DashboardEvent {
  final String driverId;

  const UpdateDriverStatusOffline(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class LoadTodayStats extends DashboardEvent {
  final String driverId;

  const LoadTodayStats(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class LoadWeeklyStats extends DashboardEvent {
  final String driverId;

  const LoadWeeklyStats(this.driverId);

  @override
  List<Object?> get props => [driverId];
}
