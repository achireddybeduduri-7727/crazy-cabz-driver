import 'package:driver_app/core/services/ride_firebase_integration.dart';
import 'package:driver_app/shared/models/route_model.dart';

/// Example integration showing how to add Firebase tracking to your existing RouteBloc
/// Copy these patterns into your actual route_bloc.dart file

class RouteBloc_FirebaseIntegrationExample {
  final RideFirebaseIntegration _firebaseIntegration = RideFirebaseIntegration();

  // ============================================================
  // EXAMPLE 1: Save when manual ride is created
  // ============================================================
  Future<void> onCreateManualRide(RouteModel route, String driverId) async {
    // Your existing code to create route locally...
    
    // 🔥 ADD THIS: Save to Firebase automatically
    try {
      await _firebaseIntegration.onRideCreated(
        route: route,
        driverId: driverId,
      );
      print('✅ Ride saved to Firebase');
    } catch (e) {
      print('❌ Firebase save failed: $e');
      // Continue anyway - don't block local functionality
    }
  }

  // ============================================================
  // EXAMPLE 2: Save when driver navigates to pickup
  // ============================================================
  Future<void> onDriverNavigatesToPickup(String rideId) async {
    // Your existing navigation code...
    
    // 🔥 ADD THIS: Save action to Firebase
    try {
      await _firebaseIntegration.onNavigateToPickup(
        rideId: rideId,
        timestamp: DateTime.now(),
      );
      print('✅ Navigation action saved to Firebase');
    } catch (e) {
      print('❌ Firebase save failed: $e');
    }
  }

  // ============================================================
  // EXAMPLE 3: Save when driver arrives at pickup
  // ============================================================
  Future<void> onDriverArrivesAtPickup(String rideId) async {
    // Your existing arrival code...
    
    // 🔥 ADD THIS: Save action to Firebase
    try {
      await _firebaseIntegration.onArriveAtPickup(
        rideId: rideId,
        timestamp: DateTime.now(),
      );
      print('✅ Arrival saved to Firebase');
    } catch (e) {
      print('❌ Firebase save failed: $e');
    }
  }

  // ============================================================
  // EXAMPLE 4: Save when passenger is picked up
  // ============================================================
  Future<void> onPassengerPickedUp(String rideId) async {
    // Your existing pickup code...
    
    // 🔥 ADD THIS: Save action to Firebase
    try {
      await _firebaseIntegration.onPassengerPickedUp(
        rideId: rideId,
        timestamp: DateTime.now(),
      );
      print('✅ Pickup saved to Firebase');
    } catch (e) {
      print('❌ Firebase save failed: $e');
    }
  }

  // ============================================================
  // EXAMPLE 5: Save when ride is completed
  // ============================================================
  Future<void> onRideCompleted(String rideId, {double? distance, int? duration}) async {
    // Your existing completion code...
    
    // 🔥 ADD THIS: Save completion to Firebase
    try {
      await _firebaseIntegration.onRideCompleted(
        rideId: rideId,
        timestamp: DateTime.now(),
        distance: distance,
        duration: duration,
        additionalData: {
          'notes': 'Ride completed successfully',
        },
      );
      print('✅ Completion saved to Firebase');
    } catch (e) {
      print('❌ Firebase save failed: $e');
    }
  }

  // ============================================================
  // EXAMPLE 6: Save when pickup address is changed
  // ============================================================
  Future<void> onPickupAddressChanged({
    required String rideId,
    required String newAddress,
    required double latitude,
    required double longitude,
  }) async {
    // Your existing address update code...
    
    // 🔥 ADD THIS: Save change to Firebase
    try {
      await _firebaseIntegration.onPickupAddressChanged(
        rideId: rideId,
        newAddress: newAddress,
        latitude: latitude,
        longitude: longitude,
      );
      print('✅ Address change saved to Firebase');
    } catch (e) {
      print('❌ Firebase save failed: $e');
    }
  }

  // ============================================================
  // EXAMPLE 7: Save when pickup time is changed
  // ============================================================
  Future<void> onPickupTimeChanged({
    required String rideId,
    required DateTime newPickupTime,
  }) async {
    // Your existing time update code...
    
    // 🔥 ADD THIS: Save change to Firebase
    try {
      await _firebaseIntegration.onPickupTimeChanged(
        rideId: rideId,
        newPickupTime: newPickupTime,
      );
      print('✅ Time change saved to Firebase');
    } catch (e) {
      print('❌ Firebase save failed: $e');
    }
  }

  // ============================================================
  // EXAMPLE 8: Save GPS location updates
  // ============================================================
  Future<void> onLocationUpdate({
    required String rideId,
    required String driverId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
  }) async {
    // Your existing location tracking code...
    
    // 🔥 ADD THIS: Save GPS data to Firebase
    try {
      await _firebaseIntegration.onLocationUpdate(
        rideId: rideId,
        driverId: driverId,
        latitude: latitude,
        longitude: longitude,
        speed: speed,
        heading: heading,
      );
      // Don't print every time - too frequent
    } catch (e) {
      // Silent fail - GPS tracking shouldn't block app
    }
  }

  // ============================================================
  // EXAMPLE 9: Retrieve ride details from Firebase
  // ============================================================
  Future<Map<String, dynamic>?> getRideDetailsFromFirebase(String rideId) async {
    try {
      final details = await _firebaseIntegration.getRideDetails(rideId);
      print('📦 Retrieved ride details: ${details?['status']}');
      return details;
    } catch (e) {
      print('❌ Failed to retrieve ride: $e');
      return null;
    }
  }

  // ============================================================
  // EXAMPLE 10: Get full event timeline
  // ============================================================
  Future<List<Map<String, dynamic>>> getRideTimeline(String rideId) async {
    try {
      final timeline = await _firebaseIntegration.getRideTimeline(rideId);
      print('📅 Found ${timeline.length} events for ride');
      
      // Print timeline
      for (final event in timeline) {
        print('  ${event['eventType']} at ${event['timestamp']}');
      }
      
      return timeline;
    } catch (e) {
      print('❌ Failed to get timeline: $e');
      return [];
    }
  }
}

/// ============================================================
/// INTEGRATION PATTERN: Add to your RouteBloc event handlers
/// ============================================================

// In your actual route_bloc.dart file, add this at the top:
// final RideFirebaseIntegration _firebaseIntegration = RideFirebaseIntegration();

// Then in each event handler, add the Firebase call:

/*
Future<void> _onCreateManualRide(
  CreateManualRide event,
  Emitter<RouteState> emit,
) async {
  try {
    // Your existing code...
    final route = RouteModel(...);
    
    // 🔥 ADD THIS LINE
    await _firebaseIntegration.onRideCreated(
      route: route,
      driverId: currentDriverId,
    );
    
    // Rest of your existing code...
  } catch (e) {
    // Handle error
  }
}
*/

/*
Future<void> _onNavigateToPickup(
  NavigateToPickup event,
  Emitter<RouteState> emit,
) async {
  try {
    // Your existing code...
    
    // 🔥 ADD THIS LINE
    await _firebaseIntegration.onNavigateToPickup(
      rideId: event.ride.id,
      timestamp: DateTime.now(),
    );
    
    // Rest of your existing code...
  } catch (e) {
    // Handle error
  }
}
*/

// Repeat this pattern for all ride actions!
