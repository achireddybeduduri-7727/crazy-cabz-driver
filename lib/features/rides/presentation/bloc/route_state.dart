import 'package:equatable/equatable.dart';
import '../../../../shared/models/route_model.dart';

abstract class RouteState extends Equatable {
  const RouteState();

  @override
  List<Object?> get props => [];
}

class RouteInitial extends RouteState {}

class RouteLoading extends RouteState {}

class RouteLoaded extends RouteState {
  final RouteModel? activeRoute;
  final List<RouteModel>? routeHistory;

  const RouteLoaded({this.activeRoute, this.routeHistory});

  @override
  List<Object?> get props => [activeRoute, routeHistory];

  RouteLoaded copyWith({
    RouteModel? activeRoute,
    List<RouteModel>? routeHistory,
  }) {
    return RouteLoaded(
      activeRoute: activeRoute ?? this.activeRoute,
      routeHistory: routeHistory ?? this.routeHistory,
    );
  }
}

class RouteUpdating extends RouteState {
  final RouteModel currentRoute;
  final String action;

  const RouteUpdating({required this.currentRoute, required this.action});

  @override
  List<Object?> get props => [currentRoute, action];
}

class RouteSuccess extends RouteState {
  final RouteModel route;
  final String message;

  const RouteSuccess({required this.route, required this.message});

  @override
  List<Object?> get props => [route, message];
}

class RouteError extends RouteState {
  final String message;
  final String? errorCode;

  const RouteError({required this.message, this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

class EmergencyAlertSent extends RouteState {
  final String message;

  const EmergencyAlertSent(this.message);

  @override
  List<Object?> get props => [message];
}

class OfficeTrackingUpdateSent extends RouteState {
  final String message;

  const OfficeTrackingUpdateSent(this.message);

  @override
  List<Object?> get props => [message];
}

// Individual ride status update states
class IndividualRideUpdated extends RouteState {
  final IndividualRide ride;
  final String message;

  const IndividualRideUpdated({required this.ride, required this.message});

  @override
  List<Object?> get props => [ride, message];
}

class PassengerPresenceUpdated extends RouteState {
  final IndividualRide ride;
  final String message;

  const PassengerPresenceUpdated({required this.ride, required this.message});

  @override
  List<Object?> get props => [ride, message];
}

class NavigationLaunched extends RouteState {
  final String address;
  final String message;

  const NavigationLaunched({required this.address, required this.message});

  @override
  List<Object?> get props => [address, message];
}

class RouteCompleted extends RouteState {
  final RouteModel route;
  final String message;
  final DateTime completedAt;

  const RouteCompleted({
    required this.route,
    required this.message,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [route, message, completedAt];
}

class RouteCancelled extends RouteState {
  final RouteModel route;
  final String message;
  final String reason;
  final DateTime cancelledAt;

  const RouteCancelled({
    required this.route,
    required this.message,
    required this.reason,
    required this.cancelledAt,
  });

  @override
  List<Object?> get props => [route, message, reason, cancelledAt];
}

class RideHistoryLoaded extends RouteState {
  final List<RouteModel> historyRoutes;
  final int totalCount;

  const RideHistoryLoaded({
    required this.historyRoutes,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [historyRoutes, totalCount];
}

class ActiveRouteLoaded extends RouteState {
  final RouteModel? activeRoute;
  final String message;

  const ActiveRouteLoaded({this.activeRoute, required this.message});

  @override
  List<Object?> get props => [activeRoute, message];
}
