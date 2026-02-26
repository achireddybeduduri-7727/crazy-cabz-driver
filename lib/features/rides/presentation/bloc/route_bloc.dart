import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../shared/models/route_model.dart';
import '../../../../shared/models/ride_model.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/gps_tracking_service.dart';
import '../../../../core/services/ride_history_service.dart';
import '../../../../core/services/ride_firebase_integration.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/route_use_case.dart';
import 'route_event.dart';
import 'route_state.dart';

// Helper class for route verification results
class RouteVerificationResult {
  final bool isValid;
  final String? error;

  const RouteVerificationResult({required this.isValid, this.error});
}

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final RouteUseCase _routeUseCase = RouteUseCase();
  final LocationService _locationService = LocationService();
  final GPSTrackingService _gpsTrackingService = GPSTrackingService();
  final RideFirebaseIntegration _firebaseIntegration = RideFirebaseIntegration();

  RouteModel? _currentRoute;
  Timer? _trackingTimer;
  Timer? _officeUpdateTimer;

  RouteBloc() : super(RouteInitial()) {
    on<LoadActiveRoute>(_onLoadActiveRoute);
    on<LoadRouteHistory>(_onLoadRouteHistory);
    on<StartRoute>(_onStartRoute);
    on<CompleteRoute>(_onCompleteRoute);
    on<CancelRoute>(_onCancelRoute);
    on<UpdateIndividualRideStatus>(_onUpdateIndividualRideStatus);
    on<MarkPassengerPresent>(_onMarkPassengerPresent);
    on<AddRouteTrackingPoint>(_onAddRouteTrackingPoint);
    on<SendOfficeTrackingUpdate>(_onSendOfficeTrackingUpdate);
    on<SendEmergencyAlert>(_onSendEmergencyAlert);
    on<CreateManualRoute>(_onCreateManualRoute);
    on<NavigateToPickup>(_onNavigateToPickup);
    on<CompleteManualRoute>(_onCompleteManualRoute);
    on<CancelManualRoute>(_onCancelManualRoute);
    on<LoadRideHistory>(_onLoadRideHistory);
    on<CancelIndividualRide>(_onCancelIndividualRide);
    on<UpdateRideAddress>(_onUpdateRideAddress);

    // Time-tracked ride events
    on<StartNavigationToPickup>(_onStartNavigationToPickup);
    on<ArrivedAtPickup>(_onArrivedAtPickup);
    on<PassengerPickedUp>(_onPassengerPickedUp);
    on<StartNavigationToDestination>(_onStartNavigationToDestination);
    on<ArrivedAtDestination>(_onArrivedAtDestination);
    on<CompleteRideWithTimestamp>(_onCompleteRideWithTimestamp);

    // Load active ride on initialization
    _loadActiveRideOnStart();
  }

  @override
  Future<void> close() {
    _trackingTimer?.cancel();
    _officeUpdateTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadActiveRoute(
    LoadActiveRoute event,
    Emitter<RouteState> emit,
  ) async {
    emit(RouteLoading());
    try {
      print('🔍 [BLOC] ======= LoadActiveRoute STARTED =======');
      print('🔍 [BLOC] Loading active route for driver: ${event.driverId}');

      // First, check local storage for saved active ride (manual rides are saved here)
      RouteModel? activeRoute;
      try {
        print('🔍 [BLOC] Checking RideHistoryService.getActiveRide()...');
        activeRoute = await RideHistoryService.getActiveRide();
        if (activeRoute != null) {
          print(
            '✅ [BLOC] Found active route in local storage: ${activeRoute.id}',
          );
          print('📊 [BLOC] Route status: ${activeRoute.status}');
          print('🚗 [BLOC] Number of rides: ${activeRoute.rides.length}');
          print('⏰ [BLOC] Scheduled time: ${activeRoute.scheduledTime}');
        } else {
          print('ℹ️ [BLOC] No active route found in local storage');
        }
      } catch (localError) {
        print('⚠️ [BLOC] Error loading from local storage: $localError');
      }

      // If no local route found, try fetching from network (for scheduled routes from backend)
      if (activeRoute == null) {
        print(
          '🌐 [BLOC] No local route - Checking network for active route...',
        );
        try {
          activeRoute = await _routeUseCase.getActiveRoute(
            driverId: event.driverId,
          );
          if (activeRoute != null) {
            print(
              '✅ [BLOC] Found active route from network: ${activeRoute.id}',
            );
            // Save to local storage for offline access
            print('💾 [BLOC] Saving network route to local storage...');
            await RideHistoryService.saveActiveRide(activeRoute);
          } else {
            print('ℹ️ [BLOC] No active route found on network');
          }
        } catch (networkError) {
          print('⚠️ [BLOC] Network request failed: $networkError');
          // Network failure is acceptable - we already checked local storage
        }
      }

      _currentRoute = activeRoute;

      // Successfully loaded (even if null - meaning no active route)
      print('📤 [BLOC] Emitting RouteLoaded state...');
      emit(RouteLoaded(activeRoute: activeRoute));
      print(
        '✅ [BLOC] Active route loaded: ${activeRoute != null ? "Route found (${activeRoute.rides.length} rides)" : "No active route"}',
      );
      print('🔍 [BLOC] ======= LoadActiveRoute COMPLETED =======');
    } catch (e) {
      print('❌ [BLOC] Error loading active route: $e');
      // Provide a user-friendly error message
      String errorMessage = 'Unable to load routes';
      if (e.toString().contains('Failed to connect') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('timeout')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('500') ||
          e.toString().contains('server')) {
        errorMessage = 'Server error. Please try again later.';
      }
      emit(RouteError(message: errorMessage));
    }
  }

  Future<void> _onLoadRouteHistory(
    LoadRouteHistory event,
    Emitter<RouteState> emit,
  ) async {
    emit(RouteLoading());
    try {
      final routeHistory = await _routeUseCase.getRouteHistory(
        driverId: event.driverId,
        page: event.page,
        limit: event.limit,
      );
      emit(RouteLoaded(routeHistory: routeHistory));
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }

  Future<void> _onStartRoute(StartRoute event, Emitter<RouteState> emit) async {
    if (_currentRoute == null) {
      emit(const RouteError(message: 'No active route found'));
      return;
    }

    emit(
      RouteUpdating(currentRoute: _currentRoute!, action: 'Starting route...'),
    );

    try {
      final updatedRoute = await _routeUseCase.startRoute(
        routeId: event.routeId,
      );
      _currentRoute = updatedRoute;
      _startLocationTracking();
      _startOfficeUpdates();

      // Start GPS tracking for the route
      await _startGPSTracking();

      emit(
        RouteSuccess(
          route: updatedRoute,
          message: 'Route started successfully',
        ),
      );
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }

  Future<void> _onCompleteRoute(
    CompleteRoute event,
    Emitter<RouteState> emit,
  ) async {
    if (_currentRoute == null) {
      emit(const RouteError(message: 'No active route found'));
      return;
    }

    emit(
      RouteUpdating(
        currentRoute: _currentRoute!,
        action: 'Completing route...',
      ),
    );

    try {
      _stopLocationTracking();
      _stopOfficeUpdates();

      // Stop GPS tracking
      await _stopGPSTracking();

      final completedRoute = await _routeUseCase.completeRoute(
        routeId: event.routeId,
        notes: event.notes,
      );

      // Add completed route to history
      await RideHistoryService.addToHistory(completedRoute);

      // Clear active ride
      await RideHistoryService.clearActiveRide();
      _currentRoute = null;

      emit(
        RouteSuccess(
          route: completedRoute,
          message: 'Route completed and saved to history',
        ),
      );
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }

  Future<void> _onCancelRoute(
    CancelRoute event,
    Emitter<RouteState> emit,
  ) async {
    if (_currentRoute == null) {
      emit(const RouteError(message: 'No active route found'));
      return;
    }

    emit(
      RouteUpdating(
        currentRoute: _currentRoute!,
        action: 'Cancelling route...',
      ),
    );

    try {
      _stopLocationTracking();
      _stopOfficeUpdates();

      final cancelledRoute = await _routeUseCase.cancelRoute(
        routeId: event.routeId,
        reason: event.reason,
      );

      _currentRoute = null;

      emit(
        RouteSuccess(
          route: cancelledRoute,
          message: 'Route cancelled successfully',
        ),
      );
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }

  Future<void> _onUpdateIndividualRideStatus(
    UpdateIndividualRideStatus event,
    Emitter<RouteState> emit,
  ) async {
    if (_currentRoute == null) {
      emit(const RouteError(message: 'No active route found'));
      return;
    }

    try {
      final updatedRide = await _routeUseCase.updateIndividualRideStatus(
        rideId: event.rideId,
        status: event.status,
        additionalData: event.additionalData,
      );

      // Update the current route with the updated ride
      final updatedRides = _currentRoute!.rides.map((ride) {
        return ride.id == event.rideId ? updatedRide : ride;
      }).toList();

      _currentRoute = _currentRoute!.copyWith(rides: updatedRides);

      // Send update to office tracking system
      add(
        SendOfficeTrackingUpdate(
          routeId: _currentRoute!.id,
          trackingData: {
            'ride_id': event.rideId,
            'status': event.status.name,
            'timestamp': DateTime.now().toIso8601String(),
            'passenger': updatedRide.passenger.toJson(),
          },
        ),
      );

      emit(
        IndividualRideUpdated(
          ride: updatedRide,
          message: 'Ride status updated successfully',
        ),
      );
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }

  Future<void> _onMarkPassengerPresent(
    MarkPassengerPresent event,
    Emitter<RouteState> emit,
  ) async {
    try {
      final updatedRide = await _routeUseCase.markPassengerPresent(
        rideId: event.rideId,
        isPresent: event.isPresent,
      );

      // Update the current route with the updated ride
      if (_currentRoute != null) {
        final updatedRides = _currentRoute!.rides.map((ride) {
          return ride.id == event.rideId ? updatedRide : ride;
        }).toList();

        _currentRoute = _currentRoute!.copyWith(rides: updatedRides);
      }

      emit(
        PassengerPresenceUpdated(
          ride: updatedRide,
          message: event.isPresent
              ? 'Passenger marked as present'
              : 'Passenger marked as absent',
        ),
      );
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }

  Future<void> _onAddRouteTrackingPoint(
    AddRouteTrackingPoint event,
    Emitter<RouteState> emit,
  ) async {
    try {
      await _routeUseCase.addRouteTrackingPoint(
        routeId: event.routeId,
        locationPoint: event.locationPoint,
      );

      // Update current route with new tracking point
      if (_currentRoute != null) {
        final updatedTrackingPoints = List<LocationPoint>.from(
          _currentRoute!.routeTrackingPoints,
        )..add(event.locationPoint);
        _currentRoute = _currentRoute!.copyWith(
          routeTrackingPoints: updatedTrackingPoints,
        );
      }
    } catch (e) {
      // Silently handle tracking errors to avoid disrupting the route flow
      AppLogger.warning('Error adding route tracking point: $e');
    }
  }

  Future<void> _onSendOfficeTrackingUpdate(
    SendOfficeTrackingUpdate event,
    Emitter<RouteState> emit,
  ) async {
    try {
      await _routeUseCase.sendOfficeTrackingUpdate(
        routeId: event.routeId,
        trackingData: event.trackingData,
      );

      emit(const OfficeTrackingUpdateSent('Tracking update sent to office'));
    } catch (e) {
      // Don't emit error for tracking updates as they shouldn't disrupt the main flow
      AppLogger.warning('Error sending office tracking update: $e');
    }
  }

  Future<void> _onSendEmergencyAlert(
    SendEmergencyAlert event,
    Emitter<RouteState> emit,
  ) async {
    try {
      await _routeUseCase.sendEmergencyAlert(
        driverId: event.driverId,
        routeId: event.routeId,
        latitude: event.latitude,
        longitude: event.longitude,
        message: event.message,
      );
      emit(const EmergencyAlertSent('Emergency alert sent successfully'));
    } catch (e) {
      emit(RouteError(message: 'Failed to send emergency alert: $e'));
    }
  }

  void _startLocationTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_currentRoute != null) {
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
              AddRouteTrackingPoint(
                routeId: _currentRoute!.id,
                locationPoint: locationPoint,
              ),
            );
          }
        } catch (e) {
          AppLogger.warning('Error getting location for tracking: $e');
        }
      }
    });
  }

  void _stopLocationTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  /// Start GPS tracking for the current route
  Future<void> _startGPSTracking() async {
    if (_currentRoute == null) return;

    try {
      AppLogger.info('Starting GPS tracking for route: ${_currentRoute!.id}');

      // Get the first ride as the primary ride for GPS tracking
      final primaryRide = _currentRoute!.rides.first;

      final success = await _gpsTrackingService.startTracking(
        rideId: primaryRide.id,
        routeId: _currentRoute!.id,
      );

      if (success) {
        AppLogger.info('GPS tracking started successfully');
      } else {
        AppLogger.warning('Failed to start GPS tracking');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error starting GPS tracking: $e');
      AppLogger.error('Stack trace: $stackTrace');
    }
  }

  /// Stop GPS tracking for the current route
  Future<void> _stopGPSTracking() async {
    try {
      AppLogger.info('Stopping GPS tracking');
      await _gpsTrackingService.stopTracking();
      AppLogger.info('GPS tracking stopped successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error stopping GPS tracking: $e');
      AppLogger.error('Stack trace: $stackTrace');
    }
  }

  void _startOfficeUpdates() {
    _officeUpdateTimer?.cancel();
    _officeUpdateTimer = Timer.periodic(const Duration(minutes: 2), (
      timer,
    ) async {
      if (_currentRoute != null) {
        try {
          final position = await _locationService.getCurrentPosition();
          if (position != null) {
            add(
              SendOfficeTrackingUpdate(
                routeId: _currentRoute!.id,
                trackingData: {
                  'route_id': _currentRoute!.id,
                  'driver_location': {
                    'latitude': position.latitude,
                    'longitude': position.longitude,
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                  'route_status': _currentRoute!.status.name,
                  'completed_rides': _currentRoute!.completedRides,
                  'total_rides': _currentRoute!.totalPassengers,
                  'next_stops': _currentRoute!.nextRides
                      .take(3)
                      .map(
                        (ride) => {
                          'passenger_name': ride.passenger.fullName,
                          'address': ride.pickupAddress,
                          'status': ride.status.name,
                        },
                      )
                      .toList(),
                },
              ),
            );
          }
        } catch (e) {
          AppLogger.warning('Error sending periodic office update: $e');
        }
      }
    });
  }

  void _stopOfficeUpdates() {
    _officeUpdateTimer?.cancel();
    _officeUpdateTimer = null;
  }

  Future<void> _onCreateManualRoute(
    CreateManualRoute event,
    Emitter<RouteState> emit,
  ) async {
    AppLogger.info('🚀 Starting manual route creation process');
    emit(RouteLoading());

    try {
      // Comprehensive validation of the route data
      final validationError = _validateRouteData(event.route);
      if (validationError != null) {
        AppLogger.error('❌ Route validation failed: $validationError');
        emit(
          RouteError(message: validationError, errorCode: 'VALIDATION_ERROR'),
        );
        return;
      }

      AppLogger.info('✅ Route validation passed');
      AppLogger.info('📝 Creating manual route: ${event.route.id}');
      AppLogger.info('👤 Driver ID: ${event.route.driverId}');
      AppLogger.info('🚗 Number of rides: ${event.route.rides.length}');

      // Log detailed ride information
      for (int i = 0; i < event.route.rides.length; i++) {
        final ride = event.route.rides[i];
        AppLogger.info(
          '🎯 Ride ${i + 1}: ${ride.passenger.fullName} - ${ride.pickupAddress} → ${ride.dropOffAddress}',
        );
      }

      // Clear any existing active route to prevent conflicts
      if (_currentRoute != null) {
        AppLogger.info(
          '🔄 Clearing existing active route: ${_currentRoute!.id}',
        );
        await RideHistoryService.clearActiveRide();
      }

      // Store the route with enhanced error handling
      _currentRoute = event.route;

      print('💾 [BLOC] Attempting to save route to RideHistoryService...');
      try {
        await RideHistoryService.saveActiveRide(event.route);
        print('✅ [BLOC] Route saved to persistent storage successfully');
        AppLogger.info('💾 Route saved to persistent storage successfully');
      } catch (storageError) {
        print(
          '❌ [BLOC] CRITICAL: Failed to save to persistent storage: $storageError',
        );
        AppLogger.error(
          '💾 CRITICAL: Failed to save to persistent storage: $storageError',
        );
        // This is critical - if we can't save, throw error
        throw Exception('Failed to save route: $storageError');
      }

      // Simulate realistic processing time with progressive updates
      await Future.delayed(const Duration(milliseconds: 300));
      emit(
        RouteUpdating(
          currentRoute: event.route,
          action: 'Processing route data...',
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      emit(
        RouteUpdating(
          currentRoute: event.route,
          action: 'Validating passenger information...',
        ),
      );

      await Future.delayed(const Duration(milliseconds: 200));

      // Final verification with comprehensive checks
      final verificationResult = _verifyRouteCreation(event.route);
      if (!verificationResult.isValid) {
        throw Exception(
          'Route verification failed: ${verificationResult.error}',
        );
      }

      AppLogger.info('✅ Route verification completed successfully');

      // Create a copy of the route with updated timestamps
      final finalRoute = event.route.copyWith(
        createdAt: DateTime.now(),
        status: RouteStatus.scheduled,
      );

      // Update current route and save to storage again with final timestamps
      _currentRoute = finalRoute;

      print('💾 [BLOC] Saving final route with updated timestamps...');
      try {
        await RideHistoryService.saveActiveRide(finalRoute);
        print('✅ [BLOC] Final route saved to persistent storage');
        AppLogger.info('💾 Final route saved to persistent storage');
      } catch (storageError) {
        print('❌ [BLOC] CRITICAL: Failed to save final route: $storageError');
        AppLogger.error(
          '💾 CRITICAL: Failed to save final route: $storageError',
        );
        // This is critical - if we can't save the final route, throw error
        throw Exception('Failed to save final route: $storageError');
      }

      // 🔥 SAVE TO FIREBASE: Save ride creation with all details
      try {
        print('🔥 [FIREBASE] Saving ride to Firebase...');
        await _firebaseIntegration.onRideCreated(
          route: finalRoute,
          driverId: finalRoute.driverId,
        );
        print('✅ [FIREBASE] Ride saved to Firebase successfully');
        AppLogger.info('🔥 Ride data saved to Firebase');
      } catch (firebaseError) {
        print('⚠️ [FIREBASE] Firebase save failed but continuing: $firebaseError');
        AppLogger.error('⚠️ Firebase save failed: $firebaseError');
        // Don't throw - local functionality should continue even if Firebase fails
      }

      // Emit success message first
      emit(
        RouteSuccess(
          route: finalRoute,
          message:
              'Manual ride created successfully! ${finalRoute.rides.length} passenger(s) added.',
        ),
      );

      // Then immediately emit RouteLoaded so the UI displays the route
      print('📤 [BLOC] Emitting RouteLoaded state with final route');
      await Future.delayed(const Duration(milliseconds: 500));
      emit(RouteLoaded(activeRoute: finalRoute));
      print('✅ [BLOC] RouteLoaded state emitted');

      AppLogger.info('🎉 Manual route created successfully: ${finalRoute.id}');
      AppLogger.info('📊 Route status: ${finalRoute.status}');
      AppLogger.info('⏰ Scheduled for: ${finalRoute.scheduledTime}');
    } catch (e, stackTrace) {
      AppLogger.error('💥 Failed to create manual route: $e');
      AppLogger.error('📋 Stack trace: $stackTrace');

      // Clean up any partial state
      _currentRoute = null;
      try {
        await RideHistoryService.clearActiveRide();
      } catch (cleanupError) {
        AppLogger.error('🧹 Failed to cleanup after error: $cleanupError');
      }

      // Provide specific error messages based on error type
      String userMessage = 'Failed to create manual ride. Please try again.';
      if (e.toString().contains('validation')) {
        userMessage = 'Invalid ride information. Please check your input.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        userMessage =
            'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('storage')) {
        userMessage = 'Storage error. Please restart the app and try again.';
      }

      emit(
        RouteError(
          message: userMessage,
          errorCode: 'CREATE_MANUAL_ROUTE_ERROR',
        ),
      );
    }
  }

  // Enhanced validation method
  String? _validateRouteData(RouteModel route) {
    if (route.id.isEmpty) {
      return 'Route ID is missing';
    }

    if (route.driverId.isEmpty) {
      return 'Driver information is missing';
    }

    if (route.rides.isEmpty) {
      return 'No passengers found. Please add at least one passenger.';
    }

    if (route.rides.length > 10) {
      return 'Too many passengers. Maximum 10 passengers allowed per route.';
    }

    // Validate each ride
    for (int i = 0; i < route.rides.length; i++) {
      final ride = route.rides[i];

      if (ride.passenger.fullName.trim().isEmpty) {
        return 'Passenger ${i + 1}: Name is required';
      }

      if (ride.passenger.phoneNumber.trim().isEmpty) {
        return 'Passenger ${i + 1}: Phone number is required';
      }

      if (ride.pickupAddress.trim().isEmpty) {
        return 'Passenger ${i + 1}: Pickup address is required';
      }

      if (ride.dropOffAddress.trim().isEmpty) {
        return 'Passenger ${i + 1}: Drop-off address is required';
      }

      if (ride.scheduledPickupTime != null &&
          ride.scheduledPickupTime!.isBefore(
            DateTime.now().subtract(const Duration(minutes: 5)),
          )) {
        return 'Passenger ${i + 1}: Pickup time cannot be in the past';
      }

      // Validate phone number format (basic check)
      final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
      if (!phoneRegex.hasMatch(ride.passenger.phoneNumber.trim())) {
        return 'Passenger ${i + 1}: Invalid phone number format';
      }
    }

    return null; // All validations passed
  }

  // Enhanced verification method
  RouteVerificationResult _verifyRouteCreation(RouteModel route) {
    try {
      // Check if route was stored properly
      if (_currentRoute == null || _currentRoute!.id != route.id) {
        return RouteVerificationResult(
          isValid: false,
          error: 'Route was not stored correctly in memory',
        );
      }

      // Verify all required fields are present
      if (_currentRoute!.rides.length != route.rides.length) {
        return RouteVerificationResult(
          isValid: false,
          error: 'Passenger count mismatch during verification',
        );
      }

      // Verify passenger data integrity
      for (int i = 0; i < route.rides.length; i++) {
        final originalRide = route.rides[i];
        final storedRide = _currentRoute!.rides[i];

        if (originalRide.passenger.fullName != storedRide.passenger.fullName) {
          return RouteVerificationResult(
            isValid: false,
            error: 'Passenger ${i + 1} data corruption detected',
          );
        }
      }

      return RouteVerificationResult(isValid: true);
    } catch (e) {
      return RouteVerificationResult(
        isValid: false,
        error: 'Verification process failed: $e',
      );
    }
  }

  Future<void> _onNavigateToPickup(
    NavigateToPickup event,
    Emitter<RouteState> emit,
  ) async {
    try {
      AppLogger.info('Starting navigation process');

      // Validate input
      if (event.pickupAddress.trim().isEmpty) {
        AppLogger.error('Pickup address is empty');
        emit(RouteError(message: 'Invalid pickup address'));
        return;
      }

      AppLogger.info(
        'Launching Google Maps navigation to: ${event.pickupAddress}',
      );

      String destination = event.pickupAddress.trim();

      // If we have coordinates, use them for more precise navigation
      if (event.pickupLatitude != null && event.pickupLongitude != null) {
        destination = '${event.pickupLatitude},${event.pickupLongitude}';
        AppLogger.info('Using provided coordinates: $destination');
      } else {
        // Try to geocode the address to get coordinates with timeout
        try {
          AppLogger.info('Attempting to geocode address...');

          // Add timeout to prevent hanging
          List<Location> locations = await locationFromAddress(
            event.pickupAddress,
          ).timeout(const Duration(seconds: 5));

          if (locations.isNotEmpty) {
            Location location = locations.first;
            destination = '${location.latitude},${location.longitude}';
            AppLogger.info('Geocoded address to: $destination');
          }
        } catch (geocodeError) {
          AppLogger.warning(
            'Geocoding failed or timed out, using raw address: $geocodeError',
          );
          // Use the original address if geocoding fails
          destination = Uri.encodeComponent(event.pickupAddress);
        }
      }

      // Create Google Maps navigation URL
      final String mapsUrlString =
          'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving';
      AppLogger.info('Maps URL: $mapsUrlString');

      final Uri mapsUrl = Uri.parse(mapsUrlString);

      // Check if URL can be launched before attempting
      AppLogger.info('Checking if Google Maps can be launched...');
      bool canLaunch = await canLaunchUrl(mapsUrl);

      if (canLaunch) {
        AppLogger.info('Launching Google Maps...');
        bool launched = await launchUrl(
          mapsUrl,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          emit(
            NavigationLaunched(
              address: event.pickupAddress,
              message: 'Google Maps navigation launched successfully',
            ),
          );
          AppLogger.info('Google Maps navigation launched successfully');
        } else {
          throw Exception('Failed to launch Google Maps URL');
        }
      } else {
        throw Exception(
          'Cannot launch Google Maps - no compatible application found',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to launch navigation: $e');
      AppLogger.error('Navigation stack trace: $stackTrace');
      emit(
        RouteError(
          message:
              'Failed to launch navigation. Please check if Google Maps is installed.',
        ),
      );
    }
  }

  Future<void> _onCompleteManualRoute(
    CompleteManualRoute event,
    Emitter<RouteState> emit,
  ) async {
    try {
      AppLogger.info('Completing manual route: ${event.routeId}');

      // Update route status to completed
      if (_currentRoute != null && _currentRoute!.id == event.routeId) {
        final completedRoute = _currentRoute!.copyWith(
          status: RouteStatus.completed,
          completedAt: event.completedAt,
          notes: event.completionNotes ?? _currentRoute!.notes,
        );

        // Add to history
        await RideHistoryService.addToHistory(completedRoute);

        // Clear active ride
        await RideHistoryService.clearActiveRide();
        _currentRoute = null;

        emit(
          RouteCompleted(
            route: completedRoute,
            message: 'Ride completed successfully',
            completedAt: event.completedAt,
          ),
        );

        AppLogger.info(
          'Manual route completed and added to history: ${event.routeId}',
        );
      } else {
        throw Exception('Route not found or ID mismatch');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to complete manual route: $e');
      AppLogger.error('Complete route stack trace: $stackTrace');
      emit(RouteError(message: 'Failed to complete ride. Please try again.'));
    }
  }

  Future<void> _onCancelManualRoute(
    CancelManualRoute event,
    Emitter<RouteState> emit,
  ) async {
    try {
      AppLogger.info('Cancelling manual route: ${event.routeId}');

      // Update route status to cancelled
      if (_currentRoute != null && _currentRoute!.id == event.routeId) {
        final cancelledRoute = _currentRoute!.copyWith(
          status: RouteStatus.cancelled,
          completedAt: event.cancelledAt,
          notes:
              '${_currentRoute!.notes ?? ''}\nCancelled: ${event.cancellationReason}',
        );

        // Add to history
        await RideHistoryService.addToHistory(cancelledRoute);

        // Clear active ride
        await RideHistoryService.clearActiveRide();
        _currentRoute = null;

        emit(
          RouteCancelled(
            route: cancelledRoute,
            message: 'Ride cancelled',
            reason: event.cancellationReason,
            cancelledAt: event.cancelledAt,
          ),
        );

        AppLogger.info(
          'Manual route cancelled and added to history: ${event.routeId}',
        );
      } else {
        throw Exception('Route not found or ID mismatch');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cancel manual route: $e');
      AppLogger.error('Cancel route stack trace: $stackTrace');
      emit(RouteError(message: 'Failed to cancel ride. Please try again.'));
    }
  }

  Future<void> _onLoadRideHistory(
    LoadRideHistory event,
    Emitter<RouteState> emit,
  ) async {
    try {
      print('🔍 RouteBloc: Loading ride history for driver: ${event.driverId}');
      AppLogger.info('Loading ride history for driver: ${event.driverId}');

      // Don't emit RouteLoading - load instantly from local storage
      // This prevents showing spinner and makes UI instant

      // Load history from storage (returns immediately from local)
      final historyRoutes = await RideHistoryService.getRideHistory();
      final statistics = await RideHistoryService.getRideStatistics();

      print('✅ RouteBloc: Loaded ${historyRoutes.length} rides from history');
      print('📊 RouteBloc: Emitting RideHistoryLoaded state...');

      // Always emit success, even if empty
      emit(
        RideHistoryLoaded(
          historyRoutes: historyRoutes,
          totalCount: statistics['total'] ?? 0,
        ),
      );

      AppLogger.info('Loaded ${historyRoutes.length} rides from history');
    } catch (e, stackTrace) {
      print('❌ RouteBloc: Failed to load ride history: $e');
      print('📋 Stack trace: $stackTrace');
      AppLogger.error('Failed to load ride history: $e');
      AppLogger.error('Load history stack trace: $stackTrace');

      // Even on error, emit empty history instead of error state
      print('🔄 Emitting empty history instead of error');
      emit(RideHistoryLoaded(historyRoutes: [], totalCount: 0));
    }
  }

  Future<void> _loadActiveRideOnStart() async {
    try {
      AppLogger.info('Loading active ride on startup');

      final activeRide = await RideHistoryService.getActiveRide();
      if (activeRide != null) {
        _currentRoute = activeRide;
        AppLogger.info('Active ride restored: ${activeRide.id}');
      } else {
        AppLogger.info('No active ride found');
      }
    } catch (e) {
      AppLogger.error('Failed to load active ride on startup: $e');
    }
  }

  // Time-tracked ride event handlers

  Future<void> _onStartNavigationToPickup(
    StartNavigationToPickup event,
    Emitter<RouteState> emit,
  ) async {
    try {
      AppLogger.info('Starting navigation to pickup for ride: ${event.rideId}');

      if (_currentRoute == null) {
        emit(const RouteError(message: 'No active route found'));
        return;
      }

      // Find the ride and update with navigation timestamp
      final updatedRides = _currentRoute!.rides.map((ride) {
        if (ride.id == event.rideId) {
          return ride.copyWith(
            status: IndividualRideStatus.enRoute,
            navigatedToPickupAt: event.timestamp,
          );
        }
        return ride;
      }).toList();

      _currentRoute = _currentRoute!.copyWith(rides: updatedRides);

      // Save to persistence
      await RideHistoryService.saveActiveRide(_currentRoute!);

      // 🔥 SAVE TO FIREBASE: Track navigation start
      try {
        await _firebaseIntegration.onNavigateToPickup(
          rideId: event.rideId,
          timestamp: event.timestamp,
        );
        AppLogger.info('🔥 Navigation to pickup saved to Firebase');
      } catch (firebaseError) {
        AppLogger.error('⚠️ Firebase tracking failed: $firebaseError');
      }

      // Find the updated ride to emit
      final updatedRide = updatedRides.firstWhere(
        (ride) => ride.id == event.rideId,
      );

      emit(
        IndividualRideUpdated(
          ride: updatedRide,
          message: 'Navigation to pickup started',
        ),
      );

      AppLogger.info(
        'Navigation to pickup timestamp saved: ${event.timestamp}',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to start navigation to pickup: $e');
      AppLogger.error('Stack trace: $stackTrace');
      emit(RouteError(message: 'Failed to start navigation.'));
    }
  }

  Future<void> _onArrivedAtPickup(
    ArrivedAtPickup event,
    Emitter<RouteState> emit,
  ) async {
    try {
      AppLogger.info('Arrived at pickup for ride: ${event.rideId}');

      if (_currentRoute == null) {
        emit(const RouteError(message: 'No active route found'));
        return;
      }

      // Find the ride and update with arrival timestamp
      final updatedRides = _currentRoute!.rides.map((ride) {
        if (ride.id == event.rideId) {
          return ride.copyWith(
            status: IndividualRideStatus.arrived,
            arrivedAtPickupAt: event.timestamp,
          );
        }
        return ride;
      }).toList();

      _currentRoute = _currentRoute!.copyWith(rides: updatedRides);

      // Save to persistence
      await RideHistoryService.saveActiveRide(_currentRoute!);

      // 🔥 SAVE TO FIREBASE: Track arrival at pickup
      try {
        await _firebaseIntegration.onArriveAtPickup(
          rideId: event.rideId,
          timestamp: event.timestamp,
        );
        AppLogger.info('🔥 Arrival at pickup saved to Firebase');
      } catch (firebaseError) {
        AppLogger.error('⚠️ Firebase tracking failed: $firebaseError');
      }

      // Find the updated ride to emit
      final updatedRide = updatedRides.firstWhere(
        (ride) => ride.id == event.rideId,
      );

      emit(
        IndividualRideUpdated(
          ride: updatedRide,
          message: 'Arrived at pickup location',
        ),
      );

      AppLogger.info('Pickup arrival timestamp saved: ${event.timestamp}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to mark arrival at pickup: $e');
      AppLogger.error('Stack trace: $stackTrace');
      emit(RouteError(message: 'Failed to mark arrival.'));
    }
  }

  Future<void> _onPassengerPickedUp(
    PassengerPickedUp event,
    Emitter<RouteState> emit,
  ) async {
    try {
      AppLogger.info('Passenger picked up for ride: ${event.rideId}');

      if (_currentRoute == null) {
        emit(const RouteError(message: 'No active route found'));
        return;
      }

      // Find the ride and update with pickup timestamp
      final updatedRides = _currentRoute!.rides.map((ride) {
        if (ride.id == event.rideId) {
          return ride.copyWith(
            status: IndividualRideStatus.pickedUp,
            passengerPickedUpAt: event.timestamp,
          );
        }
        return ride;
      }).toList();

      _currentRoute = _currentRoute!.copyWith(rides: updatedRides);

      // Save to persistence
      await RideHistoryService.saveActiveRide(_currentRoute!);

      // 🔥 SAVE TO FIREBASE: Track passenger pickup
      try {
        await _firebaseIntegration.onPassengerPickedUp(
          rideId: event.rideId,
          timestamp: event.timestamp,
        );
        AppLogger.info('🔥 Passenger pickup saved to Firebase');
      } catch (firebaseError) {
        AppLogger.error('⚠️ Firebase tracking failed: $firebaseError');
      }

      // Find the updated ride to emit
      final updatedRide = updatedRides.firstWhere(
        (ride) => ride.id == event.rideId,
      );

      emit(
        IndividualRideUpdated(
          ride: updatedRide,
          message: 'Passenger picked up successfully',
        ),
      );

      AppLogger.info('Passenger pickup timestamp saved: ${event.timestamp}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to mark passenger picked up: $e');
      AppLogger.error('Stack trace: $stackTrace');
      emit(RouteError(message: 'Failed to mark passenger pickup.'));
    }
  }

  Future<void> _onStartNavigationToDestination(
    StartNavigationToDestination event,
    Emitter<RouteState> emit,
  ) async {
    try {
      AppLogger.info(
        'Starting navigation to destination for ride: ${event.rideId}',
      );

      if (_currentRoute == null) {
        emit(const RouteError(message: 'No active route found'));
        return;
      }

      // Find the ride and update with destination navigation timestamp
      final updatedRides = _currentRoute!.rides.map((ride) {
        if (ride.id == event.rideId) {
          return ride.copyWith(navigatedToDestinationAt: event.timestamp);
        }
        return ride;
      }).toList();

      _currentRoute = _currentRoute!.copyWith(rides: updatedRides);

      // Save to persistence
      await RideHistoryService.saveActiveRide(_currentRoute!);

      // Find the updated ride to emit
      final updatedRide = updatedRides.firstWhere(
        (ride) => ride.id == event.rideId,
      );

      emit(
        IndividualRideUpdated(
          ride: updatedRide,
          message: 'Navigation to destination started',
        ),
      );

      AppLogger.info(
        'Navigation to destination timestamp saved: ${event.timestamp}',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to start navigation to destination: $e');
      AppLogger.error('Stack trace: $stackTrace');
      emit(RouteError(message: 'Failed to start destination navigation.'));
    }
  }

  Future<void> _onArrivedAtDestination(
    ArrivedAtDestination event,
    Emitter<RouteState> emit,
  ) async {
    try {
      AppLogger.info('Arrived at destination for ride: ${event.rideId}');

      if (_currentRoute == null) {
        emit(const RouteError(message: 'No active route found'));
        return;
      }

      // Find the ride and update with destination arrival timestamp
      final updatedRides = _currentRoute!.rides.map((ride) {
        if (ride.id == event.rideId) {
          return ride.copyWith(arrivedAtDestinationAt: event.timestamp);
        }
        return ride;
      }).toList();

      _currentRoute = _currentRoute!.copyWith(rides: updatedRides);

      // Save to persistence
      await RideHistoryService.saveActiveRide(_currentRoute!);

      // Find the updated ride to emit
      final updatedRide = updatedRides.firstWhere(
        (ride) => ride.id == event.rideId,
      );

      emit(
        IndividualRideUpdated(
          ride: updatedRide,
          message: 'Arrived at destination',
        ),
      );

      AppLogger.info('Destination arrival timestamp saved: ${event.timestamp}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to mark arrival at destination: $e');
      AppLogger.error('Stack trace: $stackTrace');
      emit(RouteError(message: 'Failed to mark destination arrival.'));
    }
  }

  Future<void> _onCompleteRideWithTimestamp(
    CompleteRideWithTimestamp event,
    Emitter<RouteState> emit,
  ) async {
    try {
      AppLogger.info('Completing ride with timestamp: ${event.rideId}');

      if (_currentRoute == null) {
        emit(const RouteError(message: 'No active route found'));
        return;
      }

      final now = event.timestamp;

      // Find the ride and update with completion timestamp
      final updatedRides = _currentRoute!.rides.map((ride) {
        if (ride.id == event.rideId) {
          // Ensure all timeline steps are completed before marking as done
          final navigatedToDestination = ride.navigatedToDestinationAt ?? now;
          final arrivedAtDestination = ride.arrivedAtDestinationAt ?? now;

          return ride.copyWith(
            status: IndividualRideStatus.completed,
            navigatedToDestinationAt: navigatedToDestination,
            arrivedAtDestinationAt: arrivedAtDestination,
            rideCompletedAt: now,
            passengerNotes: event.notes,
          );
        }
        return ride;
      }).toList();

      _currentRoute = _currentRoute!.copyWith(rides: updatedRides);

      // Find the completed ride to add to history
      final completedRide = updatedRides.firstWhere(
        (ride) => ride.id == event.rideId,
      );

      // Create a route with just the completed ride for history
      final completedRideRoute = _currentRoute!.copyWith(
        rides: [completedRide],
        status: RouteStatus.completed,
        completedAt: now,
      );

      // Add the completed ride to history immediately
      await RideHistoryService.addToHistory(completedRideRoute);
      AppLogger.info(
        '✅ Completed ride added to local history: ${event.rideId}',
      );

      // 🔥 SAVE TO FIREBASE: Track ride completion
      try {
        await _firebaseIntegration.onRideCompleted(
          rideId: event.rideId,
          timestamp: now,
          additionalData: {
            'notes': event.notes,
          },
        );
        AppLogger.info('🔥 Ride completion saved to Firebase');
      } catch (firebaseError) {
        AppLogger.error('⚠️ Firebase tracking failed: $firebaseError');
      }

      // Check if all rides in route are completed
      final allCompleted = _currentRoute!.rides.every(
        (ride) => ride.status == IndividualRideStatus.completed,
      );

      if (allCompleted) {
        // All rides completed - stop GPS tracking and clear active ride
        await _stopGPSTracking();
        await RideHistoryService.clearActiveRide();
        _currentRoute = null;

        emit(
          RouteCompleted(
            route: completedRideRoute,
            message: 'Ride completed and saved to history!',
            completedAt: now,
          ),
        );
      } else {
        // Save updated active route (with remaining incomplete rides)
        await RideHistoryService.saveActiveRide(_currentRoute!);

        emit(
          IndividualRideUpdated(
            ride: completedRide,
            message: 'Ride completed and saved to history!',
          ),
        );
      }

      AppLogger.info('Ride completion timestamp saved: $now');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to complete ride with timestamp: $e');
      AppLogger.error('Stack trace: $stackTrace');
      emit(RouteError(message: 'Failed to complete ride.'));
    }
  }

  Future<void> _onCancelIndividualRide(
    CancelIndividualRide event,
    Emitter<RouteState> emit,
  ) async {
    if (_currentRoute == null) {
      emit(const RouteError(message: 'No active route found'));
      return;
    }

    try {
      AppLogger.info('🚫 Canceling individual ride: ${event.rideId}');
      AppLogger.info('📝 Cancellation reason: ${event.cancellationReason}');

      emit(
        RouteUpdating(
          currentRoute: _currentRoute!,
          action: 'Canceling ride...',
        ),
      );

      // Find the ride to cancel
      final rideIndex = _currentRoute!.rides.indexWhere(
        (ride) => ride.id == event.rideId,
      );

      if (rideIndex == -1) {
        throw Exception('Ride not found');
      }

      final canceledRide = _currentRoute!.rides[rideIndex];

      // Update ride status to cancelled
      final updatedRide = canceledRide.copyWith(
        status: IndividualRideStatus.cancelled,
        passengerNotes: 'Cancelled: ${event.cancellationReason}',
        updatedAt: event.cancelledAt,
      );

      // Update the route with the cancelled ride removed
      final updatedRides = List<IndividualRide>.from(_currentRoute!.rides);
      updatedRides.removeAt(
        rideIndex,
      ); // Remove the cancelled ride from active list

      _currentRoute = _currentRoute!.copyWith(rides: updatedRides);

      // Save updated route
      if (_currentRoute!.rides.isEmpty) {
        // If no rides left, clear active route
        await RideHistoryService.clearActiveRide();
        _currentRoute = null;
        emit(const RouteLoaded(activeRoute: null));
      } else {
        // Save updated route with remaining rides
        await RideHistoryService.saveActiveRide(_currentRoute!);
        emit(
          IndividualRideUpdated(
            ride: updatedRide,
            message: 'Ride cancelled: ${event.cancellationReason}',
          ),
        );
      }

      AppLogger.info('✅ Ride cancelled successfully: ${event.rideId}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cancel ride: $e');
      AppLogger.error('Stack trace: $stackTrace');
      emit(RouteError(message: 'Failed to cancel ride: $e'));
    }
  }

  Future<void> _onUpdateRideAddress(
    UpdateRideAddress event,
    Emitter<RouteState> emit,
  ) async {
    if (_currentRoute == null) {
      emit(const RouteError(message: 'No active route found'));
      return;
    }

    try {
      AppLogger.info('📍 Updating ride address: ${event.rideId}');

      emit(
        RouteUpdating(
          currentRoute: _currentRoute!,
          action: 'Updating address...',
        ),
      );

      // Find the ride to update
      final rideIndex = _currentRoute!.rides.indexWhere(
        (ride) => ride.id == event.rideId,
      );

      if (rideIndex == -1) {
        throw Exception('Ride not found');
      }

      final currentRide = _currentRoute!.rides[rideIndex];

      // Update the ride with new address information
      final updatedRide = currentRide.copyWith(
        pickupAddress: event.newPickupAddress ?? currentRide.pickupAddress,
        pickupLatitude: event.newPickupLatitude ?? currentRide.pickupLatitude,
        pickupLongitude:
            event.newPickupLongitude ?? currentRide.pickupLongitude,
        dropOffAddress: event.newDropOffAddress ?? currentRide.dropOffAddress,
        dropOffLatitude:
            event.newDropOffLatitude ?? currentRide.dropOffLatitude,
        dropOffLongitude:
            event.newDropOffLongitude ?? currentRide.dropOffLongitude,
      );

      // Update the route with the updated ride
      final updatedRides = List<IndividualRide>.from(_currentRoute!.rides);
      updatedRides[rideIndex] = updatedRide;

      _currentRoute = _currentRoute!.copyWith(rides: updatedRides);

      // Save updated route
      await RideHistoryService.saveActiveRide(_currentRoute!);

      // 🔥 SAVE TO FIREBASE: Track address changes
      try {
        if (event.newPickupAddress != null) {
          await _firebaseIntegration.onPickupAddressChanged(
            rideId: event.rideId,
            newAddress: event.newPickupAddress!,
            latitude: event.newPickupLatitude ?? 0.0,
            longitude: event.newPickupLongitude ?? 0.0,
          );
          AppLogger.info('🔥 Pickup address change saved to Firebase');
        }
        if (event.newDropOffAddress != null) {
          await _firebaseIntegration.onDropOffAddressChanged(
            rideId: event.rideId,
            newAddress: event.newDropOffAddress!,
            latitude: event.newDropOffLatitude ?? 0.0,
            longitude: event.newDropOffLongitude ?? 0.0,
          );
          AppLogger.info('🔥 Drop-off address change saved to Firebase');
        }
      } catch (firebaseError) {
        AppLogger.error('⚠️ Firebase tracking failed: $firebaseError');
      }

      emit(
        IndividualRideUpdated(
          ride: updatedRide,
          message: 'Ride address updated successfully',
        ),
      );

      AppLogger.info('✅ Ride address updated successfully: ${event.rideId}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update ride address: $e');
      AppLogger.error('Stack trace: $stackTrace');
      emit(RouteError(message: 'Failed to update ride address: $e'));
    }
  }
}
