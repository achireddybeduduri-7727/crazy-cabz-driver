import 'package:dio/dio.dart';
import '../../../core/network/network_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/ride_model.dart';

class RideRepository {
  final NetworkService _networkService = NetworkService();

  Future<Map<String, dynamic>> createRide({
    required String driverId,
    required RideModel ride,
  }) async {
    try {
      final response = await _networkService.post(
        AppConstants.ridesEndpoint,
        data: {'driverId': driverId, ...ride.toJson()},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> updateRideStatus({
    required String rideId,
    required String status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _networkService.put(
        '${AppConstants.ridesEndpoint}/$rideId/status',
        data: {
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalData,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> addTrackingPoint({
    required String rideId,
    required LocationPoint locationPoint,
  }) async {
    try {
      final response = await _networkService.post(
        '${AppConstants.trackingEndpoint}/$rideId/location',
        data: locationPoint.toJson(),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> completeRide({
    required String rideId,
    required double totalDistance,
    required int duration,
    String? notes,
  }) async {
    try {
      final response = await _networkService.put(
        '${AppConstants.ridesEndpoint}/$rideId/complete',
        data: {
          'totalDistance': totalDistance,
          'duration': duration,
          'notes': notes,
          'completedAt': DateTime.now().toIso8601String(),
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> cancelRide({
    required String rideId,
    required String reason,
  }) async {
    try {
      final response = await _networkService.put(
        '${AppConstants.ridesEndpoint}/$rideId/cancel',
        data: {
          'reason': reason,
          'cancelledAt': DateTime.now().toIso8601String(),
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> getRideHistory({
    required String driverId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _networkService.get(
        '${AppConstants.ridesEndpoint}/driver/$driverId',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> getActiveRide({required String driverId}) async {
    try {
      final response = await _networkService.get(
        '${AppConstants.ridesEndpoint}/driver/$driverId/active',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> sendEmergencyAlert({
    required String driverId,
    required String rideId,
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    try {
      final response = await _networkService.post(
        '/emergency/alert',
        data: {
          'driverId': driverId,
          'rideId': rideId,
          'latitude': latitude,
          'longitude': longitude,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }
}
