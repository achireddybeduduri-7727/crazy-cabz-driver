# Automatic Ride Tracking to Firebase

## Overview
This system automatically saves all ride data to Firebase at every stage, from creation to completion/cancellation. Every action is tracked and stored with full details.

## What Gets Saved Automatically

### 1. **When Ride is Created**
- Complete ride details
- Driver ID, Rider ID, Route ID
- Pickup address, coordinates
- Drop-off address, coordinates
- Scheduled pickup/drop-off times
- Creation timestamp

### 2. **During Ride Progress** (Every Action Saved)
- Driver navigates to pickup
- Driver arrives at pickup
- Passenger picked up
- Driver navigates to destination
- Driver arrives at destination
- Ride completed

### 3. **When Details Change**
- Pickup address updated
- Drop-off address updated
- Pickup time changed
- Drop-off time changed
- Any other ride detail modification

### 4. **GPS Tracking** (Continuous)
- Real-time location updates
- Speed and heading
- Route tracking throughout ride

### 5. **Ride Completion**
- Final status (completed/cancelled)
- Completion timestamp
- Total distance and duration
- All events timeline

---

## Implementation Guide

### Step 1: Add to Your RouteBloc

```dart
import 'package:driver_app/core/services/ride_firebase_integration.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final RideFirebaseIntegration _firebaseIntegration = RideFirebaseIntegration();
  
  // Your existing code...
  
  Future<void> _onCreateManualRide(
    CreateManualRide event,
    Emitter<RouteState> emit,
  ) async {
    try {
      // Your existing ride creation logic...
      final route = RouteModel(
        // ... your route data
      );
      
      // 🔥 AUTOMATICALLY SAVE TO FIREBASE
      await _firebaseIntegration.onRideCreated(
        route: route,
        driverId: 'current_driver_id', // Use actual driver ID
      );
      
      // Continue with your existing logic...
    } catch (e) {
      // Handle error
    }
  }
}
```

### Step 2: Track Navigation Actions

```dart
// When driver taps "Navigate to Pickup"
Future<void> _onNavigateToPickup(
  NavigateToPickup event,
  Emitter<RouteState> emit,
) async {
  // Your existing navigation logic...
  
  // 🔥 SAVE ACTION TO FIREBASE
  await _firebaseIntegration.onNavigateToPickup(
    rideId: event.rideId,
    timestamp: DateTime.now(),
  );
}

// When driver arrives at pickup
Future<void> _onArriveAtPickup(
  ArriveAtPickup event,
  Emitter<RouteState> emit,
) async {
  // Your existing logic...
  
  // 🔥 SAVE ACTION TO FIREBASE
  await _firebaseIntegration.onArriveAtPickup(
    rideId: event.rideId,
    timestamp: DateTime.now(),
  );
}

// When passenger is picked up
Future<void> _onPickupPassenger(
  PickupPassenger event,
  Emitter<RouteState> emit,
) async {
  // Your existing logic...
  
  // 🔥 SAVE ACTION TO FIREBASE
  await _firebaseIntegration.onPassengerPickedUp(
    rideId: event.rideId,
    timestamp: DateTime.now(),
  );
}

// When navigating to destination
Future<void> _onNavigateToDestination(
  NavigateToDestination event,
  Emitter<RouteState> emit,
) async {
  // Your existing logic...
  
  // 🔥 SAVE ACTION TO FIREBASE
  await _firebaseIntegration.onNavigateToDestination(
    rideId: event.rideId,
    timestamp: DateTime.now(),
  );
}

// When arriving at destination
Future<void> _onArriveAtDestination(
  ArriveAtDestination event,
  Emitter<RouteState> emit,
) async {
  // Your existing logic...
  
  // 🔥 SAVE ACTION TO FIREBASE
  await _firebaseIntegration.onArriveAtDestination(
    rideId: event.rideId,
    timestamp: DateTime.now(),
  );
}
```

### Step 3: Track Address Changes

```dart
// When pickup address is updated
Future<void> _onUpdatePickupAddress(
  UpdatePickupAddress event,
  Emitter<RouteState> emit,
) async {
  // Your existing update logic...
  
  // 🔥 SAVE CHANGE TO FIREBASE
  await _firebaseIntegration.onPickupAddressChanged(
    rideId: event.rideId,
    newAddress: event.newAddress,
    latitude: event.latitude,
    longitude: event.longitude,
  );
}

// When drop-off address is updated
Future<void> _onUpdateDropOffAddress(
  UpdateDropOffAddress event,
  Emitter<RouteState> emit,
) async {
  // Your existing update logic...
  
  // 🔥 SAVE CHANGE TO FIREBASE
  await _firebaseIntegration.onDropOffAddressChanged(
    rideId: event.rideId,
    newAddress: event.newAddress,
    latitude: event.latitude,
    longitude: event.longitude,
  );
}
```

### Step 4: Track Time Changes

```dart
// When pickup time is changed
Future<void> _onUpdatePickupTime(
  UpdatePickupTime event,
  Emitter<RouteState> emit,
) async {
  // Your existing update logic...
  
  // 🔥 SAVE CHANGE TO FIREBASE
  await _firebaseIntegration.onPickupTimeChanged(
    rideId: event.rideId,
    newPickupTime: event.newPickupTime,
  );
}

// When drop-off time is changed
Future<void> _onUpdateDropOffTime(
  UpdateDropOffTime event,
  Emitter<RouteState> emit,
) async {
  // Your existing update logic...
  
  // 🔥 SAVE CHANGE TO FIREBASE
  await _firebaseIntegration.onDropOffTimeChanged(
    rideId: event.rideId,
    newDropOffTime: event.newDropOffTime,
  );
}
```

### Step 5: Track GPS Location (Continuous Updates)

```dart
// In your location tracking service or bloc
void _startLocationTracking(String rideId, String driverId) {
  locationStream.listen((position) async {
    // Your existing location handling...
    
    // 🔥 SAVE GPS DATA TO FIREBASE
    await _firebaseIntegration.onLocationUpdate(
      rideId: rideId,
      driverId: driverId,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      heading: position.heading,
    );
  });
}
```

### Step 6: Track Ride Completion

```dart
// When ride is completed
Future<void> _onCompleteRide(
  CompleteRide event,
  Emitter<RouteState> emit,
) async {
  // Your existing completion logic...
  
  // 🔥 SAVE COMPLETION TO FIREBASE
  await _firebaseIntegration.onRideCompleted(
    rideId: event.rideId,
    timestamp: DateTime.now(),
    distance: calculatedDistance,
    duration: calculatedDuration,
    additionalData: {
      'finalNotes': 'Any final notes',
      'passengerRating': 5,
    },
  );
}

// When ride is cancelled
Future<void> _onCancelRide(
  CancelRide event,
  Emitter<RouteState> emit,
) async {
  // Your existing cancellation logic...
  
  // 🔥 SAVE CANCELLATION TO FIREBASE
  await _firebaseIntegration.onRideCancelled(
    rideId: event.rideId,
    cancelledBy: 'driver', // or 'passenger'
    reason: event.cancellationReason,
    additionalData: {
      'cancelledAtStage': 'pickup', // or 'in_progress', etc.
    },
  );
}
```

---

## Data Structure in Firebase

### Firestore Collections

#### 1. `rides` (Active Rides)
```json
{
  "rideId": "RIDE123",
  "driverId": "DRIVER456",
  "riderId": "RIDER789",
  "status": "passenger_on_board",
  "pickupAddress": "123 Main St",
  "pickupLatitude": 34.0522,
  "pickupLongitude": -118.2437,
  "dropOffAddress": "456 Oak Ave",
  "dropOffLatitude": 34.0622,
  "dropOffLongitude": -118.2537,
  "scheduledPickupTime": "2025-10-17T08:00:00Z",
  "navigatedToPickupAt": "2025-10-17T07:50:00Z",
  "arrivedAtPickupAt": "2025-10-17T08:02:00Z",
  "passengerPickedUpAt": "2025-10-17T08:05:00Z",
  "currentLocation": {
    "latitude": 34.0550,
    "longitude": -118.2450,
    "updatedAt": "2025-10-17T08:10:00Z"
  },
  "events": [
    {
      "type": "ride_created",
      "data": {...},
      "timestamp": "2025-10-17T07:45:00Z"
    },
    {
      "type": "navigating_to_pickup",
      "data": {...},
      "timestamp": "2025-10-17T07:50:00Z"
    }
  ],
  "createdAt": "2025-10-17T07:45:00Z",
  "updatedAt": "2025-10-17T08:10:00Z"
}
```

#### 2. `ride_history` (Completed/Cancelled Rides)
Same structure as `rides` but with:
```json
{
  "status": "completed",
  "completedAt": "2025-10-17T08:30:00Z",
  "distance": 5.2,
  "duration": 25
}
```

#### 3. `ride_events` (Detailed Event Log)
```json
{
  "rideId": "RIDE123",
  "eventType": "pickup_address_changed",
  "eventData": {
    "oldAddress": "123 Main St",
    "newAddress": "124 Main St",
    "reason": "Pickup address changed"
  },
  "timestamp": "2025-10-17T07:55:00Z"
}
```

#### 4. `gps_tracking` (GPS History)
```json
{
  "rideId": "RIDE123",
  "driverId": "DRIVER456",
  "latitude": 34.0550,
  "longitude": -118.2450,
  "speed": 35.5,
  "heading": 180.0,
  "timestamp": "2025-10-17T08:10:00Z"
}
```

### Realtime Database

#### `active_rides/{rideId}`
Real-time updates for live tracking (same structure as Firestore but updates instantly)

#### `live_tracking/{driverId}`
Current location of driver for live map tracking

---

## Retrieving Data

### Get Complete Ride Details
```dart
final rideDetails = await _firebaseIntegration.getRideDetails('RIDE123');
print('Ride status: ${rideDetails['status']}');
print('All events: ${rideDetails['events']}');
```

### Get Full Event Timeline
```dart
final timeline = await _firebaseIntegration.getRideTimeline('RIDE123');
for (final event in timeline) {
  print('${event['eventType']}: ${event['timestamp']}');
}
```

### Get GPS Route
```dart
final route = await _firebaseIntegration.getRideRoute('RIDE123');
for (final point in route) {
  print('Location: ${point['latitude']}, ${point['longitude']}');
}
```

---

## Benefits

✅ **Complete History**: Every action is tracked with timestamp
✅ **Automatic Sync**: No manual saving needed - happens automatically
✅ **Real-time Updates**: Live tracking for rider app
✅ **Easy Access**: Organized collections for each feature
✅ **Full Details**: All ride information in one place
✅ **Change Tracking**: Know when and why details changed
✅ **GPS History**: Complete route of each ride
✅ **Event Timeline**: See exactly what happened and when

---

## Next Steps

1. ✅ Services created and ready
2. ⏳ Add integration calls to your RouteBloc (see examples above)
3. ⏳ Add GPS tracking integration
4. ⏳ Test with a sample ride
5. ⏳ Verify data in Firebase Console

---

## Testing

1. Create a test ride
2. Go through each action (navigate, arrive, pickup, etc.)
3. Check Firebase Console:
   - `rides` collection - active ride data
   - `ride_events` collection - all events logged
   - `gps_tracking` collection - location history
4. Complete or cancel the ride
5. Check `ride_history` collection - ride moved to history

Everything is automatically saved! 🚀
