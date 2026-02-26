import 'package:firebase_database/firebase_database.dart';
import '../../shared/models/route_model.dart';
import '../utils/app_logger.dart';

class FirebaseRideHistoryService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static const String _driversPath = 'drivers';
  static const String _rideHistoryPath = 'ride_history';

  // Get the current driver ID (you may want to get this from auth service)
  static String get _currentDriverId =>
      'current_driver_id'; // TODO: Get from auth

  // Store completed ride in Firebase with timestamps
  static Future<void> storeCompletedRide(RouteModel route) async {
    try {
      final driverRef = _database.ref(
        '$_driversPath/$_currentDriverId/$_rideHistoryPath',
      );

      // Convert route to JSON (using existing toJson method)
      final rideData = route.toJson();

      // Add timestamp metadata
      rideData['firebase_stored_at'] = DateTime.now().millisecondsSinceEpoch;
      rideData['driver_id'] = _currentDriverId;

      // Store with timestamp as key to ensure uniqueness and ordering
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await driverRef.child(timestamp.toString()).set(rideData);

      AppLogger.info('🔥 Completed ride stored in Firebase: ${route.id}');

      // Also update driver statistics
      await _updateDriverStats(route);
    } catch (e) {
      AppLogger.error('❌ Failed to store completed ride in Firebase: $e');
      rethrow;
    }
  }

  // Get all completed rides for the current driver
  static Future<List<RouteModel>> getCompletedRides() async {
    try {
      final driverRef = _database.ref(
        '$_driversPath/$_currentDriverId/$_rideHistoryPath',
      );
      final snapshot = await driverRef.orderByKey().limitToLast(100).get();

      if (!snapshot.exists) {
        AppLogger.info('🔥 No ride history found in Firebase');
        return [];
      }

      final List<RouteModel> rides = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      // Convert Firebase data back to RouteModel objects
      for (final entry in data.entries) {
        try {
          final rideData = Map<String, dynamic>.from(entry.value as Map);
          final route = RouteModel.fromJson(rideData);
          rides.add(route);
        } catch (e) {
          AppLogger.error('Failed to parse ride data: $e');
        }
      }

      // Sort by completion time (most recent first)
      rides.sort(
        (a, b) => (b.completedAt ?? b.createdAt).compareTo(
          a.completedAt ?? a.createdAt,
        ),
      );

      AppLogger.info('🔥 Loaded ${rides.length} rides from Firebase');
      return rides;
    } catch (e) {
      AppLogger.error('❌ Failed to load ride history from Firebase: $e');
      return [];
    }
  }

  // Listen to real-time updates for ride history
  static Stream<List<RouteModel>> getRideHistoryStream() {
    try {
      final driverRef = _database.ref(
        '$_driversPath/$_currentDriverId/$_rideHistoryPath',
      );

      return driverRef.orderByKey().limitToLast(100).onValue.map((event) {
        if (!event.snapshot.exists) {
          return <RouteModel>[];
        }

        final List<RouteModel> rides = [];
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        for (final entry in data.entries) {
          try {
            final rideData = Map<String, dynamic>.from(entry.value as Map);
            final route = RouteModel.fromJson(rideData);
            rides.add(route);
          } catch (e) {
            AppLogger.error('Failed to parse ride data in stream: $e');
          }
        }

        // Sort by completion time (most recent first)
        rides.sort(
          (a, b) => (b.completedAt ?? b.createdAt).compareTo(
            a.completedAt ?? a.createdAt,
          ),
        );

        return rides;
      });
    } catch (e) {
      AppLogger.error('❌ Failed to create ride history stream: $e');
      return Stream.value([]);
    }
  }

  // Update driver statistics
  static Future<void> _updateDriverStats(RouteModel route) async {
    try {
      final statsRef = _database.ref(
        '$_driversPath/$_currentDriverId/statistics',
      );

      // Get current stats
      final snapshot = await statsRef.get();
      Map<String, dynamic> stats = {};

      if (snapshot.exists) {
        stats = Map<String, dynamic>.from(snapshot.value as Map);
      }

      // Calculate route totals
      double routeTotalFare = 0.0;
      double routeTotalDistance = 0.0;

      for (var ride in route.rides) {
        routeTotalFare +=
            ride.distance ?? 0.0; // Using distance as fare placeholder
        routeTotalDistance += ride.distance ?? 0.0;
      }

      // Update stats
      final currentTotal = stats['total_rides'] ?? 0;
      final currentEarnings = stats['total_earnings'] ?? 0.0;
      final currentDistance = stats['total_distance_km'] ?? 0.0;

      await statsRef.update({
        'total_rides': currentTotal + route.rides.length,
        'total_earnings': currentEarnings + routeTotalFare,
        'total_distance_km': currentDistance + routeTotalDistance,
        'last_ride_completed_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      AppLogger.info('🔥 Driver statistics updated');
    } catch (e) {
      AppLogger.error('❌ Failed to update driver statistics: $e');
    }
  }

  // Get driver statistics
  static Future<Map<String, dynamic>> getDriverStatistics() async {
    try {
      final statsRef = _database.ref(
        '$_driversPath/$_currentDriverId/statistics',
      );
      final snapshot = await statsRef.get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }

      return {
        'total_rides': 0,
        'total_earnings': 0.0,
        'total_distance_km': 0.0,
      };
    } catch (e) {
      AppLogger.error('❌ Failed to get driver statistics: $e');
      return {
        'total_rides': 0,
        'total_earnings': 0.0,
        'total_distance_km': 0.0,
      };
    }
  }
}
