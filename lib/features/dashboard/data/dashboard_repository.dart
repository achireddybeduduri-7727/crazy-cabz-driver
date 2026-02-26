import 'package:dio/dio.dart';
import '../../../core/network/network_service.dart';
import '../../../core/constants/app_constants.dart';

class DashboardRepository {
  final NetworkService _networkService = NetworkService();

  Future<Map<String, dynamic>> getDashboardStats({
    required String driverId,
  }) async {
    try {
      final response = await _networkService.get('/dashboard/stats/$driverId');
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

  Future<Map<String, dynamic>> getRecentRides({
    required String driverId,
    int limit = 5,
  }) async {
    try {
      final response = await _networkService.get(
        '${AppConstants.ridesEndpoint}/driver/$driverId/recent',
        queryParameters: {'limit': limit},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> updateDriverStatus({
    required String driverId,
    required bool isOnline,
  }) async {
    try {
      final response = await _networkService.put(
        '/driver/$driverId/status',
        data: {
          'isOnline': isOnline,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> getTodayStats({required String driverId}) async {
    try {
      final response = await _networkService.get(
        '/dashboard/stats/$driverId/today',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> getWeeklyStats({
    required String driverId,
  }) async {
    try {
      final response = await _networkService.get(
        '/dashboard/stats/$driverId/weekly',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> getDriverLocation({
    required String driverId,
  }) async {
    try {
      final response = await _networkService.get('/driver/$driverId/location');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _networkService.put(
        '/driver/$driverId/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }
}
