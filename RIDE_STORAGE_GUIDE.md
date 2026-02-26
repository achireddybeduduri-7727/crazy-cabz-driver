# Ride Local Storage Guide

## Overview
The Driver App implements a comprehensive local storage system that persists ride data locally until rides are completed or cancelled. This ensures data reliability, offline support, and seamless user experience.

---

## Storage Architecture

### 1. **Storage Services**

#### **RideHistoryService** (`lib/core/services/ride_history_service.dart`)
Primary service for managing ride data persistence.

**Key Storage Keys:**
- `active_ride` - Current active route
- `ride_history` - Historical completed/cancelled rides (last 100)
- `ride_counter` - Total ride counter for statistics

**Storage Technology:**
- **SharedPreferences** - Local persistent storage
- **Firebase** - Cloud backup (optional, continues if fails)

---

## Storage Lifecycle

### **1. Ride Creation** 🚀

When a ride is created (manually or scheduled):

```dart
// In RouteBloc._onCreateManualRoute()
await RideHistoryService.saveActiveRide(event.route);
```

**What Happens:**
1. Route is validated
2. Existing active route is cleared (if any)
3. New route is saved to `active_ride` key
4. Route status: `RouteStatus.scheduled`
5. Data persists locally in SharedPreferences

**Storage Format:**
```json
{
  "id": "route_123",
  "driverId": "driver_456",
  "status": "scheduled",
  "rides": [
    {
      "id": "ride_001",
      "status": "scheduled",
      "passenger": {...},
      "pickupAddress": "...",
      "dropOffAddress": "..."
    }
  ],
  "createdAt": "2025-10-10T10:00:00.000Z"
}
```

---

### **2. Active Ride Storage** 💾

The active ride remains in local storage throughout its lifecycle:

**Stored When:**
- ✅ Route is created
- ✅ Route is started
- ✅ Individual rides are updated
- ✅ Ride statuses change (navigating, arrived, picked up, etc.)
- ✅ Location tracking points are added

**Updated During:**
- Navigation to pickup
- Passenger pickup
- Navigation to destination
- Arrival at destination
- Status changes

**Storage Location:**
```
SharedPreferences → Key: "active_ride"
```

---

### **3. Ride Updates** 🔄

Every time a ride status changes, the active route is updated:

```dart
// In RouteBloc
_currentRoute = _currentRoute!.copyWith(rides: updatedRides);
await RideHistoryService.saveActiveRide(_currentRoute!);
```

**Update Triggers:**
- Start navigation to pickup
- Arrive at pickup location
- Pick up passenger
- Start navigation to destination
- Arrive at destination
- Complete individual ride
- Mark passenger present/absent

---

### **4. Ride Completion** ✅

When a route is completed:

```dart
// In RouteBloc._onCompleteRoute()
await RideHistoryService.addToHistory(completedRoute);
await RideHistoryService.clearActiveRide();
```

**What Happens:**
1. Route status changes to `RouteStatus.completed`
2. Route is moved from `active_ride` to `ride_history`
3. Route is added to Firebase (cloud backup)
4. Ride counter is incremented
5. Active ride storage is cleared
6. Route becomes part of ride history (max 100 kept locally)

**Storage Transition:**
```
active_ride → removed
ride_history → [completed_route, ...previous_routes]
ride_counter → incremented
```

---

### **5. Ride Cancellation** ❌

When a route is cancelled:

```dart
// In RouteBloc._onCancelRoute()
await _routeUseCase.cancelRoute(routeId, reason);
await RideHistoryService.clearActiveRide();
```

**What Happens:**
1. Route status changes to `RouteStatus.cancelled`
2. Active ride storage is cleared
3. Route is NOT added to history (optional: could be added)
4. Cancellation reason is stored (if implemented)

**Storage Cleanup:**
```
active_ride → removed
_currentRoute → set to null
```

---

## Key Storage Methods

### **Save Active Ride**
```dart
static Future<void> saveActiveRide(RouteModel route) async {
  final prefs = await SharedPreferences.getInstance();
  final routeJson = jsonEncode(route.toJson());
  await prefs.setString(_activeRideKey, routeJson);
}
```

### **Get Active Ride**
```dart
static Future<RouteModel?> getActiveRide() async {
  final prefs = await SharedPreferences.getInstance();
  final routeJson = prefs.getString(_activeRideKey);
  if (routeJson != null) {
    return RouteModel.fromJson(jsonDecode(routeJson));
  }
  return null;
}
```

### **Clear Active Ride**
```dart
static Future<void> clearActiveRide() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_activeRideKey);
}
```

### **Add to History**
```dart
static Future<void> addToHistory(RouteModel route) async {
  // 1. Store in Firebase (cloud)
  await FirebaseRideHistoryService.storeCompletedRide(route);
  
  // 2. Store locally
  List<RouteModel> history = await getRideHistory();
  history.insert(0, route); // Most recent first
  
  // Keep only last 100 rides
  if (history.length > 100) {
    history = history.take(100).toList();
  }
  
  // Save updated history
  final prefs = await SharedPreferences.getInstance();
  final historyJson = jsonEncode(history.map((r) => r.toJson()).toList());
  await prefs.setString(_rideHistoryKey, historyJson);
  
  // Increment counter
  await _incrementRideCounter();
}
```

---

## Data Persistence Features

### **Offline Support** 📱
- All ride data stored locally using SharedPreferences
- App works fully offline
- Data syncs to Firebase when connection available
- If Firebase fails, continues with local storage only

### **Data Redundancy** 🔒
- Primary: Local SharedPreferences storage
- Backup: Firebase cloud storage
- Automatic sync when online

### **Auto-Recovery** 🔄
```dart
Future<void> _loadActiveRideOnStart() async {
  final activeRide = await RideHistoryService.getActiveRide();
  if (activeRide != null) {
    _currentRoute = activeRide;
    add(LoadActiveRoute(activeRide.driverId));
  }
}
```

When app restarts:
1. Checks for active ride in storage
2. Automatically loads active ride
3. Restores route state
4. Continues from where user left off

### **History Management** 📚
- Stores last 100 completed routes locally
- Prevents excessive storage usage
- Syncs with Firebase for unlimited cloud history
- Merges Firebase and local data on retrieval

---

## Storage States

### **Active Ride States**

| State | Storage Status | Location |
|-------|---------------|----------|
| Created | ✅ Stored | `active_ride` key |
| Scheduled | ✅ Stored | `active_ride` key |
| Started | ✅ Stored | `active_ride` key |
| In Progress | ✅ Stored (updates) | `active_ride` key |
| Completing | ✅ Stored (updating) | `active_ride` key |
| Completed | ✅ Moved to history | `ride_history` array |
| Cancelled | ❌ Cleared | Removed from storage |

---

## Individual Ride Tracking

Each ride within a route has timestamps stored:

```dart
class IndividualRide {
  final String id;
  final IndividualRideStatus status;
  
  // Time tracking
  final DateTime? navigatedToPickupAt;
  final DateTime? arrivedAtPickupAt;
  final DateTime? passengerPickedUpAt;
  final DateTime? navigatedToDestinationAt;
  final DateTime? arrivedAtDestinationAt;
  final DateTime? rideCompletedAt;
}
```

**All timestamps are persisted in local storage** throughout the ride lifecycle.

---

## Statistics & Analytics

```dart
static Future<Map<String, int>> getRideStatistics() async {
  return {
    'total': totalRides,        // From ride_counter
    'completed': completedRides, // From ride_history
    'cancelled': cancelledRides, // From ride_history
    'recent': history.length,    // Current history count
  };
}
```

---

## Error Handling

### **Storage Failures**
```dart
try {
  await RideHistoryService.saveActiveRide(route);
} catch (storageError) {
  AppLogger.error('Failed to save: $storageError');
  // Continue operation - don't fail completely
}
```

### **Firebase Failures**
- App continues with local storage only
- Logs warning but doesn't interrupt user flow
- Retries sync when connection restored

### **Data Corruption**
- Validates JSON before parsing
- Returns null/empty list on corruption
- Logs errors for debugging

---

## Best Practices

### ✅ **Do's**
- Always save active ride after status updates
- Clear active ride after completion/cancellation
- Use try-catch for all storage operations
- Log storage operations for debugging
- Keep history limited (100 rides max locally)

### ❌ **Don'ts**
- Don't store sensitive passenger data insecurely
- Don't block UI during storage operations
- Don't fail operations if storage fails
- Don't store unlimited history locally

---

## Testing & Debugging

### **Debug Method**
```dart
await RideHistoryService.debugPrintStoredHistory();
```

**Outputs:**
- All stored routes
- Route statuses
- Ride counts
- Statistics
- Raw JSON data

### **Clear All Data** (Testing Only)
```dart
await RideHistoryService.clearAllHistory();
```

---

## Summary

✅ **Rides are stored locally from creation until completion/cancellation**

**Storage Timeline:**
1. **Create** → Stored in `active_ride`
2. **Update** → Continuously updated in `active_ride`
3. **Complete** → Moved to `ride_history` + Firebase
4. **Cancel** → Cleared from `active_ride`

**Key Benefits:**
- 📱 Full offline support
- 🔄 Auto-recovery on app restart
- 💾 Dual storage (local + cloud)
- 📊 Persistent statistics
- 🚀 Fast local access
- 🔒 Data redundancy

The system ensures **no ride data is lost** and provides a seamless experience even without internet connectivity! 🎉
