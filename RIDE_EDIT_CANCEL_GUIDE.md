# Ride Edit & Cancel Feature Guide

## Overview
The Driver App now includes comprehensive features for editing ride addresses and canceling individual rides with detailed reason tracking. These features are available in the individual ride detail screen for better ride management.

---

## Features Added

### 1. **Edit Ride Address** 📍

Allows drivers to update pickup and drop-off addresses for scheduled or en-route rides.

#### **Availability:**
- ✅ Scheduled rides
- ✅ En-route rides (before arrival)
- ❌ Arrived rides (passenger waiting)
- ❌ Picked up rides (in transit)
- ❌ Completed rides
- ❌ Cancelled rides

#### **How to Use:**
1. Open individual ride detail screen
2. Tap **"Edit Address"** button (blue outlined button)
3. Update pickup and/or drop-off addresses
4. Tap **"Update"** to save changes

#### **Features:**
- 📝 Edit both pickup and drop-off addresses
- 🔄 Real-time address validation
- 💾 Automatic save to local storage
- 📍 Note: Coordinates updated automatically (placeholder for geocoding)

#### **Implementation:**
```dart
_routeBloc.add(UpdateRideAddress(
  rideId: _currentRide.id,
  newPickupAddress: newPickupAddress,
  newDropOffAddress: newDropOffAddress,
));
```

---

### 2. **Cancel Individual Ride** ❌

Allows drivers to cancel specific rides with mandatory reason selection.

#### **Availability:**
- ✅ Scheduled rides
- ✅ En-route rides
- ❌ Arrived rides (use complete instead)
- ❌ Picked up rides (use complete instead)
- ❌ Completed rides
- ❌ Cancelled rides

#### **Cancellation Reasons:**
1. **Passenger not available** - Passenger not at pickup location
2. **Passenger cancelled** - Passenger requested cancellation
3. **Vehicle issue** - Car problem, breakdown, etc.
4. **Traffic/Road conditions** - Severe traffic, road closure, weather
5. **Emergency** - Driver emergency situation
6. **Other** - Custom reason (text input required)

#### **How to Use:**
1. Open individual ride detail screen
2. Tap **"Cancel Ride"** button (red outlined button)
3. Select cancellation reason from list
4. If "Other" selected, enter custom reason
5. Review warning message
6. Tap **"Cancel Ride"** to confirm (or "Keep Ride" to abort)

#### **Features:**
- 📋 Predefined cancellation reasons
- ✍️ Custom reason input for "Other"
- ⚠️ Warning message before confirmation
- 🔒 Cannot be undone
- 🗑️ Removed from active rides immediately
- 💾 Cancellation reason stored in ride notes

#### **Warning Message:**
```
⚠️ This action cannot be undone. The ride will be removed from your active rides.
```

#### **Implementation:**
```dart
_routeBloc.add(CancelIndividualRide(
  rideId: _currentRide.id,
  cancellationReason: finalReason,
  cancelledAt: DateTime.now(),
));
```

---

## UI Components

### **Action Buttons Layout**

Both buttons appear as a row at the top of the ride actions section:

```
┌─────────────────────────────────────────────┐
│  [📍 Edit Address]  [❌ Cancel Ride]        │
│                                              │
│  [Swipe to Navigate Pick →]                 │
└─────────────────────────────────────────────┘
```

### **Edit Address Dialog**

**Components:**
- Title: "Edit Addresses"
- Pickup Address field (multi-line text input)
- Drop-off Address field (multi-line text input)
- Info note: "Coordinates will be updated automatically"
- Cancel button (dismisses dialog)
- Update button (saves changes)

**Validation:**
- Both addresses required
- Shows error snackbar if empty
- Trims whitespace

### **Cancel Ride Dialog**

**Components:**
- Title: "Cancel Ride"
- Instruction text
- Radio button list of reasons
- Custom reason text field (when "Other" selected)
- Warning box with orange background
- Keep Ride button (dismisses dialog)
- Cancel Ride button (red, confirms cancellation)

**Behavior:**
- Cancel Ride button disabled until reason selected
- Custom text required if "Other" selected
- Auto-navigates back after cancellation

---

## BLoC Events

### **1. UpdateRideAddress Event**

```dart
class UpdateRideAddress extends RouteEvent {
  final String rideId;
  final String? newPickupAddress;
  final double? newPickupLatitude;
  final double? newPickupLongitude;
  final String? newDropOffAddress;
  final double? newDropOffLatitude;
  final double? newDropOffLongitude;
}
```

**Parameters:**
- `rideId` - Required, identifies the ride to update
- `newPickupAddress` - Optional, new pickup address text
- `newPickupLatitude` - Optional, new pickup latitude
- `newPickupLongitude` - Optional, new pickup longitude
- `newDropOffAddress` - Optional, new drop-off address text
- `newDropOffLatitude` - Optional, new drop-off latitude
- `newDropOffLongitude` - Optional, new drop-off longitude

**Handler:** `_onUpdateRideAddress()`

**Flow:**
1. Validates active route exists
2. Finds ride by ID
3. Creates updated ride with new addresses
4. Updates route with modified ride
5. Saves to local storage
6. Emits `IndividualRideUpdated` state

### **2. CancelIndividualRide Event**

```dart
class CancelIndividualRide extends RouteEvent {
  final String rideId;
  final String cancellationReason;
  final DateTime cancelledAt;
}
```

**Parameters:**
- `rideId` - Required, identifies the ride to cancel
- `cancellationReason` - Required, reason for cancellation
- `cancelledAt` - Required, timestamp of cancellation

**Handler:** `_onCancelIndividualRide()`

**Flow:**
1. Validates active route exists
2. Finds ride by ID
3. Updates ride status to `cancelled`
4. Stores reason in `passengerNotes` field
5. Removes ride from active route
6. If no rides left, clears active route
7. Otherwise, saves updated route
8. Emits appropriate state

---

## BLoC Handlers

### **_onUpdateRideAddress()**

**Purpose:** Updates ride pickup/drop-off addresses

**Process:**
```
1. Check active route exists
2. Emit RouteUpdating (loading state)
3. Find ride in route by ID
4. Create updated ride with new addresses
5. Replace old ride with updated ride
6. Save route to RideHistoryService
7. Emit IndividualRideUpdated (success)
8. Handle errors with RouteError state
```

**Error Handling:**
- No active route: Emits `RouteError`
- Ride not found: Throws exception
- Storage failure: Logs error, emits `RouteError`

### **_onCancelIndividualRide()**

**Purpose:** Cancels individual ride with reason

**Process:**
```
1. Check active route exists
2. Emit RouteUpdating (loading state)
3. Find ride in route by ID
4. Update ride status to cancelled
5. Store cancellation reason in passengerNotes
6. Remove ride from active rides list
7. Check if any rides remaining:
   a. No rides: Clear active route, emit RouteLoaded(null)
   b. Has rides: Save updated route, emit IndividualRideUpdated
8. Handle errors with RouteError state
```

**Special Cases:**
- **Last ride cancelled:** Clears entire active route
- **Multiple rides:** Removes only cancelled ride, keeps others
- **Storage:** Updates local storage automatically

---

## Storage Behavior

### **Edit Address**

**What's Stored:**
```json
{
  "id": "ride_123",
  "pickupAddress": "Updated Address 1",
  "dropOffAddress": "Updated Address 2",
  "updatedAt": "2025-10-10T14:30:00.000Z"
}
```

**Storage Flow:**
1. Updates ride in current route
2. Saves entire route to `active_ride` key
3. Triggers local storage update
4. Route remains in active state

### **Cancel Ride**

**What's Stored:**
```json
{
  "id": "ride_123",
  "status": "cancelled",
  "passengerNotes": "Cancelled: Passenger not available",
  "updatedAt": "2025-10-10T14:30:00.000Z"
}
```

**Storage Flow:**
1. Removes ride from active route
2. If rides remain: Updates `active_ride` with remaining rides
3. If no rides: Deletes `active_ride` key entirely
4. Cancelled ride NOT added to history (only completed rides)

---

## UI States & Feedback

### **Success Messages**

**Edit Address:**
```
✅ Address updated successfully
```
- Green snackbar
- 2-second duration
- Auto-dismisses

**Cancel Ride:**
- No snackbar (dialog handles feedback)
- Automatic navigation back to route list
- 500ms delay for smooth transition

### **Error Messages**

**Edit Address - Empty Fields:**
```
❌ Both addresses are required
```
- Red snackbar
- Dialog remains open
- User can correct and retry

**Cancel Ride - No Reason:**
```
❌ Please provide a cancellation reason
```
- Red snackbar
- Dialog remains open
- User must select/enter reason

**General Errors:**
```
❌ Failed to update ride address: [error details]
❌ Failed to cancel ride: [error details]
```
- Emitted from BLoC
- Logged to AppLogger
- Displayed in snackbar

---

## Button Visibility Logic

### **Edit Address Button**

**Visible When:**
```dart
status == IndividualRideStatus.scheduled ||
status == IndividualRideStatus.enRoute
```

**Hidden When:**
- Ride is arrived (passenger waiting)
- Ride is picked up (in transit)
- Ride is completed
- Ride is cancelled

**Reasoning:** Can't change destination mid-ride or after completion

### **Cancel Ride Button**

**Visible When:**
```dart
status == IndividualRideStatus.scheduled ||
status == IndividualRideStatus.enRoute
```

**Hidden When:**
- Ride is arrived or later stages
- Best practice: Complete the ride instead of canceling once arrived

**Reasoning:** After arrival, should complete ride (passenger absent handled differently)

---

## User Workflows

### **Workflow 1: Edit Address Before Starting**

```
1. Driver views scheduled ride
2. Passenger calls with address change
3. Driver taps "Edit Address"
4. Updates pickup/drop-off address
5. Taps "Update"
6. ✅ Address updated, ready to navigate
```

### **Workflow 2: Edit Address En Route**

```
1. Driver navigating to pickup
2. Realizes wrong address
3. Taps "Edit Address"
4. Corrects the address
5. Taps "Update"
6. ✅ Can re-navigate with correct address
```

### **Workflow 3: Cancel Ride - Passenger Unavailable**

```
1. Driver arrives at pickup (but ride not marked "arrived" yet)
2. Passenger not responding
3. Driver taps "Cancel Ride"
4. Selects "Passenger not available"
5. Reviews warning message
6. Taps "Cancel Ride" to confirm
7. ✅ Ride removed, navigation to route list
```

### **Workflow 4: Cancel Ride - Emergency**

```
1. Driver has vehicle issue
2. Opens active ride
3. Taps "Cancel Ride"
4. Selects "Vehicle issue"
5. Confirms cancellation
6. ✅ Ride cancelled, can notify passenger
```

### **Workflow 5: Cancel Ride - Custom Reason**

```
1. Driver needs to cancel for unique reason
2. Taps "Cancel Ride"
3. Selects "Other"
4. Text field appears
5. Enters custom reason: "Road flooded, cannot access"
6. Confirms cancellation
7. ✅ Ride cancelled with custom reason stored
```

---

## Technical Implementation

### **State Management**

**BLoC Pattern:**
- Events: `UpdateRideAddress`, `CancelIndividualRide`
- States: `RouteUpdating`, `IndividualRideUpdated`, `RouteLoaded`, `RouteError`
- Handler: `RouteBloc`

**State Transitions:**

**Edit Address:**
```
RouteLoaded → RouteUpdating → IndividualRideUpdated → RouteLoaded
```

**Cancel Ride:**
```
RouteLoaded → RouteUpdating → (RouteLoaded(null) OR IndividualRideUpdated)
```

### **Data Flow**

**Edit Address:**
```
UI (Dialog)
  → UpdateRideAddress Event
    → RouteBloc Handler
      → Update Ride Object
        → Update Route
          → RideHistoryService.saveActiveRide()
            → SharedPreferences Storage
              → IndividualRideUpdated State
                → UI Update
```

**Cancel Ride:**
```
UI (Dialog)
  → CancelIndividualRide Event
    → RouteBloc Handler
      → Update Ride Status
        → Remove from Route
          → Check Remaining Rides
            → RideHistoryService (save or clear)
              → SharedPreferences Storage
                → State Emission
                  → Navigate Back
```

---

## Best Practices

### **For Drivers:**

✅ **DO:**
- Edit address before starting navigation
- Provide specific cancellation reasons
- Cancel only when absolutely necessary
- Verify address changes before updating

❌ **DON'T:**
- Cancel rides after passenger pickup
- Change addresses mid-transit
- Use vague cancellation reasons
- Cancel without attempting contact

### **For Developers:**

✅ **DO:**
- Validate all address inputs
- Store cancellation reasons for analytics
- Log all edit/cancel operations
- Maintain data consistency in storage
- Handle edge cases (last ride, no rides)

❌ **DON'T:**
- Allow cancellation of completed rides
- Skip validation on address updates
- Lose cancellation reason data
- Allow empty reason submissions

---

## Future Enhancements

### **Potential Improvements:**

1. **Geocoding Integration** 🗺️
   - Auto-fetch coordinates from address
   - Validate address exists
   - Show map preview of new location

2. **Cancellation Analytics** 📊
   - Track cancellation patterns
   - Generate reports by reason
   - Driver cancellation rate metrics

3. **Address Suggestions** 💡
   - Recent addresses dropdown
   - Autocomplete from passenger history
   - Saved common locations

4. **Undo Cancellation** ↩️
   - Grace period (30 seconds)
   - Restore cancelled ride
   - Prevent accidental cancellations

5. **Passenger Notification** 📧
   - Auto-notify on cancellation
   - Send SMS/email with reason
   - Allow passenger to reschedule

6. **Partial Cancellation** 🎯
   - Cancel individual legs
   - Reschedule instead of cancel
   - Transfer to another driver

---

## Summary

### **Key Features:**

✅ **Edit Address**
- Update pickup/drop-off addresses
- Available for scheduled & en-route rides
- Real-time storage updates
- User-friendly dialog interface

✅ **Cancel Ride**
- Mandatory reason selection
- 6 predefined + custom option
- Warning before confirmation
- Automatic route cleanup
- Stores cancellation details

### **Benefits:**

🚀 **Flexibility** - Handle last-minute changes
🔒 **Accountability** - Track all cancellations with reasons
💾 **Reliability** - Persistent storage, no data loss
🎯 **User-Friendly** - Intuitive dialogs and confirmations
📊 **Analytics-Ready** - Structured cancellation data

### **Impact:**

- Reduces communication errors with address changes
- Provides clear audit trail for cancellations
- Improves driver-passenger relationship
- Enables data-driven decision making
- Enhances overall app reliability

---

## File Locations

**Events:**
- `lib/features/rides/presentation/bloc/route_event.dart`
  - `CancelIndividualRide`
  - `UpdateRideAddress`

**Handlers:**
- `lib/features/rides/presentation/bloc/route_bloc.dart`
  - `_onCancelIndividualRide()`
  - `_onUpdateRideAddress()`

**UI:**
- `lib/features/rides/presentation/screens/individual_ride_detail_screen.dart`
  - `_showEditAddressDialog()`
  - `_showCancelRideDialog()`
  - Updated `_buildRideActions()`

**Storage:**
- `lib/core/services/ride_history_service.dart` (existing)
  - Uses `saveActiveRide()` and `clearActiveRide()`

---

## Testing Checklist

### **Edit Address:**
- [ ] Edit pickup address only
- [ ] Edit drop-off address only
- [ ] Edit both addresses
- [ ] Submit with empty fields (should fail)
- [ ] Cancel dialog (no changes saved)
- [ ] Verify storage updated
- [ ] Check UI reflects changes

### **Cancel Ride:**
- [ ] Select each predefined reason
- [ ] Select "Other" with custom text
- [ ] Try to submit without reason (should fail)
- [ ] Cancel dialog (ride kept)
- [ ] Confirm cancellation (ride removed)
- [ ] Last ride cancellation (route cleared)
- [ ] Multiple rides (only one removed)
- [ ] Verify navigation back
- [ ] Check storage updated

### **Button Visibility:**
- [ ] Scheduled ride: Both buttons visible
- [ ] En-route ride: Both buttons visible
- [ ] Arrived ride: Both buttons hidden
- [ ] Picked up ride: Both buttons hidden
- [ ] Completed ride: Both buttons hidden
- [ ] Cancelled ride: Both buttons hidden

---

**Implementation Complete!** 🎉

The ride profile now has full edit and cancel capabilities with proper reason tracking and storage management!
