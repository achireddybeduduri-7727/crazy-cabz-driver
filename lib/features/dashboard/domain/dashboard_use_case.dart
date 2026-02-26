import '../../../shared/models/ride_model.dart';
import '../data/dashboard_repository.dart';
import '../presentation/bloc/dashboard_state.dart';

class DashboardUseCase {
  final DashboardRepository _dashboardRepository = DashboardRepository();

  Future<DashboardStats> getDashboardStats({required String driverId}) async {
    try {
      final response = await _dashboardRepository.getDashboardStats(
        driverId: driverId,
      );
      return DashboardStats.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to load dashboard stats: $e');
    }
  }

  Future<RideModel?> getActiveRide({required String driverId}) async {
    try {
      final response = await _dashboardRepository.getActiveRide(
        driverId: driverId,
      );
      if (response['data'] != null) {
        return RideModel.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load active ride: $e');
    }
  }

  Future<List<RideModel>> getRecentRides({
    required String driverId,
    int limit = 5,
  }) async {
    try {
      final response = await _dashboardRepository.getRecentRides(
        driverId: driverId,
        limit: limit,
      );
      final List<dynamic> ridesData = response['data']['rides'];
      return ridesData.map((json) => RideModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load recent rides: $e');
    }
  }

  Future<bool> updateDriverStatus({
    required String driverId,
    required bool isOnline,
  }) async {
    try {
      final response = await _dashboardRepository.updateDriverStatus(
        driverId: driverId,
        isOnline: isOnline,
      );
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to update driver status: $e');
    }
  }

  Future<DashboardStats> getTodayStats({required String driverId}) async {
    try {
      final response = await _dashboardRepository.getTodayStats(
        driverId: driverId,
      );
      return DashboardStats.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to load today stats: $e');
    }
  }

  Future<DashboardStats> getWeeklyStats({required String driverId}) async {
    try {
      final response = await _dashboardRepository.getWeeklyStats(
        driverId: driverId,
      );
      return DashboardStats.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to load weekly stats: $e');
    }
  }

  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _dashboardRepository.updateDriverLocation(
        driverId: driverId,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      throw Exception('Failed to update driver location: $e');
    }
  }

  // Business logic helpers
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String formatEarnings(double earnings) {
    return '\$${earnings.toStringAsFixed(2)}';
  }

  String formatOnlineTime(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  double calculateCompletionRate(int completed, int total) {
    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }

  String getStatusColor(String status) {
    switch (status) {
      case 'online':
        return '0xFF4CAF50'; // Green
      case 'offline':
        return '0xFF757575'; // Grey
      case 'busy':
        return '0xFFFF9800'; // Orange
      case 'break':
        return '0xFF2196F3'; // Blue
      default:
        return '0xFF757575'; // Grey
    }
  }

  bool canGoOnline(DashboardStats stats) {
    // Add business logic for when driver can go online
    // For example, check if vehicle documents are valid, etc.
    return true;
  }

  String getPerformanceMessage(DashboardStats stats) {
    final completionRate = calculateCompletionRate(
      stats.completedRides,
      stats.totalRides,
    );

    if (completionRate >= 95) {
      return 'Excellent performance! Keep it up!';
    } else if (completionRate >= 85) {
      return 'Great job! You\'re doing well.';
    } else if (completionRate >= 70) {
      return 'Good work! Room for improvement.';
    } else {
      return 'Focus on completing more rides.';
    }
  }

  List<Map<String, dynamic>> getQuickActions(bool hasActiveRide) {
    if (hasActiveRide) {
      return [
        {
          'title': 'Current Ride',
          'icon': 'car_rental',
          'route': '/rides',
          'color': '0xFF4CAF50',
        },
        {
          'title': 'Navigation',
          'icon': 'navigation',
          'route': '/navigation',
          'color': '0xFF2196F3',
        },
        {
          'title': 'Emergency',
          'icon': 'emergency',
          'route': '/emergency',
          'color': '0xFFF44336',
        },
      ];
    } else {
      return [
        {
          'title': 'Activities',
          'icon': 'history',
          'route': '/history',
          'color': '0xFF9C27B0',
        },
        {
          'title': 'Earnings',
          'icon': 'account_balance_wallet',
          'route': '/earnings',
          'color': '0xFF4CAF50',
        },
        {
          'title': 'Support',
          'icon': 'support_agent',
          'route': '/support',
          'color': '0xFF FF9800',
        },
        {
          'title': 'Settings',
          'icon': 'settings',
          'route': '/settings',
          'color': '0xFF607D8B',
        },
      ];
    }
  }
}
