import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/ride_use_case.dart';
import '../../../../shared/models/ride_model.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/save_active_ride.dart';
import 'ride_event.dart';
import 'ride_state.dart';

class RideBloc extends Bloc<RideEvent, RideState> {
  final RideUseCase _rideUseCase = RideUseCase();
  final LocationService _locationService = LocationService();
  final SaveActiveRide _saveActiveRide = SaveActiveRide();

  RideModel? _currentRide;
  Timer? _trackingTimer;
  final List<LocationPoint> _currentRoute = [];

  RideBloc() : super(RideInitial()) {
    on<LoadActiveRide>(_onLoadActiveRide);
    on<CreateRide>(_onCreateRide);
    on<UpdateRideStatus>(_onUpdateRideStatus);
    on<StartPickup>(_onStartPickup);
    on<MarkArrived>(_onMarkArrived);
    on<PickupCustomer>(_onPickupCustomer);
    on<EndRide>(_onEndRide);
    on<CancelRide>(_onCancelRide);
    on<AddTrackingPoint>(_onAddTrackingPoint);
    on<LoadRideHistory>(_onLoadRideHistory);
    on<SendEmergencyAlert>(_onSendEmergencyAlert);
  }

  @override
  Future<void> close() {
    _trackingTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadActiveRide(
    LoadActiveRide event,
    Emitter<RideState> emit,
  ) async {
    emit(RideLoading());
    try {
      final activeRide = await _rideUseCase.getActiveRide(
        driverId: event.driverId,
      );
      _currentRide = activeRide;
      emit(RideLoaded(activeRide: activeRide));
    } catch (e) {
      // If fetching from the API fails, try to load from local storage
      final localRideData = StorageService.getJson('active_ride');
      if (localRideData != null) {
        final localRide = RideModel.fromJson(localRideData);
        _currentRide = localRide;
        emit(RideLoaded(activeRide: localRide));
      } else {
        emit(RideError(message: e.toString()));
      }
    }
  }

  Future<void> _onCreateRide(CreateRide event, Emitter<RideState> emit) async {
    emit(RideLoading());
    try {
      final ride = await _rideUseCase.createRide(event.ride);
      _currentRide = ride;
      await _saveActiveRide(ride);
      emit(RideSuccess(ride: ride, message: 'Ride created successfully'));
    } catch (e) {
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onUpdateRideStatus(
    UpdateRideStatus event,
    Emitter<RideState> emit,
  ) async {
    if (_currentRide == null) {
      emit(const RideError(message: 'No active ride found'));
      return;
    }

    emit(
      RideUpdating(
        currentRide: _currentRide!,
        action: 'Updating status to ${event.status}',
      ),
    );

    try {
      final updatedRide = await _rideUseCase.updateRideStatus(
        rideId: event.rideId,
        status: event.status,
        additionalData: event.additionalData,
      );
      _currentRide = updatedRide;
      await _saveActiveRide(updatedRide);
      emit(
        RideSuccess(
          ride: updatedRide,
          message: 'Ride status updated successfully',
        ),
      );
    } catch (e) {
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onStartPickup(
    StartPickup event,
    Emitter<RideState> emit,
  ) async {
    if (_currentRide == null || !_rideUseCase.canStartPickup(_currentRide!)) {
      emit(const RideError(message: 'Cannot start pickup at this time'));
      return;
    }

    emit(
      RideUpdating(currentRide: _currentRide!, action: 'Starting pickup...'),
    );

    try {
      final updatedRide = await _rideUseCase.updateRideStatus(
        rideId: event.rideId,
        status: 'enRoute',
        additionalData: {'startedAt': DateTime.now().toIso8601String()},
      );
      _currentRide = updatedRide;
      await _saveActiveRide(updatedRide);
      _startLocationTracking();
      emit(RideSuccess(ride: updatedRide, message: 'Started pickup journey'));
    } catch (e) {
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onMarkArrived(
    MarkArrived event,
    Emitter<RideState> emit,
  ) async {
    if (_currentRide == null || !_rideUseCase.canArrive(_currentRide!)) {
      emit(const RideError(message: 'Cannot mark as arrived at this time'));
      return;
    }

    emit(
      RideUpdating(currentRide: _currentRide!, action: 'Marking as arrived...'),
    );

    try {
      final updatedRide = await _rideUseCase.updateRideStatus(
        rideId: event.rideId,
        status: 'arrived',
        additionalData: {'arrivedAt': DateTime.now().toIso8601String()},
      );
      _currentRide = updatedRide;
      await _saveActiveRide(updatedRide);
      emit(
        RideSuccess(
          ride: updatedRide,
          message: 'Marked as arrived at pickup location',
        ),
      );
    } catch (e) {
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onPickupCustomer(
    PickupCustomer event,
    Emitter<RideState> emit,
  ) async {
    if (_currentRide == null || !_rideUseCase.canPickUp(_currentRide!)) {
      emit(const RideError(message: 'Cannot pickup customer at this time'));
      return;
    }

    emit(
      RideUpdating(
        currentRide: _currentRide!,
        action: 'Picking up customer...',
      ),
    );

    try {
      final updatedRide = await _rideUseCase.updateRideStatus(
        rideId: event.rideId,
        status: 'inProgress',
        additionalData: {'pickedUpAt': DateTime.now().toIso8601String()},
      );
      _currentRide = updatedRide;
      await _saveActiveRide(updatedRide);
      emit(
        RideSuccess(
          ride: updatedRide,
          message: 'Customer picked up successfully',
        ),
      );
    } catch (e) {
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onEndRide(EndRide event, Emitter<RideState> emit) async {
    if (_currentRide == null || !_rideUseCase.canEndRide(_currentRide!)) {
      emit(const RideError(message: 'Cannot end ride at this time'));
      return;
    }

    emit(RideUpdating(currentRide: _currentRide!, action: 'Ending ride...'));

    try {
      _stopLocationTracking();

      final totalDistance = _rideUseCase.calculateDistance(_currentRoute);
      final duration = _rideUseCase.calculateDuration(
        startTime: _currentRide!.startedAt ?? _currentRide!.createdAt,
      );

      final completedRide = await _rideUseCase.completeRide(
        rideId: event.rideId,
        totalDistance: totalDistance,
        duration: duration,
        notes: event.notes,
      );

      _currentRide = null;
      _currentRoute.clear();
      await StorageService.remove('active_ride');

      emit(
        RideSuccess(
          ride: completedRide,
          message: 'Ride completed successfully',
        ),
      );
    } catch (e) {
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onCancelRide(CancelRide event, Emitter<RideState> emit) async {
    if (_currentRide == null) {
      emit(const RideError(message: 'No active ride to cancel'));
      return;
    }

    emit(
      RideUpdating(currentRide: _currentRide!, action: 'Cancelling ride...'),
    );

    try {
      _stopLocationTracking();

      final cancelledRide = await _rideUseCase.cancelRide(
        rideId: event.rideId,
        reason: event.reason,
      );

      _currentRide = null;
      _currentRoute.clear();
      await StorageService.remove('active_ride');

      emit(
        RideSuccess(
          ride: cancelledRide,
          message: 'Ride cancelled successfully',
        ),
      );
    } catch (e) {
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onAddTrackingPoint(
    AddTrackingPoint event,
    Emitter<RideState> emit,
  ) async {
    try {
      await _rideUseCase.addTrackingPoint(
        rideId: event.rideId,
        locationPoint: event.locationPoint,
      );
      _currentRoute.add(event.locationPoint);
    } catch (e) {
      // Silently handle tracking errors to avoid disrupting the ride flow
      print('Error adding tracking point: $e');
    }
  }

  Future<void> _onLoadRideHistory(
    LoadRideHistory event,
    Emitter<RideState> emit,
  ) async {
    emit(RideLoading());
    try {
      final rideHistory = await _rideUseCase.getRideHistory(
        driverId: event.driverId,
        page: event.page,
        limit: event.limit,
      );
      emit(RideLoaded(rideHistory: rideHistory));
    } catch (e) {
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onSendEmergencyAlert(
    SendEmergencyAlert event,
    Emitter<RideState> emit,
  ) async {
    try {
      await _rideUseCase.sendEmergencyAlert(
        driverId: event.driverId,
        rideId: event.rideId,
        latitude: event.latitude,
        longitude: event.longitude,
        message: event.message,
      );
      emit(const EmergencyAlertSent('Emergency alert sent successfully'));
    } catch (e) {
      emit(RideError(message: 'Failed to send emergency alert: $e'));
    }
  }

  void _startLocationTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_currentRide != null) {
        try {
          final position = await _locationService.getCurrentPosition();
          if (position != null) {
            final locationPoint = LocationPoint(
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: DateTime.now(),
              speed: position.speed,
              bearing: position.heading,
            );

            add(
              AddTrackingPoint(
                rideId: _currentRide!.id,
                locationPoint: locationPoint,
              ),
            );
          }
        } catch (e) {
          print('Error getting location: $e');
        }
      }
    });
  }

  void _stopLocationTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  // Getters for current ride state
  RideModel? get currentRide => _currentRide;
  List<LocationPoint> get currentRoute => List.unmodifiable(_currentRoute);
  bool get isTracking => _trackingTimer?.isActive ?? false;
}
