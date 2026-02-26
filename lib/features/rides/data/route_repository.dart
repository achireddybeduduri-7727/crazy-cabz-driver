import '../../../core/network/network_service.dart';
import '../../../shared/models/ride_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/ride_history_service.dart';
import '../../../shared/models/route_model.dart';

class RouteRepository {
  final NetworkService _networkService = NetworkService();

  Future<Map<String, dynamic>> getActiveRoute({
    required String driverId,
  }) async {
    try {
      // PRIORITY 1: Check RideHistoryService for local active ride
      final RouteModel? localActiveRide =
          await RideHistoryService.getActiveRide();
      if (localActiveRide != null) {
        return {
          'data': localActiveRide.toJson(),
          'message': 'Loaded from local storage',
        };
      }

      // PRIORITY 2: Check legacy storage
      final localRoutes = StorageService.getJson('active_routes_$driverId');
      if (localRoutes != null) {
        return {'data': localRoutes, 'message': 'Loaded from local storage'};
      }

      // PRIORITY 3: Try network
      final response = await _networkService.get(
        '/routes/active',
        queryParameters: {'driver_id': driverId},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      // Fallback checks
      final RouteModel? fallbackRide = await RideHistoryService.getActiveRide();
      if (fallbackRide != null) {
        return {
          'data': fallbackRide.toJson(),
          'message': 'Loaded from local storage',
        };
      }

      final localRoutes = StorageService.getJson('active_routes_$driverId');
      if (localRoutes != null) {
        return {'data': localRoutes, 'message': 'Loaded from local storage'};
      }

      if (e.toString().contains('404') ||
          e.toString().toLowerCase().contains('no active route') ||
          e.toString().toLowerCase().contains('not found')) {
        return {'data': null, 'message': 'No active route found'};
      }

      return {'data': null, 'message': 'No active route (offline mode)'};
    }
  }

  Future<Map<String, dynamic>> getRouteHistory({
    required String driverId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final localHistory = StorageService.getJson('route_history_$driverId');
      if (localHistory != null && localHistory['routes'] != null) {
        return localHistory;
      }

      final response = await _networkService.get(
        '/routes/history',
        queryParameters: {
          'driver_id': driverId,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      final localHistory = StorageService.getJson('route_history_$driverId');
      if (localHistory != null) {
        return localHistory;
      }
      return {'data': [], 'message': 'No route history available'};
    }
  }

  Future<Map<String, dynamic>> startRoute({required String routeId}) async {
    try {
      final response = await _networkService.post(
        '/routes/$routeId/start',
        data: {'started_at': DateTime.now().toIso8601String()},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to start route: $e');
    }
  }

  Future<Map<String, dynamic>> completeRoute({
    required String routeId,
    String? notes,
  }) async {
    try {
      final response = await _networkService.post(
        '/routes/$routeId/complete',
        data: {
          'completed_at': DateTime.now().toIso8601String(),
          'notes': notes,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to complete route: $e');
    }
  }

  Future<Map<String, dynamic>> cancelRoute({
    required String routeId,
    required String reason,
  }) async {
    try {
      final response = await _networkService.post(
        '/routes/$routeId/cancel',
        data: {
          'cancelled_at': DateTime.now().toIso8601String(),
          'reason': reason,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to cancel route: $e');
    }
  }

  Future<Map<String, dynamic>> updateIndividualRideStatus({
    required String rideId,
    required String status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final data = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        ...?additionalData,
      };

      final response = await _networkService.put(
        '/rides/$rideId/status',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update individual ride status: $e');
    }
  }

  Future<Map<String, dynamic>> markPassengerPresent({
    required String rideId,
    required bool isPresent,
  }) async {
    try {
      final response = await _networkService.put(
        '/rides/$rideId/presence',
        data: {
          'is_present': isPresent,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to mark passenger presence: $e');
    }
  }

  Future<void> addRouteTrackingPoint({
    required String routeId,
    required LocationPoint locationPoint,
  }) async {
    try {
      await _networkService.post(
        '/routes/$routeId/tracking',
        data: locationPoint.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to add route tracking point: $e');
    }
  }

  Future<void> sendOfficeTrackingUpdate({
    required String routeId,
    required Map<String, dynamic> trackingData,
  }) async {
    try {
      await _networkService.post(
        '/routes/$routeId/office-tracking',
        data: {
          'route_id': routeId,
          'timestamp': DateTime.now().toIso8601String(),
          ...trackingData,
        },
      );
    } catch (e) {
      throw Exception('Failed to send office tracking update: $e');
    }
  }

  Future<void> sendEmergencyAlert({
    required String driverId,
    required String routeId,
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    try {
      await _networkService.post(
        '/emergency/alert',
        data: {
          'driver_id': driverId,
          'route_id': routeId,
          'location': {'latitude': latitude, 'longitude': longitude},
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'route_emergency',
        },
      );
    } catch (e) {
      throw Exception('Failed to send emergency alert: $e');
    }
  }

  Future<Map<String, dynamic>> getPassengerDetails({
    required String passengerId,
  }) async {
    try {
      final response = await _networkService.get('/passengers/$passengerId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get passenger details: $e');
    }
  }

  Future<Map<String, dynamic>> updatePassengerLocation({
    required String passengerId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final response = await _networkService.put(
        '/passengers/$passengerId/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update passenger location: $e');
    }
  }

  Future<Map<String, dynamic>> getOptimizedRoute({
    required String routeId,
    required double startLatitude,
    required double startLongitude,
  }) async {
    try {
      final response = await _networkService.post(
        '/routes/$routeId/optimize',
        data: {
          'start_latitude': startLatitude,
          'start_longitude': startLongitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get optimized route: $e');
    }
  }

  Future<Map<String, dynamic>> getRouteNavigation({
    required String routeId,
    required double currentLatitude,
    required double currentLongitude,
  }) async {
    try {
      final response = await _networkService.get(
        '/routes/$routeId/navigation',
        queryParameters: {
          'current_lat': currentLatitude.toString(),
          'current_lng': currentLongitude.toString(),
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get route navigation: $e');
    }
  }
}
