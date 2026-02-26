import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

/// Comprehensive Ride Tracking Service
/// Automatically saves all ride events, updates, and details to Firebase
/// Tracks every action from ride creation to completion/cancellation
class RideTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

  // Collection names
  static const String ridesCollection = 'rides';
  static const String rideHistoryCollection = 'ride_history';
  static const String rideEventsCollection = 'ride_events';
  static const String gpsTrackingCollection = 'gps_tracking';

  /// Save a new ride when it's created
  /// This creates the initial ride record with all details
  Future<void> createRide({
    required String rideId,
    required String driverId,
    required String riderId,
    required Map<String, dynamic> rideDetails,
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      
      final rideData = {
        'rideId': rideId,
        'driverId': driverId,
        'riderId': riderId,
        'status': 'created',
        ...rideDetails,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'events': [],
      };

      // Save to Firestore for permanent storage
      await _firestore.collection(ridesCollection).doc(rideId).set(rideData);

      // Save to Realtime Database for live updates
      await _realtimeDb.ref('active_rides/$rideId').set({
        ...rideData,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      // Log the creation event
      await _logRideEvent(
        rideId: rideId,
        eventType: 'ride_created',
        eventData: {'details': rideDetails},
      );

      print('✅ Ride created and saved: $rideId');
    } catch (e) {
      print('❌ Error creating ride: $e');
      rethrow;
    }
  }

  /// Update ride when any detail changes (address, pickup time, drop time, etc.)
  Future<void> updateRideDetails({
    required String rideId,
    required Map<String, dynamic> updates,
    required String changeReason,
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      
      final updateData = {
        ...updates,
        'updatedAt': timestamp,
        'lastChangeReason': changeReason,
      };

      // Update Firestore
      await _firestore.collection(ridesCollection).doc(rideId).update(updateData);

      // Update Realtime Database
      await _realtimeDb.ref('active_rides/$rideId').update({
        ...updates,
        'updatedAt': ServerValue.timestamp,
      });

      // Log the update event
      await _logRideEvent(
        rideId: rideId,
        eventType: 'ride_updated',
        eventData: {
          'changes': updates,
          'reason': changeReason,
        },
      );

      print('✅ Ride updated: $rideId - $changeReason');
    } catch (e) {
      print('❌ Error updating ride: $e');
      rethrow;
    }
  }

  /// Save ride action (driver navigating, arriving, picking up, etc.)
  Future<void> saveRideAction({
    required String rideId,
    required String actionType,
    required Map<String, dynamic> actionData,
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();

      // Update ride status
      await _firestore.collection(ridesCollection).doc(rideId).update({
        'lastAction': actionType,
        'lastActionAt': timestamp,
        'updatedAt': timestamp,
      });

      // Update Realtime Database
      await _realtimeDb.ref('active_rides/$rideId').update({
        'lastAction': actionType,
        'lastActionAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      // Log the action event
      await _logRideEvent(
        rideId: rideId,
        eventType: actionType,
        eventData: actionData,
      );

      print('✅ Ride action saved: $rideId - $actionType');
    } catch (e) {
      print('❌ Error saving ride action: $e');
      rethrow;
    }
  }

  /// Save GPS tracking data during active ride
  Future<void> saveGPSTracking({
    required String rideId,
    required String driverId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
  }) async {
    try {
      final trackingData = {
        'rideId': rideId,
        'driverId': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'heading': heading,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save to Firestore (for history)
      await _firestore.collection(gpsTrackingCollection).add(trackingData);

      // Update current location in Realtime Database (for live tracking)
      await _realtimeDb.ref('live_tracking/$driverId').set({
        'rideId': rideId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'heading': heading,
        'timestamp': ServerValue.timestamp,
      });

      // Also update the ride's last known location
      await _firestore.collection(ridesCollection).doc(rideId).update({
        'currentLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });

    } catch (e) {
      print('❌ Error saving GPS tracking: $e');
      // Don't rethrow - GPS tracking failures shouldn't break the app
    }
  }

  /// Complete a ride and move to history
  Future<void> completeRide({
    required String rideId,
    required Map<String, dynamic> completionData,
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();

      // Get the full ride data
      final rideDoc = await _firestore.collection(ridesCollection).doc(rideId).get();
      final rideData = rideDoc.data();

      if (rideData == null) {
        throw Exception('Ride not found: $rideId');
      }

      // Update ride status to completed
      final completedRideData = {
        ...rideData,
        'status': 'completed',
        'completedAt': timestamp,
        'updatedAt': timestamp,
        ...completionData,
      };

      await _firestore.collection(ridesCollection).doc(rideId).update({
        'status': 'completed',
        'completedAt': timestamp,
        'updatedAt': timestamp,
        ...completionData,
      });

      // Move to ride history
      await _firestore.collection(rideHistoryCollection).doc(rideId).set(completedRideData);

      // Remove from active rides in Realtime Database
      await _realtimeDb.ref('active_rides/$rideId').remove();

      // Log completion event
      await _logRideEvent(
        rideId: rideId,
        eventType: 'ride_completed',
        eventData: completionData,
      );

      print('✅ Ride completed and moved to history: $rideId');
    } catch (e) {
      print('❌ Error completing ride: $e');
      rethrow;
    }
  }

  /// Cancel a ride and save cancellation details
  Future<void> cancelRide({
    required String rideId,
    required String cancelledBy,
    required String cancellationReason,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();

      // Get the full ride data
      final rideDoc = await _firestore.collection(ridesCollection).doc(rideId).get();
      final rideData = rideDoc.data();

      if (rideData == null) {
        throw Exception('Ride not found: $rideId');
      }

      // Update ride status to cancelled
      final cancelledRideData = {
        ...rideData,
        'status': 'cancelled',
        'cancelledAt': timestamp,
        'cancelledBy': cancelledBy,
        'cancellationReason': cancellationReason,
        'updatedAt': timestamp,
        if (additionalData != null) ...additionalData,
      };

      await _firestore.collection(ridesCollection).doc(rideId).update({
        'status': 'cancelled',
        'cancelledAt': timestamp,
        'cancelledBy': cancelledBy,
        'cancellationReason': cancellationReason,
        'updatedAt': timestamp,
        if (additionalData != null) ...additionalData,
      });

      // Move to ride history
      await _firestore.collection(rideHistoryCollection).doc(rideId).set(cancelledRideData);

      // Remove from active rides in Realtime Database
      await _realtimeDb.ref('active_rides/$rideId').remove();

      // Log cancellation event
      await _logRideEvent(
        rideId: rideId,
        eventType: 'ride_cancelled',
        eventData: {
          'cancelledBy': cancelledBy,
          'reason': cancellationReason,
          if (additionalData != null) ...additionalData,
        },
      );

      print('✅ Ride cancelled and moved to history: $rideId');
    } catch (e) {
      print('❌ Error cancelling ride: $e');
      rethrow;
    }
  }

  /// Log every ride event for detailed tracking
  Future<void> _logRideEvent({
    required String rideId,
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      await _firestore.collection(rideEventsCollection).add({
        'rideId': rideId,
        'eventType': eventType,
        'eventData': eventData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Also append to ride's events array
      await _firestore.collection(ridesCollection).doc(rideId).update({
        'events': FieldValue.arrayUnion([
          {
            'type': eventType,
            'data': eventData,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ]),
      });
    } catch (e) {
      print('❌ Error logging ride event: $e');
      // Don't rethrow - event logging failures shouldn't break the main flow
    }
  }

  /// Update pickup address
  Future<void> updatePickupAddress({
    required String rideId,
    required String newAddress,
    required double latitude,
    required double longitude,
  }) async {
    await updateRideDetails(
      rideId: rideId,
      updates: {
        'pickupAddress': newAddress,
        'pickupLatitude': latitude,
        'pickupLongitude': longitude,
      },
      changeReason: 'Pickup address changed',
    );
  }

  /// Update drop-off address
  Future<void> updateDropOffAddress({
    required String rideId,
    required String newAddress,
    required double latitude,
    required double longitude,
  }) async {
    await updateRideDetails(
      rideId: rideId,
      updates: {
        'dropOffAddress': newAddress,
        'dropOffLatitude': latitude,
        'dropOffLongitude': longitude,
      },
      changeReason: 'Drop-off address changed',
    );
  }

  /// Update pickup time
  Future<void> updatePickupTime({
    required String rideId,
    required DateTime newPickupTime,
  }) async {
    await updateRideDetails(
      rideId: rideId,
      updates: {
        'scheduledPickupTime': newPickupTime.toIso8601String(),
      },
      changeReason: 'Pickup time changed',
    );
  }

  /// Update drop-off time
  Future<void> updateDropOffTime({
    required String rideId,
    required DateTime newDropOffTime,
  }) async {
    await updateRideDetails(
      rideId: rideId,
      updates: {
        'scheduledDropOffTime': newDropOffTime.toIso8601String(),
      },
      changeReason: 'Drop-off time changed',
    );
  }

  /// Get complete ride details with all events
  Future<Map<String, dynamic>?> getRideDetails(String rideId) async {
    try {
      final rideDoc = await _firestore.collection(ridesCollection).doc(rideId).get();
      if (!rideDoc.exists) {
        // Check in history
        final historyDoc = await _firestore.collection(rideHistoryCollection).doc(rideId).get();
        return historyDoc.data();
      }
      return rideDoc.data();
    } catch (e) {
      print('❌ Error getting ride details: $e');
      return null;
    }
  }

  /// Get all events for a ride
  Future<List<Map<String, dynamic>>> getRideEvents(String rideId) async {
    try {
      final eventsSnapshot = await _firestore
          .collection(rideEventsCollection)
          .where('rideId', isEqualTo: rideId)
          .orderBy('timestamp', descending: false)
          .get();

      return eventsSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error getting ride events: $e');
      return [];
    }
  }

  /// Get GPS tracking history for a ride
  Future<List<Map<String, dynamic>>> getRideGPSTracking(String rideId) async {
    try {
      final trackingSnapshot = await _firestore
          .collection(gpsTrackingCollection)
          .where('rideId', isEqualTo: rideId)
          .orderBy('timestamp', descending: false)
          .get();

      return trackingSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error getting GPS tracking: $e');
      return [];
    }
  }

  /// Get active rides for a driver
  Future<List<Map<String, dynamic>>> getActiveRidesForDriver(String driverId) async {
    try {
      final ridesSnapshot = await _firestore
          .collection(ridesCollection)
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: ['created', 'accepted', 'in_progress'])
          .get();

      return ridesSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error getting active rides: $e');
      return [];
    }
  }

  /// Get ride history for a driver
  Future<List<Map<String, dynamic>>> getRideHistoryForDriver(String driverId) async {
    try {
      final historySnapshot = await _firestore
          .collection(rideHistoryCollection)
          .where('driverId', isEqualTo: driverId)
          .orderBy('completedAt', descending: true)
          .get();

      return historySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error getting ride history: $e');
      return [];
    }
  }
}
