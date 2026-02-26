import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive Firestore service for organizing data into separate collections
/// Each feature has its own collection for easy access and scalability
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String driversCollection = 'drivers';
  static const String ridersCollection = 'riders';
  static const String ridesCollection = 'rides';
  static const String gpsTrackingCollection = 'gps_tracking';
  static const String rideHistoryCollection = 'ride_history';
  static const String notificationsCollection = 'notifications';
  static const String supportTicketsCollection = 'support_tickets';
  static const String earningsCollection = 'earnings';
  static const String settingsCollection = 'settings';
  static const String manualRidesCollection = 'manual_rides';

  // ==================== DRIVERS ====================
  
  /// Add or update a driver profile
  Future<void> saveDriver({
    required String driverId,
    required Map<String, dynamic> driverData,
  }) async {
    try {
      await _firestore.collection(driversCollection).doc(driverId).set(
        {
          ...driverData,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('✅ Driver saved: $driverId');
    } catch (e) {
      print('❌ Error saving driver: $e');
      rethrow;
    }
  }

  /// Get a driver profile
  Future<Map<String, dynamic>?> getDriver(String driverId) async {
    try {
      final doc = await _firestore.collection(driversCollection).doc(driverId).get();
      return doc.data();
    } catch (e) {
      print('❌ Error getting driver: $e');
      return null;
    }
  }

  // ==================== RIDERS ====================
  
  /// Add or update a rider profile
  Future<void> saveRider({
    required String riderId,
    required Map<String, dynamic> riderData,
  }) async {
    try {
      await _firestore.collection(ridersCollection).doc(riderId).set(
        {
          ...riderData,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('✅ Rider saved: $riderId');
    } catch (e) {
      print('❌ Error saving rider: $e');
      rethrow;
    }
  }

  /// Get a rider profile
  Future<Map<String, dynamic>?> getRider(String riderId) async {
    try {
      final doc = await _firestore.collection(ridersCollection).doc(riderId).get();
      return doc.data();
    } catch (e) {
      print('❌ Error getting rider: $e');
      return null;
    }
  }

  // ==================== RIDES ====================
  
  /// Create a new ride
  Future<String?> createRide({
    required String driverId,
    required String riderId,
    required Map<String, dynamic> rideData,
  }) async {
    try {
      final docRef = await _firestore.collection(ridesCollection).add({
        'driverId': driverId,
        'riderId': riderId,
        ...rideData,
        'status': 'active',
        'startTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Ride created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating ride: $e');
      return null;
    }
  }

  /// Update a ride
  Future<void> updateRide({
    required String rideId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore.collection(ridesCollection).doc(rideId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Ride updated: $rideId');
    } catch (e) {
      print('❌ Error updating ride: $e');
      rethrow;
    }
  }

  /// Get a ride
  Future<Map<String, dynamic>?> getRide(String rideId) async {
    try {
      final doc = await _firestore.collection(ridesCollection).doc(rideId).get();
      return doc.data();
    } catch (e) {
      print('❌ Error getting ride: $e');
      return null;
    }
  }

  /// Get active rides for a driver
  Future<List<Map<String, dynamic>>> getActiveRides(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection(ridesCollection)
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'active')
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Error getting active rides: $e');
      return [];
    }
  }

  // ==================== GPS TRACKING ====================
  
  /// Save GPS location for a ride
  Future<void> saveGPSLocation({
    required String rideId,
    required String driverId,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore.collection(gpsTrackingCollection).add({
        'rideId': rideId,
        'driverId': driverId,
        'location': GeoPoint(latitude, longitude),
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
        ...?additionalData,
      });
      print('✅ GPS location saved for ride: $rideId');
    } catch (e) {
      print('❌ Error saving GPS location: $e');
      rethrow;
    }
  }

  /// Get GPS tracking history for a ride
  Future<List<Map<String, dynamic>>> getGPSTrackingHistory(String rideId) async {
    try {
      final snapshot = await _firestore
          .collection(gpsTrackingCollection)
          .where('rideId', isEqualTo: rideId)
          .orderBy('timestamp', descending: false)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Error getting GPS tracking history: $e');
      return [];
    }
  }

  // ==================== RIDE HISTORY ====================
  
  /// Save completed ride to history
  Future<void> saveRideHistory({
    required String rideId,
    required String driverId,
    required String riderId,
    required Map<String, dynamic> rideData,
  }) async {
    try {
      await _firestore.collection(rideHistoryCollection).doc(rideId).set({
        'rideId': rideId,
        'driverId': driverId,
        'riderId': riderId,
        ...rideData,
        'completedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Ride history saved: $rideId');
    } catch (e) {
      print('❌ Error saving ride history: $e');
      rethrow;
    }
  }

  /// Get ride history for a driver
  Future<List<Map<String, dynamic>>> getDriverRideHistory(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection(rideHistoryCollection)
          .where('driverId', isEqualTo: driverId)
          .orderBy('completedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Error getting driver ride history: $e');
      return [];
    }
  }

  // ==================== NOTIFICATIONS ====================
  
  /// Send a notification
  Future<void> sendNotification({
    required String recipientId,
    required String type,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore.collection(notificationsCollection).add({
        'recipientId': recipientId,
        'type': type,
        'message': message,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        ...?additionalData,
      });
      print('✅ Notification sent to: $recipientId');
    } catch (e) {
      print('❌ Error sending notification: $e');
      rethrow;
    }
  }

  /// Get notifications for a user
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(notificationsCollection)
          .where('recipientId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection(notificationsCollection).doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // ==================== SUPPORT TICKETS ====================
  
  /// Create a support ticket
  Future<String?> createSupportTicket({
    required String userId,
    required String issue,
    required String category,
    String? description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final docRef = await _firestore.collection(supportTicketsCollection).add({
        'userId': userId,
        'issue': issue,
        'category': category,
        'description': description,
        'status': 'open',
        'priority': 'normal',
        'createdAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      });
      print('✅ Support ticket created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating support ticket: $e');
      return null;
    }
  }

  /// Update support ticket status
  Future<void> updateSupportTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    try {
      await _firestore.collection(supportTicketsCollection).doc(ticketId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Support ticket status updated: $ticketId');
    } catch (e) {
      print('❌ Error updating support ticket: $e');
      rethrow;
    }
  }

  /// Get support tickets for a user
  Future<List<Map<String, dynamic>>> getSupportTickets(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(supportTicketsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Error getting support tickets: $e');
      return [];
    }
  }

  // ==================== EARNINGS ====================
  
  /// Save earnings record
  Future<void> saveEarnings({
    required String driverId,
    required String rideId,
    required double amount,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore.collection(earningsCollection).add({
        'driverId': driverId,
        'rideId': rideId,
        'amount': amount,
        'currency': 'USD',
        'timestamp': FieldValue.serverTimestamp(),
        ...?additionalData,
      });
      print('✅ Earnings saved for driver: $driverId');
    } catch (e) {
      print('❌ Error saving earnings: $e');
      rethrow;
    }
  }

  /// Get earnings for a driver
  Future<List<Map<String, dynamic>>> getDriverEarnings(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection(earningsCollection)
          .where('driverId', isEqualTo: driverId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Error getting driver earnings: $e');
      return [];
    }
  }

  // ==================== SETTINGS ====================
  
  /// Save user settings
  Future<void> saveSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await _firestore.collection(settingsCollection).doc(userId).set(
        {
          ...settings,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('✅ Settings saved for user: $userId');
    } catch (e) {
      print('❌ Error saving settings: $e');
      rethrow;
    }
  }

  /// Get user settings
  Future<Map<String, dynamic>?> getSettings(String userId) async {
    try {
      final doc = await _firestore.collection(settingsCollection).doc(userId).get();
      return doc.data();
    } catch (e) {
      print('❌ Error getting settings: $e');
      return null;
    }
  }

  // ==================== MANUAL RIDES ====================
  
  /// Create a manual ride entry
  Future<String?> createManualRide({
    required String driverId,
    required Map<String, dynamic> rideData,
  }) async {
    try {
      final docRef = await _firestore.collection(manualRidesCollection).add({
        'driverId': driverId,
        ...rideData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Manual ride created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating manual ride: $e');
      return null;
    }
  }

  /// Get manual rides for a driver
  Future<List<Map<String, dynamic>>> getManualRides(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection(manualRidesCollection)
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Error getting manual rides: $e');
      return [];
    }
  }
}
