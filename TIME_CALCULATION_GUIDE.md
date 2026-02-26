# Activities Time Calculation Guide

## Overview
The Activities screen displays ride history with time calculations based on event timestamps. Each ride tracks 6 key timestamps and calculates 4 duration metrics from these events.

---

## Timeline Events (6 Timestamps)

### 1. **navigatedToPickupAt**
- **When**: Driver taps "Navigate to Pickup" button
- **Purpose**: Start of the entire ride timeline
- **Used For**: Beginning of total ride duration calculation

### 2. **arrivedAtPickupAt**
- **When**: Driver taps "Arrived at Pickup" button
- **Purpose**: Marks arrival at passenger location
- **Used For**: End of navigation time, start of waiting time

### 3. **passengerPickedUpAt**
- **When**: Driver taps "Passenger Picked Up" or "Navigate to Destination"
- **Purpose**: Passenger is now in the vehicle
- **Used For**: End of waiting time, start of actual trip

### 4. **navigatedToDestinationAt**
- **When**: Driver starts navigation to drop-off location
- **Purpose**: Beginning of trip to destination
- **Used For**: Start of trip duration calculation

### 5. **arrivedAtDestinationAt**
- **When**: Driver arrives at drop-off location
- **Purpose**: Marks arrival at destination
- **Used For**: End of trip duration

### 6. **rideCompletedAt**
- **When**: Driver swipes to complete the ride
- **Purpose**: Official ride completion timestamp
- **Used For**: End of total ride duration

---

## Duration Calculations (4 Metrics)

### 1. **navigationToPickupDuration**
```
Formula: arrivedAtPickupAt - navigatedToPickupAt
Units: Minutes
```
**Example:**
- Started navigation: 2:00 PM
- Arrived at pickup: 2:15 PM
- **Duration: 15 minutes**

**What it measures**: How long it took the driver to reach the pickup location from when they started navigating.

---

### 2. **waitingAtPickupDuration**
```
Formula: passengerPickedUpAt - arrivedAtPickupAt
Units: Minutes
```
**Example:**
- Arrived at pickup: 2:15 PM
- Picked up passenger: 2:20 PM
- **Duration: 5 minutes**

**What it measures**: How long the driver waited at the pickup location for the passenger.

---

### 3. **navigationToDestinationDuration**
```
Formula: arrivedAtDestinationAt - navigatedToDestinationAt
Units: Minutes
```
**Example:**
- Started to destination: 2:20 PM
- Arrived at destination: 2:45 PM
- **Duration: 25 minutes**

**What it measures**: The actual trip time with the passenger to the destination (the main ride).

---

### 4. **totalRideDuration**
```
Formula: rideCompletedAt - navigatedToPickupAt
Units: Minutes
```
**Example:**
- Started navigation: 2:00 PM
- Completed ride: 2:50 PM
- **Total Duration: 50 minutes**

**What it measures**: The entire time from when the driver started the ride until completion (includes all phases).

**Breakdown:**
- Navigation to pickup: 15 min
- Waiting at pickup: 5 min
- Trip to destination: 25 min
- Completion: 5 min
- **Total: 50 minutes**

---

## Visual Timeline Example

```
Timeline Flow:
═══════════════════════════════════════════════════════════════

1. Navigate to Pickup (2:00 PM)
   │
   │ ◄── navigationToPickupDuration (15 min) ──►
   │
2. Arrived at Pickup (2:15 PM)
   │
   │ ◄── waitingAtPickupDuration (5 min) ──►
   │
3. Passenger Picked Up (2:20 PM)
   │
4. Navigate to Destination (2:20 PM)
   │
   │ ◄── navigationToDestinationDuration (25 min) ──►
   │
5. Arrived at Destination (2:45 PM)
   │
6. Ride Completed (2:50 PM)

◄────── totalRideDuration (50 min) ──────►
```

---

## How It's Displayed in Activities

### Ride Card (Collapsed)
Shows the most important metric:
- **Total Duration**: "50m" or "1h 25m" (totalRideDuration)

### Timeline (Expanded)
Shows all events with individual durations:

1. **Navigate to Pickup** - 2:00 PM
2. **Arrived at Pickup** - 2:15 PM
   - Duration: 15m (navigationToPickupDuration)
3. **Passenger Picked Up** - 2:20 PM
   - Duration: 5m (waitingAtPickupDuration)
4. **Navigate to Destination** - 2:20 PM
5. **Arrived at Destination** - 2:45 PM
   - Duration: 25m (navigationToDestinationDuration)
6. **Ride Completed** - 2:50 PM

### Horizontal Timeline (Individual Ride Detail)
- Shows progress bar with car indicator
- Each completed step shows its timestamp in 12-hour format (e.g., "2:15 PM")
- Duration badges show time between steps

---

## Code Implementation

### Location: `lib/shared/models/route_model.dart`

```dart
// Duration calculations as computed properties (getters)

int? get navigationToPickupDuration {
  if (navigatedToPickupAt == null || arrivedAtPickupAt == null) return null;
  return arrivedAtPickupAt!.difference(navigatedToPickupAt!).inMinutes;
}

int? get waitingAtPickupDuration {
  if (arrivedAtPickupAt == null || passengerPickedUpAt == null) return null;
  return passengerPickedUpAt!.difference(arrivedAtPickupAt!).inMinutes;
}

int? get navigationToDestinationDuration {
  if (navigatedToDestinationAt == null || arrivedAtDestinationAt == null) return null;
  return arrivedAtDestinationAt!.difference(navigatedToDestinationAt!).inMinutes;
}

int? get totalRideDuration {
  if (navigatedToPickupAt == null || rideCompletedAt == null) return null;
  return rideCompletedAt!.difference(navigatedToPickupAt!).inMinutes;
}
```

---

## Duration Formatting

All durations are automatically formatted for display:

**Under 60 minutes:**
- `15` minutes → `"15m"`
- `45` minutes → `"45m"`

**60 minutes or more:**
- `75` minutes → `"1h 15m"`
- `125` minutes → `"2h 5m"`
- `180` minutes → `"3h 0m"`

---

## Key Points

1. **All calculations are automatic** - No manual entry needed
2. **Calculations happen in real-time** - As each event is logged
3. **Null safety** - If any timestamp is missing, that duration returns null
4. **Minutes precision** - All durations are rounded to the nearest minute
5. **12-hour format** - All timestamps display as "h:mm AM/PM" (e.g., "2:30 PM")
6. **Smart date display** - "Today", "Yesterday", or "MMM dd, yyyy"

---

## Use Cases

### Payment Calculation
```dart
// Calculate total billable time
final total = ride.totalRideDuration; // 50 minutes
final rate = 0.50; // $0.50 per minute
final cost = total * rate; // $25.00
```

### Performance Metrics
```dart
// Average navigation time
final avgNavTime = ride.navigationToPickupDuration; // 15 min

// Customer wait time (service quality metric)
final customerWait = ride.waitingAtPickupDuration; // 5 min

// Actual trip time
final tripTime = ride.navigationToDestinationDuration; // 25 min
```

### Timeline Verification
```dart
// Check if all timeline data is complete
final isComplete = ride.hasCompleteTimeline; // true/false

// Ensure no step was skipped
if (ride.hasCompleteTimeline) {
  print('All timeline steps logged correctly');
}
```

---

## Common Scenarios

### Scenario 1: Quick Pickup
- Navigation: 5 min
- Waiting: 1 min
- Trip: 15 min
- **Total: 21 min**

### Scenario 2: Long Distance
- Navigation: 30 min
- Waiting: 3 min
- Trip: 60 min
- **Total: 93 min (1h 33m)**

### Scenario 3: Delayed Passenger
- Navigation: 10 min
- Waiting: 20 min (passenger late)
- Trip: 25 min
- **Total: 55 min**

---

## Troubleshooting

**Q: Why is totalRideDuration showing null?**
A: Either `navigatedToPickupAt` or `rideCompletedAt` is missing. Ensure the ride was properly completed with all timeline steps.

**Q: Why are some durations missing in the timeline?**
A: Individual durations only show if both timestamps for that calculation exist. For example, `waitingAtPickupDuration` requires both `arrivedAtPickupAt` and `passengerPickedUpAt`.

**Q: Can durations be negative?**
A: No. The system ensures events are logged in chronological order. If timestamps are out of order, the duration calculation will be incorrect but not negative.

**Q: What happens if I skip a step?**
A: The recent update (completed today) ensures that when you swipe to end ride, all missing timeline steps are automatically filled with the current timestamp, so no steps are skipped.

---

## Recent Updates (October 10, 2025)

### Timeline Completion Fix
- Enhanced ride completion to ensure all 6 timeline events are logged
- Added automatic timestamp filling for skipped steps
- Improved UI feedback with step-by-step completion animation
- Added 300ms delays between events for smooth visual transition
- Automatic navigation back to Activities after 1.5 seconds
- All rides now have complete timeline data for accurate duration calculations

---

This guide ensures accurate time tracking for billing, performance analysis, and service quality monitoring.
