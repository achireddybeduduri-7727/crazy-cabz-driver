import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/route_model.dart';
import '../utils/app_logger.dart';
import 'firebase_ride_history_service.dart';

class RideHistoryService {
  static const String _activeRideKey = 'active_ride';
  static const String _rideHistoryKey = 'ride_history';
  static const String _rideCounterKey = 'ride_counter';

  // Save active ride
  static Future<void> saveActiveRide(RouteModel route) async {
    try {
      print('💾 [STORAGE] Saving active ride: ${route.id}');
      print('💾 [STORAGE] Route status: ${route.status}');
      print('💾 [STORAGE] Number of rides: ${route.rides.length}');
      print('💾 [STORAGE] Scheduled time: ${route.scheduledTime}');

      final prefs = await SharedPreferences.getInstance();
      final routeJson = jsonEncode(route.toJson());
      final success = await prefs.setString(_activeRideKey, routeJson);

      if (success) {
        print(
          '✅ [STORAGE] Active ride saved successfully to key: $_activeRideKey',
        );
        // Verify it was saved
        final verification = prefs.getString(_activeRideKey);
        if (verification != null) {
          print(
            '✅ [STORAGE] Verification: Data exists in storage (${verification.length} bytes)',
          );
        } else {
          print(
            '⚠️ [STORAGE] WARNING: Verification failed - data not found after save!',
          );
        }
      } else {
        print('❌ [STORAGE] Failed to save - setString returned false');
      }

      AppLogger.info('Active ride saved: ${route.id}');
    } catch (e) {
      print('❌ [STORAGE] Exception while saving active ride: $e');
      AppLogger.error('Failed to save active ride: $e');
      rethrow; // Re-throw to let caller know it failed
    }
  }

  // Get active ride
  static Future<RouteModel?> getActiveRide() async {
    try {
      print('🔍 [STORAGE] Loading active ride from key: $_activeRideKey');

      final prefs = await SharedPreferences.getInstance();
      final routeJson = prefs.getString(_activeRideKey);

      if (routeJson != null) {
        print('✅ [STORAGE] Found active ride data (${routeJson.length} bytes)');
        final routeData = jsonDecode(routeJson) as Map<String, dynamic>;
        final route = RouteModel.fromJson(routeData);

        print('✅ [STORAGE] Active ride loaded: ${route.id}');
        print('✅ [STORAGE] Route status: ${route.status}');
        print('✅ [STORAGE] Number of rides: ${route.rides.length}');

        AppLogger.info('Active ride loaded: ${route.id}');
        return route;
      } else {
        print('ℹ️ [STORAGE] No active ride found in storage');
        return null;
      }
    } catch (e) {
      print('❌ [STORAGE] Error loading active ride: $e');
      AppLogger.error('Failed to load active ride: $e');
      return null;
    }
  }

  // Clear active ride (when completed or cancelled)
  static Future<void> clearActiveRide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeRideKey);
      AppLogger.info('Active ride cleared');
    } catch (e) {
      AppLogger.error('Failed to clear active ride: $e');
    }
  }

  // Add ride to history
  static Future<void> addToHistory(RouteModel route) async {
    try {
      print('📝 Adding ride to history: ${route.id}');

      // Store in Firebase (cloud storage)
      try {
        print('🔥 Storing ride in Firebase...');
        await FirebaseRideHistoryService.storeCompletedRide(route);
        print('✅ Ride successfully stored in Firebase: ${route.id}');
      } catch (firebaseError) {
        print(
          '⚠️ Firebase storage failed (will use local only): $firebaseError',
        );
        AppLogger.error('Firebase storage failed: $firebaseError');
        // Continue with local storage even if Firebase fails
      }

      // Also store in local SharedPreferences (backup + offline support)
      final prefs = await SharedPreferences.getInstance();

      // Get existing history
      List<RouteModel> history = await getRideHistory();

      print('📊 Current history count: ${history.length}');

      // Add new route to the beginning (most recent first)
      history.insert(0, route);

      print('📊 New history count: ${history.length}');

      // Keep only last 100 rides to prevent excessive storage
      if (history.length > 100) {
        history = history.take(100).toList();
      }

      // Save updated history
      final historyJson = jsonEncode(history.map((r) => r.toJson()).toList());
      await prefs.setString(_rideHistoryKey, historyJson);

      // Update ride counter
      await _incrementRideCounter();

      print('✅ Ride successfully added to local history: ${route.id}');
      AppLogger.info('✅ Ride added to local history: ${route.id}');

      // Debug: Print what's actually stored
      print('\n🔍 Verifying storage after adding ride...');
      await debugPrintStoredHistory();
    } catch (e) {
      print('❌ Failed to add ride to history: $e');
      AppLogger.error('Failed to add ride to history: $e');
      rethrow;
    }
  }

  // Get ride history (merges Firebase and local storage)
  static Future<List<RouteModel>> getRideHistory() async {
    try {
      print('📖 Loading ride history from local storage...');

      // Load from local storage first (faster, offline support)
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_rideHistoryKey);
      List<RouteModel> localHistory = [];

      if (historyJson != null) {
        final historyData = jsonDecode(historyJson) as List<dynamic>;
        localHistory = historyData
            .map((data) => RouteModel.fromJson(data as Map<String, dynamic>))
            .toList();
        print('✅ Loaded ${localHistory.length} rides from local storage');
      } else {
        print('📭 No ride history found in local storage');
      }

      // Return local data immediately for fast UI rendering
      // Firebase sync happens in background (optional)
      print('✅ Returning ${localHistory.length} rides (local data)');
      AppLogger.info('� Loaded ${localHistory.length} rides from history');

      // Try to sync with Firebase in the background (non-blocking)
      // This runs asynchronously without waiting
      _syncFirebaseInBackground(prefs, localHistory);

      return localHistory;
    } catch (e) {
      print('❌ Failed to load ride history: $e');
      AppLogger.error('Failed to load ride history: $e');
      return [];
    }
  }

  // Background sync with Firebase (non-blocking)
  static void _syncFirebaseInBackground(
    SharedPreferences prefs,
    List<RouteModel> localHistory,
  ) async {
    try {
      print('🔥 Background: Attempting Firebase sync...');

      // Set a timeout to prevent long waits
      final firebaseHistory =
          await FirebaseRideHistoryService.getCompletedRides().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('⏱️ Firebase sync timed out (5s) - using local data');
              return [];
            },
          );

      if (firebaseHistory.isNotEmpty) {
        print(
          '✅ Background: Loaded ${firebaseHistory.length} rides from Firebase',
        );

        // Only update local storage if Firebase has newer/more data
        if (firebaseHistory.length > localHistory.length) {
          print('💾 Background: Updating local storage with Firebase data');
          final historyJson = jsonEncode(
            firebaseHistory.map((r) => r.toJson()).toList(),
          );
          await prefs.setString(_rideHistoryKey, historyJson);
          print('✅ Background: Local storage synced with Firebase');
        } else {
          print('ℹ️ Background: Local data is up to date');
        }
      } else {
        print('ℹ️ Background: No Firebase data or empty');
      }
    } catch (firebaseError) {
      print('⚠️ Background: Firebase sync failed: $firebaseError');
      // This is fine - we already returned local data
    }
  }

  // Get ride statistics
  static Future<Map<String, int>> getRideStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getRideHistory();
      final totalRides = prefs.getInt(_rideCounterKey) ?? 0;

      int completedRides = 0;
      int cancelledRides = 0;

      for (final route in history) {
        if (route.status == RouteStatus.completed) {
          completedRides++;
        } else if (route.status == RouteStatus.cancelled) {
          cancelledRides++;
        }
      }

      return {
        'total': totalRides,
        'completed': completedRides,
        'cancelled': cancelledRides,
        'recent': history.length,
      };
    } catch (e) {
      AppLogger.error('Failed to get ride statistics: $e');
      return {'total': 0, 'completed': 0, 'cancelled': 0, 'recent': 0};
    }
  }

  // Private method to increment ride counter
  static Future<void> _incrementRideCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_rideCounterKey) ?? 0;
      await prefs.setInt(_rideCounterKey, currentCount + 1);
    } catch (e) {
      AppLogger.error('Failed to increment ride counter: $e');
    }
  }

  // Clear all history (for testing or reset)
  static Future<void> clearAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rideHistoryKey);
      await prefs.remove(_rideCounterKey);
      await prefs.remove(_activeRideKey);
      AppLogger.info('All ride history cleared');
    } catch (e) {
      AppLogger.error('Failed to clear ride history: $e');
    }
  }

  // Debug function to print all stored history data
  static Future<void> debugPrintStoredHistory() async {
    try {
      print('\n═══════════════════════════════════════════════════');
      print('🔍 DEBUG: STORED RIDE HISTORY DATA');
      print('═══════════════════════════════════════════════════');

      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_rideHistoryKey);

      if (historyJson == null || historyJson.isEmpty) {
        print('❌ NO HISTORY DATA FOUND IN STORAGE');
        print('   Storage key: $_rideHistoryKey');
        print('   Value: null or empty');
        print('═══════════════════════════════════════════════════\n');
        return;
      }

      print('✅ FOUND STORED DATA');
      print('   Storage key: $_rideHistoryKey');
      print('   Raw JSON length: ${historyJson.length} characters');
      print('\n📄 RAW JSON DATA:');
      print('---------------------------------------------------');
      print(historyJson);
      print('---------------------------------------------------\n');

      // Parse and display structured data
      final historyData = jsonDecode(historyJson) as List<dynamic>;
      print('📊 PARSED DATA:');
      print('   Total routes in history: ${historyData.length}');
      print('\n');

      for (int i = 0; i < historyData.length; i++) {
        final routeData = historyData[i] as Map<String, dynamic>;
        print('   [$i] Route Details:');
        print('       ID: ${routeData['id']}');
        print('       Status: ${routeData['status']}');
        print('       Created: ${routeData['createdAt']}');
        print('       Completed: ${routeData['completedAt']}');

        // Count rides in this route
        final rides = routeData['rides'] as List<dynamic>?;
        if (rides != null) {
          print('       Number of rides: ${rides.length}');
          for (int j = 0; j < rides.length; j++) {
            final ride = rides[j] as Map<String, dynamic>;
            print('           Ride $j: ${ride['id']} - ${ride['status']}');
          }
        }
        print('');
      }

      // Get statistics
      final stats = await getRideStatistics();
      print('📈 STATISTICS:');
      print('   Total: ${stats['total']}');
      print('   Completed: ${stats['completed']}');
      print('   Cancelled: ${stats['cancelled']}');
      print('   Recent: ${stats['recent']}');

      final rideCounter = prefs.getInt(_rideCounterKey) ?? 0;
      print('   Ride Counter: $rideCounter');

      print('═══════════════════════════════════════════════════\n');
    } catch (e, stackTrace) {
      print('\n❌ ERROR WHILE DEBUGGING HISTORY DATA');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════\n');
    }
  }
}
