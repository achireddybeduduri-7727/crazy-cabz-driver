import 'package:driver_app/core/services/firestore_service.dart';
import 'package:driver_app/core/services/firebase_storage_service.dart';
import 'dart:io';

/// Example usage of Firestore and Storage services
/// This file demonstrates how to save data to organized collections and folders

class FirebaseDataExamples {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  // ==================== DRIVER EXAMPLES ====================

  /// Example: Save a new driver profile
  Future<void> saveDriverExample() async {
    await _firestoreService.saveDriver(
      driverId: 'driver_123',
      driverData: {
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'phone': '+1234567890',
        'vehicle': {
          'make': 'Toyota',
          'model': 'Prius',
          'year': 2022,
          'licensePlate': 'ABC123',
        },
        'rating': 4.8,
        'totalRides': 150,
        'status': 'active',
      },
    );
  }

  /// Example: Upload driver profile picture
  Future<void> uploadDriverProfilePictureExample(File imageFile) async {
    final url = await _storageService.uploadDriverProfilePicture(
      driverId: 'driver_123',
      file: imageFile,
      extension: 'jpg',
    );
    
    if (url != null) {
      // Update driver profile with image URL
      await _firestoreService.saveDriver(
        driverId: 'driver_123',
        driverData: {
          'profilePictureUrl': url,
        },
      );
    }
  }

  // ==================== RIDE EXAMPLES ====================

  /// Example: Create a new ride
  Future<String?> createRideExample() async {
    final rideId = await _firestoreService.createRide(
      driverId: 'driver_123',
      riderId: 'rider_456',
      rideData: {
        'pickup': {
          'address': '123 Main St, City',
          'latitude': 40.7128,
          'longitude': -74.0060,
        },
        'dropoff': {
          'address': '456 Oak Ave, City',
          'latitude': 40.7589,
          'longitude': -73.9851,
        },
        'fare': 25.50,
        'distance': 5.2, // in km
        'estimatedDuration': 15, // in minutes
      },
    );
    
    return rideId;
  }

  /// Example: Track GPS location during a ride
  Future<void> trackGPSExample(String rideId) async {
    await _firestoreService.saveGPSLocation(
      rideId: rideId,
      driverId: 'driver_123',
      latitude: 40.7128,
      longitude: -74.0060,
      additionalData: {
        'speed': 45.5, // km/h
        'heading': 180.0, // degrees
        'accuracy': 10.0, // meters
      },
    );
  }

  /// Example: Complete a ride and save to history
  Future<void> completeRideExample(String rideId) async {
    // Update ride status
    await _firestoreService.updateRide(
      rideId: rideId,
      updates: {
        'status': 'completed',
        'endTime': DateTime.now().toIso8601String(),
        'actualFare': 27.00,
        'tip': 5.00,
      },
    );
    
    // Save to ride history
    await _firestoreService.saveRideHistory(
      rideId: rideId,
      driverId: 'driver_123',
      riderId: 'rider_456',
      rideData: {
        'fare': 27.00,
        'tip': 5.00,
        'totalEarnings': 32.00,
        'distance': 5.2,
        'duration': 18, // actual duration in minutes
        'rating': 5,
      },
    );
    
    // Save earnings
    await _firestoreService.saveEarnings(
      driverId: 'driver_123',
      rideId: rideId,
      amount: 32.00,
      additionalData: {
        'baseFare': 27.00,
        'tip': 5.00,
        'date': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==================== NOTIFICATION EXAMPLES ====================

  /// Example: Send ride notification
  Future<void> sendRideNotificationExample() async {
    await _firestoreService.sendNotification(
      recipientId: 'rider_456',
      type: 'ride_update',
      message: 'Your driver is 2 minutes away!',
      additionalData: {
        'rideId': 'ride_789',
        'driverId': 'driver_123',
        'driverName': 'John Doe',
        'estimatedArrival': DateTime.now().add(Duration(minutes: 2)).toIso8601String(),
      },
    );
  }

  /// Example: Send support notification
  Future<void> sendSupportNotificationExample() async {
    await _firestoreService.sendNotification(
      recipientId: 'driver_123',
      type: 'support_update',
      message: 'Your support ticket has been resolved',
      additionalData: {
        'ticketId': 'ticket_101',
        'resolution': 'Issue has been fixed in the latest update',
      },
    );
  }

  // ==================== SUPPORT EXAMPLES ====================

  /// Example: Create a support ticket
  Future<void> createSupportTicketExample() async {
    final ticketId = await _firestoreService.createSupportTicket(
      userId: 'driver_123',
      issue: 'App crashes when accepting a ride',
      category: 'technical',
      description: 'The app crashes immediately when I try to accept a new ride request.',
      additionalData: {
        'deviceModel': 'iPhone 13',
        'osVersion': 'iOS 16.5',
        'appVersion': '1.0.0',
      },
    );
    
    print('Support ticket created: $ticketId');
  }

  /// Example: Upload support attachment
  Future<void> uploadSupportAttachmentExample(String ticketId, File screenshotFile) async {
    final url = await _storageService.uploadSupportAttachment(
      ticketId: ticketId,
      file: screenshotFile,
      fileName: 'crash_screenshot.png',
    );
    
    if (url != null) {
      print('Support attachment uploaded: $url');
    }
  }

  // ==================== MANUAL RIDE EXAMPLES ====================

  /// Example: Create a manual ride entry
  Future<void> createManualRideExample() async {
    final manualRideId = await _firestoreService.createManualRide(
      driverId: 'driver_123',
      rideData: {
        'date': DateTime.now().toIso8601String(),
        'pickup': '123 Main St',
        'dropoff': '456 Oak Ave',
        'fare': 30.00,
        'distance': 6.0,
        'notes': 'Cash payment received',
      },
    );
    
    print('Manual ride created: $manualRideId');
  }

  // ==================== SETTINGS EXAMPLES ====================

  /// Example: Save user settings
  Future<void> saveSettingsExample() async {
    await _firestoreService.saveSettings(
      userId: 'driver_123',
      settings: {
        'notifications': {
          'pushEnabled': true,
          'emailEnabled': false,
          'smsEnabled': true,
        },
        'preferences': {
          'language': 'en',
          'currency': 'USD',
          'distanceUnit': 'km',
        },
        'privacy': {
          'shareLocation': true,
          'showProfilePicture': true,
        },
      },
    );
  }

  // ==================== QUERY EXAMPLES ====================

  /// Example: Get driver's ride history
  Future<void> getDriverRideHistoryExample() async {
    final rideHistory = await _firestoreService.getDriverRideHistory('driver_123');
    
    print('Total rides: ${rideHistory.length}');
    for (var ride in rideHistory) {
      print('Ride ${ride['id']}: ${ride['pickup']} -> ${ride['dropoff']}');
    }
  }

  /// Example: Get driver's earnings
  Future<void> getDriverEarningsExample() async {
    final earnings = await _firestoreService.getDriverEarnings('driver_123');
    
    double totalEarnings = 0;
    for (var earning in earnings) {
      totalEarnings += earning['amount'] as double;
    }
    
    print('Total earnings: \$${totalEarnings.toStringAsFixed(2)}');
  }

  /// Example: Get notifications for a user
  Future<void> getNotificationsExample() async {
    final notifications = await _firestoreService.getNotifications('driver_123');
    
    print('Total notifications: ${notifications.length}');
    for (var notification in notifications) {
      print('${notification['type']}: ${notification['message']}');
      
      // Mark as read
      if (notification['isRead'] == false) {
        await _firestoreService.markNotificationAsRead(notification['id']);
      }
    }
  }

  /// Example: Get active rides for a driver
  Future<void> getActiveRidesExample() async {
    final activeRides = await _firestoreService.getActiveRides('driver_123');
    
    print('Active rides: ${activeRides.length}');
    for (var ride in activeRides) {
      print('Ride ${ride['id']}: ${ride['status']}');
    }
  }

  // ==================== COMPLETE WORKFLOW EXAMPLE ====================

  /// Example: Complete ride workflow from start to finish
  Future<void> completeRideWorkflowExample() async {
    // 1. Create a new ride
    final rideId = await _firestoreService.createRide(
      driverId: 'driver_123',
      riderId: 'rider_456',
      rideData: {
        'pickup': {
          'address': '123 Main St, City',
          'latitude': 40.7128,
          'longitude': -74.0060,
        },
        'dropoff': {
          'address': '456 Oak Ave, City',
          'latitude': 40.7589,
          'longitude': -73.9851,
        },
        'fare': 25.50,
      },
    );
    
    if (rideId == null) return;
    
    // 2. Send notification to rider
    await _firestoreService.sendNotification(
      recipientId: 'rider_456',
      type: 'ride_started',
      message: 'Your ride has started!',
      additionalData: {'rideId': rideId},
    );
    
    // 3. Track GPS during ride (simulate multiple points)
    for (int i = 0; i < 5; i++) {
      await _firestoreService.saveGPSLocation(
        rideId: rideId,
        driverId: 'driver_123',
        latitude: 40.7128 + (i * 0.01),
        longitude: -74.0060 + (i * 0.01),
        additionalData: {
          'speed': 50.0,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      await Future.delayed(Duration(seconds: 30)); // Track every 30 seconds
    }
    
    // 4. Complete the ride
    await _firestoreService.updateRide(
      rideId: rideId,
      updates: {
        'status': 'completed',
        'endTime': DateTime.now().toIso8601String(),
        'actualFare': 27.00,
      },
    );
    
    // 5. Save to ride history
    await _firestoreService.saveRideHistory(
      rideId: rideId,
      driverId: 'driver_123',
      riderId: 'rider_456',
      rideData: {
        'fare': 27.00,
        'distance': 5.2,
        'duration': 18,
      },
    );
    
    // 6. Save earnings
    await _firestoreService.saveEarnings(
      driverId: 'driver_123',
      rideId: rideId,
      amount: 27.00,
    );
    
    // 7. Send completion notification
    await _firestoreService.sendNotification(
      recipientId: 'rider_456',
      type: 'ride_completed',
      message: 'Your ride is complete. Thank you!',
      additionalData: {
        'rideId': rideId,
        'fare': 27.00,
      },
    );
    
    print('✅ Complete ride workflow finished!');
  }
}
