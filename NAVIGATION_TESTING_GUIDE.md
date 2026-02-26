# Navigation Testing Guide

## Quick Test Scenarios

### Scenario 1: Basic Tab Navigation
**Objective:** Verify smooth navigation between all tabs

**Steps:**
1. Launch app and log in
2. You should be on Rides screen (tab 0)
3. Tap "Earnings" tab → Should switch instantly
4. Tap "Activities" tab → Should switch instantly
5. Tap "Rides" tab → Should switch instantly
6. Repeat 5 times quickly

**Expected Results:**
✅ Instant tab switching (no delay or flicker)
✅ FAB appears only on Rides screen
✅ FAB disappears on other screens
✅ No console errors
✅ Smooth animations

### Scenario 2: FAB Functionality
**Objective:** Verify FAB works after navigation

**Steps:**
1. On Rides screen, press FAB (+ button)
2. Add Manual Ride screen should open
3. Press back button
4. Navigate to Earnings tab
5. Navigate back to Rides tab
6. Press FAB again
7. Add Manual Ride screen should open
8. Press back button
9. Navigate to Activities tab
10. Navigate back to Rides tab
11. Press FAB again

**Expected Results:**
✅ FAB opens Add Manual Ride screen every time
✅ No "context invalid" errors
✅ No "widget not mounted" errors
✅ Consistent behavior regardless of navigation history

### Scenario 3: State Preservation
**Objective:** Verify screens maintain their state

**Steps:**
1. On Rides screen, scroll down to see multiple rides
2. Navigate to Earnings tab
3. Navigate back to Rides tab
4. Check scroll position

5. On Earnings screen, scroll down
6. Navigate to Activities tab
7. Navigate back to Earnings tab
8. Check scroll position

**Expected Results:**
✅ Scroll position maintained on each screen
✅ Data still loaded (no re-fetching)
✅ No "rebuilding" flashes
✅ Fast return to previous state

### Scenario 4: Complex Navigation Flow
**Objective:** Test navigation through various app paths

**Steps:**
1. Start on Rides screen
2. Press FAB to add manual ride
3. Fill partial form (don't submit)
4. Press back button
5. Navigate to Profile
6. From Profile, press "Rides" button
7. Verify you're back on Rides screen
8. Press FAB
9. Form should be fresh (not partial filled)
10. Navigate to "Activities" button from Profile
11. Press Rides tab at bottom
12. Press FAB

**Expected Results:**
✅ Navigation from profile works correctly
✅ FAB functional after profile navigation
✅ No stale data
✅ No crashes or freezes

### Scenario 5: Rapid Navigation Stress Test
**Objective:** Test stability under rapid interactions

**Steps:**
1. Rapidly tap between tabs: Rides → Earnings → Activities → Rides (repeat 10 times)
2. While on Rides, rapidly tap FAB, close, FAB, close (5 times)
3. Navigate to Earnings
4. Navigate to Rides
5. Tap FAB immediately
6. Close and tap FAB again immediately

**Expected Results:**
✅ No crashes
✅ No error messages
✅ Smooth transitions
✅ FAB remains responsive
✅ No UI glitches

### Scenario 6: Profile Integration
**Objective:** Verify navigation from profile screen

**Steps:**
1. Navigate to Profile screen
2. Press "Rides" button
3. Should navigate to Rides screen with bottom nav
4. FAB should be visible and functional
5. Go back to Profile
6. Press "Activities" button
7. Should navigate to Activities screen with bottom nav
8. FAB should NOT be visible
9. Press Rides tab at bottom
10. FAB should appear
11. Press FAB

**Expected Results:**
✅ Profile navigation buttons work
✅ Correct tab selected
✅ FAB visibility correct
✅ Bottom nav always visible
✅ FAB functional after profile navigation

## Debug Log Verification

When testing, check the console for these debug messages:

### On App Start:
```
🔵 DEBUG INIT: PersistentNavigationWrapper initialized with index: 0
```

### On Tab Switch:
```
🔵 DEBUG NAV: Switching to screen index: 1 from current index: 0
✅ DEBUG NAV: Screen switched to index: 1
```

### On FAB Press:
```
🔵 DEBUG FAB: Visible on Rides screen
🔵 DEBUG FAB: FAB pressed!
🔵 DEBUG: _showAddManualRideDialog called
🔵 DEBUG: Already on rides screen, navigating directly
🔵 DEBUG: _navigateToAddManualRide called
✅ DEBUG: Widget is mounted, attempting navigation
🔵 DEBUG: Pushing AddManualRideScreen
✅ DEBUG: Building AddManualRideScreen
✅ DEBUG: Navigation command sent successfully
```

### On Return from Add Manual Ride:
```
✅ DEBUG: Returned from AddManualRideScreen
```

## Common Issues & Solutions

### Issue: FAB not appearing on Rides screen
**Check:**
- Is `_currentIndex` set to 0?
- Look for: `🔵 DEBUG FAB: Visible on Rides screen`
- If missing, check IndexedStack implementation

### Issue: FAB not responding
**Check:**
- Look for: `🔵 DEBUG FAB: FAB pressed!`
- If missing, check onPressed callback
- Verify widget is mounted

### Issue: Navigation not switching
**Check:**
- Look for: `🔵 DEBUG NAV:` messages
- Verify setState is being called
- Check _currentIndex value

### Issue: Screens rebuilding on navigation
**Check:**
- Screens should be created once in initState
- IndexedStack should reuse screens
- No duplicate `🔵 DEBUG INIT:` messages for same screen

## Performance Expectations

| Action | Expected Time | What to Watch |
|--------|--------------|---------------|
| Tab Switch | <20ms | Should be instant |
| FAB Press | <50ms | Screen opens smoothly |
| Screen Load | <100ms | Data appears quickly |
| Back Navigation | <50ms | Returns to previous state |

## Success Criteria

All tests pass when:
- ✅ All scenarios complete without errors
- ✅ Debug logs show expected messages
- ✅ No console errors or warnings
- ✅ UI remains responsive
- ✅ State preservation works
- ✅ FAB consistently functional
- ✅ Smooth animations throughout

## Reporting Issues

If you encounter problems, provide:
1. **Scenario** that failed
2. **Steps** taken
3. **Console output** (debug logs and errors)
4. **Expected vs Actual** behavior
5. **Device/Platform** information

## Hot Reload Testing

After making changes:
1. Save file
2. Hot reload (r in terminal or save in IDE)
3. Check console for compile errors
4. Test affected functionality
5. If issues, try hot restart (R in terminal)

---

**Last Updated:** Based on IndexedStack navigation implementation
**Status:** Ready for testing
**Priority:** High - Critical navigation functionality
