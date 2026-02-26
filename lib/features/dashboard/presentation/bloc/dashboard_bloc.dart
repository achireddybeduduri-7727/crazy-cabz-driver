import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/dashboard_use_case.dart';
import '../../../../shared/models/ride_model.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardUseCase _dashboardUseCase = DashboardUseCase();
  final LocationService _locationService = LocationService();

  Timer? _locationUpdateTimer;
  String? _currentDriverId;

  DashboardBloc() : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboard>(_onRefreshDashboard);
    on<UpdateDriverStatusOnline>(_onUpdateDriverStatusOnline);
    on<UpdateDriverStatusOffline>(_onUpdateDriverStatusOffline);
    on<LoadTodayStats>(_onLoadTodayStats);
    on<LoadWeeklyStats>(_onLoadWeeklyStats);
  }

  @override
  Future<void> close() {
    _locationUpdateTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    _currentDriverId = event.driverId;

    try {
      // Load all dashboard data in parallel
      final futures = await Future.wait([
        _dashboardUseCase.getDashboardStats(driverId: event.driverId),
        _dashboardUseCase.getActiveRide(driverId: event.driverId),
        _dashboardUseCase.getRecentRides(driverId: event.driverId, limit: 5),
      ]);

      final stats = futures[0] as DashboardStats;
      final activeRide = futures[1] as RideModel?;
      final recentRides = futures[2] as List<RideModel>;

      emit(
        DashboardLoaded(
          stats: stats,
          activeRide: activeRide,
          recentRides: recentRides,
          isDriverOnline: true, // Default to true, should be fetched from API
          driverStatus: 'online',
        ),
      );

      // Start location updates if driver is online
      _startLocationUpdates();
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;

    try {
      final currentState = state as DashboardLoaded;

      // Refresh data without showing loading state
      final futures = await Future.wait([
        _dashboardUseCase.getDashboardStats(driverId: event.driverId),
        _dashboardUseCase.getActiveRide(driverId: event.driverId),
        _dashboardUseCase.getRecentRides(driverId: event.driverId, limit: 5),
      ]);

      final stats = futures[0] as DashboardStats;
      final activeRide = futures[1] as RideModel?;
      final recentRides = futures[2] as List<RideModel>;

      emit(
        currentState.copyWith(
          stats: stats,
          activeRide: activeRide,
          recentRides: recentRides,
        ),
      );
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _onUpdateDriverStatusOnline(
    UpdateDriverStatusOnline event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardStatusUpdating(isGoingOnline: true));

    try {
      final success = await _dashboardUseCase.updateDriverStatus(
        driverId: event.driverId,
        isOnline: true,
      );

      if (success) {
        emit(
          const DashboardStatusUpdated(
            isOnline: true,
            message: 'You are now online and available for rides',
          ),
        );

        // Start location updates
        _startLocationUpdates();

        // Reload dashboard data - temporarily disabled while backend is unavailable
        // add(LoadDashboardData(event.driverId));
      } else {
        emit(
          const DashboardError(
            message: 'Failed to go online. Please try again.',
          ),
        );
      }
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _onUpdateDriverStatusOffline(
    UpdateDriverStatusOffline event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardStatusUpdating(isGoingOnline: false));

    try {
      final success = await _dashboardUseCase.updateDriverStatus(
        driverId: event.driverId,
        isOnline: false,
      );

      if (success) {
        emit(
          const DashboardStatusUpdated(
            isOnline: false,
            message: 'You are now offline',
          ),
        );

        // Stop location updates
        _stopLocationUpdates();

        // Reload dashboard data - temporarily disabled while backend is unavailable
        // add(LoadDashboardData(event.driverId));
      } else {
        emit(
          const DashboardError(
            message: 'Failed to go offline. Please try again.',
          ),
        );
      }
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _onLoadTodayStats(
    LoadTodayStats event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;

    try {
      final currentState = state as DashboardLoaded;
      final todayStats = await _dashboardUseCase.getTodayStats(
        driverId: event.driverId,
      );

      emit(currentState.copyWith(stats: todayStats));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _onLoadWeeklyStats(
    LoadWeeklyStats event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;

    try {
      final currentState = state as DashboardLoaded;
      final weeklyStats = await _dashboardUseCase.getWeeklyStats(
        driverId: event.driverId,
      );

      emit(currentState.copyWith(stats: weeklyStats));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 2), (
      timer,
    ) async {
      if (_currentDriverId != null) {
        try {
          final position = await _locationService.getCurrentPosition();
          if (position != null) {
            await _dashboardUseCase.updateDriverLocation(
              driverId: _currentDriverId!,
              latitude: position.latitude,
              longitude: position.longitude,
            );
          }
        } catch (e) {
          print('Error updating driver location: $e');
        }
      }
    });
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  // Getters for dashboard state
  bool get isOnline {
    final currentState = state;
    if (currentState is DashboardLoaded) {
      return currentState.isDriverOnline;
    }
    return false;
  }

  DashboardStats? get currentStats {
    final currentState = state;
    if (currentState is DashboardLoaded) {
      return currentState.stats;
    }
    return null;
  }

  bool get hasActiveRide {
    final currentState = state;
    if (currentState is DashboardLoaded) {
      return currentState.activeRide != null;
    }
    return false;
  }
}
