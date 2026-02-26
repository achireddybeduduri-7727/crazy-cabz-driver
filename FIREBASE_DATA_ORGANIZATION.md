# Firebase Data Organization Guide

This guide explains how to organize and save data to Firebase in your Driver App, with separate collections and folders for each feature.

## 📁 Firestore Collections Structure

### 1. **drivers** Collection
Stores driver profiles and settings.

```dart
await FirestoreService().saveDriver(
  driverId: 'driver_123',
  driverData: {
    'name': 'John Doe',
    'email': 'john@example.com',
    'phone': '+1234567890',
    'vehicle': {
      'make': 'Toyota',
      'model': 'Prius',
      'year': 2022,
      'licensePlate': 'ABC123',
    },
    'rating': 4.8,
    'status': 'active',
  },
);
```

### 2. **riders** Collection
Stores rider profiles and settings.

```dart
await FirestoreService().saveRider(
  riderId: 'rider_456',
  riderData: {
    'name': 'Jane Smith',
    'email': 'jane@example.com',
    'phone': '+0987654321',
  },
);
```

### 3. **rides** Collection
Stores active and completed rides.

```dart
final rideId = await FirestoreService().createRide(
  driverId: 'driver_123',
  riderId: 'rider_456',
  rideData: {
    'pickup': {
      'address': '123 Main St',
      'latitude': 40.7128,
      'longitude': -74.0060,
    },
    'dropoff': {
      'address': '456 Oak Ave',
      'latitude': 40.7589,
      'longitude': -73.9851,
    },
    'fare': 25.50,
    'status': 'active',
  },
);
```

### 4. **gps_tracking** Collection
Stores live GPS location logs for each ride.

```dart
await FirestoreService().saveGPSLocation(
  rideId: rideId,
  driverId: 'driver_123',
  latitude: 40.7128,
  longitude: -74.0060,
  additionalData: {
    'speed': 45.5,
    'heading': 180.0,
  },
);
```

### 5. **ride_history** Collection
Stores completed rides for each driver/rider.

```dart
await FirestoreService().saveRideHistory(
  rideId: rideId,
  driverId: 'driver_123',
  riderId: 'rider_456',
  rideData: {
    'fare': 27.00,
    'distance': 5.2,
    'duration': 18,
    'rating': 5,
  },
);
```

### 6. **notifications** Collection
Stores all app notifications.

```dart
await FirestoreService().sendNotification(
  recipientId: 'rider_456',
  type: 'ride_update',
  message: 'Your driver is 2 minutes away!',
  additionalData: {
    'rideId': rideId,
    'driverId': 'driver_123',
  },
);
```

### 7. **support_tickets** Collection
Stores support requests and logs.

```dart
final ticketId = await FirestoreService().createSupportTicket(
  userId: 'driver_123',
  issue: 'App crashes when accepting a ride',
  category: 'technical',
  description: 'Detailed description...',
);
```

### 8. **earnings** Collection
Stores driver earnings records.

```dart
await FirestoreService().saveEarnings(
  driverId: 'driver_123',
  rideId: rideId,
  amount: 32.00,
  additionalData: {
    'baseFare': 27.00,
    'tip': 5.00,
  },
);
```

### 9. **settings** Collection
Stores app settings for each user.

```dart
await FirestoreService().saveSettings(
  userId: 'driver_123',
  settings: {
    'notifications': {
      'pushEnabled': true,
      'emailEnabled': false,
    },
    'preferences': {
      'language': 'en',
      'currency': 'USD',
    },
  },
);
```

### 10. **manual_rides** Collection
Stores manually entered ride data.

```dart
final manualRideId = await FirestoreService().createManualRide(
  driverId: 'driver_123',
  rideData: {
    'date': DateTime.now().toIso8601String(),
    'pickup': '123 Main St',
    'dropoff': '456 Oak Ave',
    'fare': 30.00,
  },
);
```

---

## 📂 Firebase Storage Folder Structure

### 1. **/profile_pictures/drivers/**
Stores driver profile pictures.

```dart
final url = await FirebaseStorageService().uploadDriverProfilePicture(
  driverId: 'driver_123',
  file: imageFile,
  extension: 'jpg',
);
```

### 2. **/profile_pictures/riders/**
Stores rider profile pictures.

```dart
final url = await FirebaseStorageService().uploadRiderProfilePicture(
  riderId: 'rider_456',
  file: imageFile,
  extension: 'jpg',
);
```

### 3. **/ride_documents/**
Stores documents related to rides (receipts, invoices).

```dart
final url = await FirebaseStorageService().uploadRideDocument(
  rideId: rideId,
  file: documentFile,
  fileName: 'receipt.pdf',
);
```

### 4. **/company_files/**
Stores company-related files (terms, policies).

```dart
final url = await FirebaseStorageService().uploadCompanyFile(
  fileName: 'terms_of_service.pdf',
  file: documentFile,
);
```

### 5. **/chat_attachments/**
Stores files sent in chat (images, audio).

```dart
final url = await FirebaseStorageService().uploadChatAttachment(
  chatId: 'chat_789',
  messageId: 'msg_101',
  file: imageFile,
  fileName: 'photo.jpg',
);
```

### 6. **/support_attachments/**
Stores files attached to support tickets.

```dart
final url = await FirebaseStorageService().uploadSupportAttachment(
  ticketId: ticketId,
  file: screenshotFile,
  fileName: 'screenshot.png',
);
```

---

## 🚀 How to Use

### Step 1: Import the Services

```dart
import 'package:driver_app/core/services/firestore_service.dart';
import 'package:driver_app/core/services/firebase_storage_service.dart';
```

### Step 2: Initialize Services

```dart
final firestoreService = FirestoreService();
final storageService = FirebaseStorageService();
```

### Step 3: Save Data

Use the appropriate method for each feature:

```dart
// Save a driver
await firestoreService.saveDriver(driverId: '...', driverData: {...});

// Create a ride
final rideId = await firestoreService.createRide(
  driverId: '...',
  riderId: '...',
  rideData: {...},
);

// Track GPS
await firestoreService.saveGPSLocation(
  rideId: rideId,
  driverId: '...',
  latitude: 40.7128,
  longitude: -74.0060,
);

// Upload a file
final url = await storageService.uploadDriverProfilePicture(
  driverId: '...',
  file: imageFile,
);
```

### Step 4: Query Data

```dart
// Get driver ride history
final rideHistory = await firestoreService.getDriverRideHistory('driver_123');

// Get notifications
final notifications = await firestoreService.getNotifications('driver_123');

// Get earnings
final earnings = await firestoreService.getDriverEarnings('driver_123');
```

---

## ✅ Benefits of This Structure

1. **Organized**: Each feature has its own collection/folder.
2. **Scalable**: Easy to add new features or modify existing ones.
3. **Efficient**: Queries are fast because data is separated.
4. **Maintainable**: Easy to understand and manage.
5. **Integration-Ready**: Data is structured for easy integration between apps.

---

## 📝 Example: Complete Ride Workflow

```dart
// 1. Create a ride
final rideId = await firestoreService.createRide(...);

// 2. Track GPS during ride
await firestoreService.saveGPSLocation(...);

// 3. Send notifications
await firestoreService.sendNotification(...);

// 4. Complete the ride
await firestoreService.updateRide(rideId: rideId, updates: {'status': 'completed'});

// 5. Save to history
await firestoreService.saveRideHistory(...);

// 6. Save earnings
await firestoreService.saveEarnings(...);
```

---

## 🔗 Integration with Tracking App

All data is organized with unique IDs (driverId, riderId, rideId) that can be used to:
- Sync data between Driver App and Tracking App
- Query specific data for each driver or rider
- Track live location and ride progress
- Access complete ride history and earnings

---

## 📚 Next Steps

1. Check the example file: `lib/core/services/firebase_data_examples.dart`
2. Use the services in your app features
3. Test by creating sample data
4. Verify in Firebase Console that data is organized correctly

---

**All services are ready to use!** 🎉
