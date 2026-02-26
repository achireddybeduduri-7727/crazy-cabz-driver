# 🚀 Quick Integration Reference Card

## Add to RouteBloc (One Time)

```dart
import 'package:driver_app/core/services/ride_firebase_integration.dart';

final RideFirebaseIntegration _firebaseIntegration = RideFirebaseIntegration();
```

---

## Copy-Paste Integration Lines

### 📝 Ride Created
```dart
await _firebaseIntegration.onRideCreated(
  route: route,
  driverId: currentDriverId,
);
```

### 🚗 Navigate to Pickup
```dart
await _firebaseIntegration.onNavigateToPickup(
  rideId: rideId,
  timestamp: DateTime.now(),
);
```

### 📍 Arrive at Pickup
```dart
await _firebaseIntegration.onArriveAtPickup(
  rideId: rideId,
  timestamp: DateTime.now(),
);
```

### 👤 Passenger Picked Up
```dart
await _firebaseIntegration.onPassengerPickedUp(
  rideId: rideId,
  timestamp: DateTime.now(),
);
```

### 🎯 Navigate to Destination
```dart
await _firebaseIntegration.onNavigateToDestination(
  rideId: rideId,
  timestamp: DateTime.now(),
);
```

### 🏁 Arrive at Destination
```dart
await _firebaseIntegration.onArriveAtDestination(
  rideId: rideId,
  timestamp: DateTime.now(),
);
```

### ✅ Ride Completed
```dart
await _firebaseIntegration.onRideCompleted(
  rideId: rideId,
  timestamp: DateTime.now(),
  distance: totalDistance,
  duration: totalDuration,
);
```

### ❌ Ride Cancelled
```dart
await _firebaseIntegration.onRideCancelled(
  rideId: rideId,
  cancelledBy: 'driver',
  reason: 'Customer no-show',
);
```

### 📍 Pickup Address Changed
```dart
await _firebaseIntegration.onPickupAddressChanged(
  rideId: rideId,
  newAddress: newAddress,
  latitude: lat,
  longitude: lng,
);
```

### 🏠 Drop-off Address Changed
```dart
await _firebaseIntegration.onDropOffAddressChanged(
  rideId: rideId,
  newAddress: newAddress,
  latitude: lat,
  longitude: lng,
);
```

### ⏰ Pickup Time Changed
```dart
await _firebaseIntegration.onPickupTimeChanged(
  rideId: rideId,
  newPickupTime: newTime,
);
```

### 📱 GPS Location Update (Continuous)
```dart
await _firebaseIntegration.onLocationUpdate(
  rideId: rideId,
  driverId: driverId,
  latitude: position.latitude,
  longitude: position.longitude,
  speed: position.speed,
  heading: position.heading,
);
```

---

## Retrieve Data

### Get Ride Details
```dart
final details = await _firebaseIntegration.getRideDetails(rideId);
```

### Get Event Timeline
```dart
final timeline = await _firebaseIntegration.getRideTimeline(rideId);
```

### Get GPS Route
```dart
final route = await _firebaseIntegration.getRideRoute(rideId);
```

---

## That's It! 🎉

Just add one line for each action and everything is automatically saved to Firebase!
