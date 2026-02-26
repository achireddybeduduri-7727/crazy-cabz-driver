import 'package:driver_app/core/services/firestore_service.dart';

/// Quick setup to test Firebase data organization
/// Run this to create sample data in your Firebase project
class FirebaseSetupHelper {
  final FirestoreService _firestoreService = FirestoreService();

  /// Create sample data for testing
  Future<void> createSampleData() async {
    print('🚀 Creating sample data...\n');

    // 1. Create sample driver
    print('1️⃣ Creating sample driver...');
    await _firestoreService.saveDriver(
      driverId: 'driver_demo_001',
      driverData: {
        'name': 'Demo Driver',
        'email': 'demo.driver@example.com',
        'phone': '+1234567890',
        'vehicle': {
          'make': 'Toyota',
          'model': 'Prius',
          'year': 2022,
          'licensePlate': 'DEMO123',
          'color': 'White',
        },
        'rating': 4.9,
        'totalRides': 0,
        'status': 'active',
        'joinedDate': DateTime.now().toIso8601String(),
      },
    );
    print('✅ Sample driver created!\n');

    // 2. Create sample rider
    print('2️⃣ Creating sample rider...');
    await _firestoreService.saveRider(
      riderId: 'rider_demo_001',
      riderData: {
        'name': 'Demo Rider',
        'email': 'demo.rider@example.com',
        'phone': '+0987654321',
        'rating': 5.0,
        'totalRides': 0,
        'joinedDate': DateTime.now().toIso8601String(),
      },
    );
    print('✅ Sample rider created!\n');

    // 3. Create sample ride
    print('3️⃣ Creating sample ride...');
    final rideId = await _firestoreService.createRide(
      driverId: 'driver_demo_001',
      riderId: 'rider_demo_001',
      rideData: {
        'pickup': {
          'address': '123 Main Street, Demo City',
          'latitude': 40.7128,
          'longitude': -74.0060,
        },
        'dropoff': {
          'address': '456 Oak Avenue, Demo City',
          'latitude': 40.7589,
          'longitude': -73.9851,
        },
        'fare': 25.50,
        'distance': 5.2,
        'estimatedDuration': 15,
      },
    );
    print('✅ Sample ride created: $rideId\n');

    // 4. Create sample GPS tracking
    if (rideId != null) {
      print('4️⃣ Creating sample GPS tracking...');
      await _firestoreService.saveGPSLocation(
        rideId: rideId,
        driverId: 'driver_demo_001',
        latitude: 40.7128,
        longitude: -74.0060,
        additionalData: {
          'speed': 45.5,
          'heading': 180.0,
          'accuracy': 10.0,
        },
      );
      print('✅ Sample GPS tracking created!\n');

      // 5. Create sample notification
      print('5️⃣ Creating sample notification...');
      await _firestoreService.sendNotification(
        recipientId: 'rider_demo_001',
        type: 'ride_update',
        message: 'Your driver is on the way!',
        additionalData: {
          'rideId': rideId,
          'driverId': 'driver_demo_001',
          'driverName': 'Demo Driver',
        },
      );
      print('✅ Sample notification created!\n');
    }

    // 6. Create sample support ticket
    print('6️⃣ Creating sample support ticket...');
    final ticketId = await _firestoreService.createSupportTicket(
      userId: 'driver_demo_001',
      issue: 'Sample support issue',
      category: 'technical',
      description: 'This is a demo support ticket for testing purposes.',
      additionalData: {
        'deviceModel': 'Demo Device',
        'osVersion': 'Demo OS 1.0',
        'appVersion': '1.0.0',
      },
    );
    print('✅ Sample support ticket created: $ticketId\n');

    // 7. Create sample earnings
    if (rideId != null) {
      print('7️⃣ Creating sample earnings...');
      await _firestoreService.saveEarnings(
        driverId: 'driver_demo_001',
        rideId: rideId,
        amount: 25.50,
        additionalData: {
          'baseFare': 20.00,
          'tip': 5.50,
          'date': DateTime.now().toIso8601String(),
        },
      );
      print('✅ Sample earnings created!\n');
    }

    // 8. Create sample settings
    print('8️⃣ Creating sample settings...');
    await _firestoreService.saveSettings(
      userId: 'driver_demo_001',
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
    print('✅ Sample settings created!\n');

    // 9. Create sample manual ride
    print('9️⃣ Creating sample manual ride...');
    final manualRideId = await _firestoreService.createManualRide(
      driverId: 'driver_demo_001',
      rideData: {
        'date': DateTime.now().toIso8601String(),
        'pickup': '789 Pine Street, Demo City',
        'dropoff': '321 Elm Avenue, Demo City',
        'fare': 30.00,
        'distance': 6.0,
        'notes': 'Cash payment - demo ride',
      },
    );
    print('✅ Sample manual ride created: $manualRideId\n');

    print('🎉 All sample data created successfully!');
    print('\n📊 Check your Firebase Console to see the organized data:');
    print('   - Firestore: Collections for drivers, riders, rides, etc.');
    print('   - Storage: Folders for profile_pictures, ride_documents, etc.');
  }

  /// Verify the data structure
  Future<void> verifyDataStructure() async {
    print('\n🔍 Verifying data structure...\n');

    // Check driver
    final driver = await _firestoreService.getDriver('driver_demo_001');
    print('Driver data: ${driver != null ? "✅ Found" : "❌ Not found"}');

    // Check rider
    final rider = await _firestoreService.getRider('rider_demo_001');
    print('Rider data: ${rider != null ? "✅ Found" : "❌ Not found"}');

    // Check active rides
    final activeRides = await _firestoreService.getActiveRides('driver_demo_001');
    print('Active rides: ${activeRides.isNotEmpty ? "✅ Found (${activeRides.length})" : "❌ Not found"}');

    // Check ride history
    final rideHistory = await _firestoreService.getDriverRideHistory('driver_demo_001');
    print('Ride history: ${rideHistory.isNotEmpty ? "✅ Found (${rideHistory.length})" : "❌ Not found"}');

    // Check notifications
    final notifications = await _firestoreService.getNotifications('rider_demo_001');
    print('Notifications: ${notifications.isNotEmpty ? "✅ Found (${notifications.length})" : "❌ Not found"}');

    // Check support tickets
    final tickets = await _firestoreService.getSupportTickets('driver_demo_001');
    print('Support tickets: ${tickets.isNotEmpty ? "✅ Found (${tickets.length})" : "❌ Not found"}');

    // Check earnings
    final earnings = await _firestoreService.getDriverEarnings('driver_demo_001');
    print('Earnings: ${earnings.isNotEmpty ? "✅ Found (${earnings.length})" : "❌ Not found"}');

    // Check settings
    final settings = await _firestoreService.getSettings('driver_demo_001');
    print('Settings: ${settings != null ? "✅ Found" : "❌ Not found"}');

    // Check manual rides
    final manualRides = await _firestoreService.getManualRides('driver_demo_001');
    print('Manual rides: ${manualRides.isNotEmpty ? "✅ Found (${manualRides.length})" : "❌ Not found"}');

    print('\n✅ Data structure verification complete!');
  }

  /// Display summary of collections
  Future<void> displayCollectionsSummary() async {
    print('\n📋 Collections Summary:\n');
    print('Collection Name          | Purpose');
    print('-------------------------|----------------------------------');
    print('drivers                  | Driver profiles and settings');
    print('riders                   | Rider profiles and settings');
    print('rides                    | Active and completed rides');
    print('gps_tracking            | Live GPS location logs');
    print('ride_history            | Completed rides per driver/rider');
    print('notifications           | All app notifications');
    print('support_tickets         | Support requests and logs');
    print('earnings                | Driver earnings records');
    print('settings                | App settings for each user');
    print('manual_rides            | Manually entered ride data');
    
    print('\n📁 Storage Folders:\n');
    print('Folder Path                      | Purpose');
    print('---------------------------------|----------------------------------');
    print('/profile_pictures/drivers/       | Driver profile images');
    print('/profile_pictures/riders/        | Rider profile images');
    print('/ride_documents/                 | Ride receipts and documents');
    print('/company_files/                  | Company terms and policies');
    print('/chat_attachments/               | Chat images and files');
    print('/support_attachments/            | Support ticket attachments');
  }

  /// Run complete setup
  Future<void> runCompleteSetup() async {
    print('═══════════════════════════════════════════════════════════');
    print('   Firebase Data Organization Setup');
    print('═══════════════════════════════════════════════════════════\n');

    await displayCollectionsSummary();
    await createSampleData();
    await verifyDataStructure();

    print('\n═══════════════════════════════════════════════════════════');
    print('   Setup Complete! 🎉');
    print('═══════════════════════════════════════════════════════════\n');
    print('Next steps:');
    print('1. Open Firebase Console: https://console.firebase.google.com');
    print('2. Navigate to Firestore Database to see collections');
    print('3. Navigate to Storage to see folder structure');
    print('4. Review the data organization in each collection');
    print('\nFor more details, check: FIREBASE_DATA_ORGANIZATION.md');
  }
}
