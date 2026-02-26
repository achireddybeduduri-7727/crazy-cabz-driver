import '../../shared/models/earnings_model.dart';
import '../../shared/models/ride_model.dart';

class EarningsService {
  static final EarningsService _instance = EarningsService._internal();
  factory EarningsService() => _instance;
  EarningsService._internal();

  // In-memory storage for demo purposes
  final List<EarningsModel> _earnings = [];
  final Map<String, EarningsSummary> _summaries = {};

  Future<void> initialize() async {
    // Initialize with some sample data for demo
    _generateSampleData();
  }

  void _generateSampleData() {
    // Generate sample earnings for demo
    final now = DateTime.now();
    for (int i = 0; i < 10; i++) {
      final earning = EarningsModel(
        id: 'sample_$i',
        rideId: 'ride_$i',
        driverId: 'current_driver',
        baseFare: 2.5,
        distanceFare: 15.0,
        timeFare: 8.0,
        surgeFare: i % 3 == 0 ? 5.0 : 0.0,
        tips: i % 2 == 0 ? 3.0 : 0.0,
        tolls: 0.0,
        totalFare: 25.5 + (i % 3 == 0 ? 5.0 : 0.0) + (i % 2 == 0 ? 3.0 : 0.0),
        platformFee: 5.1,
        netEarnings: 20.4 + (i % 3 == 0 ? 5.0 : 0.0) + (i % 2 == 0 ? 3.0 : 0.0),
        earnedAt: now.subtract(Duration(days: i, hours: i * 2)),
        paymentStatus: 'paid',
        rideType: 'regular',
        distance: 12.5,
        duration: 25,
        customerName: 'Customer ${i + 1}',
        pickupAddress: '${100 + i} Main St',
        dropAddress: '${200 + i} Oak Ave',
      );
      _earnings.add(earning);
    }
  }

  /// Add earnings from completed ride
  Future<void> addEarnings(EarningsModel earnings) async {
    _earnings.add(earnings);
    await _updateDailySummary(earnings);
  }

  /// Get all earnings for a driver
  List<EarningsModel> getAllEarnings(String driverId) {
    return _earnings
        .where((earnings) => earnings.driverId == driverId)
        .toList();
  }

  /// Get earnings for a specific date range
  List<EarningsModel> getEarningsInRange(
    String driverId,
    DateTime start,
    DateTime end,
  ) {
    return _earnings
        .where(
          (earnings) =>
              earnings.driverId == driverId &&
              earnings.earnedAt.isAfter(start) &&
              earnings.earnedAt.isBefore(end),
        )
        .toList();
  }

  /// Get today's earnings
  List<EarningsModel> getTodayEarnings(String driverId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getEarningsInRange(driverId, startOfDay, endOfDay);
  }

  /// Get this week's earnings
  List<EarningsModel> getWeekEarnings(String driverId) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));

    return getEarningsInRange(driverId, startOfWeekDay, endOfWeek);
  }

  /// Get this month's earnings
  List<EarningsModel> getMonthEarnings(String driverId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    return getEarningsInRange(driverId, startOfMonth, endOfMonth);
  }

  /// Calculate earnings summary for a period
  EarningsSummaryData calculateSummary(List<EarningsModel> earnings) {
    if (earnings.isEmpty) {
      return EarningsSummaryData(
        totalEarnings: 0,
        netEarnings: 0,
        platformFees: 0,
        tips: 0,
        totalRides: 0,
        totalDistance: 0,
        totalTimeMinutes: 0,
        avgEarningsPerRide: 0,
        avgEarningsPerKm: 0,
        avgEarningsPerHour: 0,
      );
    }

    final totalEarnings = earnings.fold(0.0, (sum, e) => sum + e.totalFare);
    final netEarnings = earnings.fold(0.0, (sum, e) => sum + e.netEarnings);
    final platformFees = earnings.fold(0.0, (sum, e) => sum + e.platformFee);
    final tips = earnings.fold(0.0, (sum, e) => sum + e.tips);
    final totalRides = earnings.length;
    final totalDistance = earnings.fold(0.0, (sum, e) => sum + e.distance);
    final totalTimeMinutes = earnings.fold(0, (sum, e) => sum + e.duration);

    return EarningsSummaryData(
      totalEarnings: totalEarnings,
      netEarnings: netEarnings,
      platformFees: platformFees,
      tips: tips,
      totalRides: totalRides,
      totalDistance: totalDistance,
      totalTimeMinutes: totalTimeMinutes,
      avgEarningsPerRide: totalRides > 0 ? totalEarnings / totalRides : 0,
      avgEarningsPerKm: totalDistance > 0 ? totalEarnings / totalDistance : 0,
      avgEarningsPerHour: totalTimeMinutes > 0
          ? (totalEarnings / totalTimeMinutes) * 60
          : 0,
    );
  }

  /// Get daily summaries for analytics
  List<EarningsSummary> getDailySummaries(String driverId, int days) {
    final summaries = <EarningsSummary>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEarnings = getEarningsInRange(
        driverId,
        dayStart,
        dayStart.add(const Duration(days: 1)),
      );

      if (dayEarnings.isNotEmpty) {
        final summary = calculateSummary(dayEarnings);
        summaries.add(
          EarningsSummary(
            date: dayStart,
            totalEarnings: summary.totalEarnings,
            netEarnings: summary.netEarnings,
            platformFees: summary.platformFees,
            tips: summary.tips,
            totalRides: summary.totalRides,
            totalDistance: summary.totalDistance,
            totalTime: summary.totalTimeMinutes,
            avgRating: 0, // You can calculate this from ride ratings
          ),
        );
      }
    }

    return summaries.reversed.toList();
  }

  /// Update daily summary when new earnings are added
  Future<void> _updateDailySummary(EarningsModel earnings) async {
    final date = DateTime(
      earnings.earnedAt.year,
      earnings.earnedAt.month,
      earnings.earnedAt.day,
    );
    final dateKey = date.toIso8601String().split('T')[0];

    final existingSummary = _summaries[dateKey];

    if (existingSummary != null) {
      // Update existing summary
      final updatedSummary = existingSummary.copyWith(
        totalEarnings: existingSummary.totalEarnings + earnings.totalFare,
        netEarnings: existingSummary.netEarnings + earnings.netEarnings,
        platformFees: existingSummary.platformFees + earnings.platformFee,
        tips: existingSummary.tips + earnings.tips,
        totalRides: existingSummary.totalRides + 1,
        totalDistance: existingSummary.totalDistance + earnings.distance,
        totalTime: existingSummary.totalTime + earnings.duration,
      );
      _summaries[dateKey] = updatedSummary;
    } else {
      // Create new summary
      final newSummary = EarningsSummary(
        date: date,
        totalEarnings: earnings.totalFare,
        netEarnings: earnings.netEarnings,
        platformFees: earnings.platformFee,
        tips: earnings.tips,
        totalRides: 1,
        totalDistance: earnings.distance,
        totalTime: earnings.duration,
        avgRating: 0,
      );
      _summaries[dateKey] = newSummary;
    }
  }

  /// Create earnings from completed ride
  EarningsModel createEarningsFromRide(RideModel ride) {
    // This would typically calculate based on your business logic
    const double baseFareRate = 2.5;
    const double perKmRate = 1.2;
    const double perMinuteRate = 0.15;
    const double platformFeeRate = 0.2; // 20%

    final distance = ride.distance ?? 0;
    final duration = ride.duration ?? 0;

    final baseFare = baseFareRate;
    final distanceFare = distance * perKmRate;
    final timeFare = duration * perMinuteRate;
    final surgeFare = 0.0; // You can implement surge pricing logic
    final tips = 0.0; // Tips would be added separately
    final tolls = 0.0; // Tolls would be calculated based on route

    final totalFare =
        baseFare + distanceFare + timeFare + surgeFare + tips + tolls;
    final platformFee = totalFare * platformFeeRate;
    final netEarnings = totalFare - platformFee;

    return EarningsModel(
      id: 'earnings_${ride.id}',
      rideId: ride.id,
      driverId: ride.driverId,
      baseFare: baseFare,
      distanceFare: distanceFare,
      timeFare: timeFare,
      surgeFare: surgeFare,
      tips: tips,
      tolls: tolls,
      totalFare: totalFare,
      platformFee: platformFee,
      netEarnings: netEarnings,
      earnedAt: ride.completedAt ?? DateTime.now(),
      paymentStatus: 'paid',
      rideType: 'regular',
      distance: distance,
      duration: duration,
      customerName: ride.employeeName,
      pickupAddress: ride.pickupLocation.address,
      dropAddress: ride.dropLocation.address,
    );
  }

  /// Get payment status summary
  Map<String, double> getPaymentStatusSummary(String driverId) {
    final earnings = getAllEarnings(driverId);
    final Map<String, double> summary = {
      'paid': 0.0,
      'pending': 0.0,
      'cancelled': 0.0,
    };

    for (final earning in earnings) {
      summary[earning.paymentStatus] =
          (summary[earning.paymentStatus] ?? 0.0) + earning.netEarnings;
    }

    return summary;
  }

  /// Generate earnings report for tax purposes
  Map<String, dynamic> generateTaxReport(String driverId, int year) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);
    final yearEarnings = getEarningsInRange(driverId, startOfYear, endOfYear);

    final summary = calculateSummary(yearEarnings);

    return {
      'year': year,
      'totalEarnings': summary.totalEarnings,
      'netEarnings': summary.netEarnings,
      'platformFees': summary.platformFees,
      'tips': summary.tips,
      'totalRides': summary.totalRides,
      'totalDistance': summary.totalDistance,
      'totalHours': summary.totalTimeMinutes / 60,
      'avgEarningsPerRide': summary.avgEarningsPerRide,
      'avgEarningsPerKm': summary.avgEarningsPerKm,
      'avgEarningsPerHour': summary.avgEarningsPerHour,
      'monthlyBreakdown': _getMonthlyBreakdown(yearEarnings),
    };
  }

  Map<int, Map<String, dynamic>> _getMonthlyBreakdown(
    List<EarningsModel> earnings,
  ) {
    final Map<int, List<EarningsModel>> monthlyEarnings = {};

    for (final earning in earnings) {
      final month = earning.earnedAt.month;
      monthlyEarnings[month] = (monthlyEarnings[month] ?? [])..add(earning);
    }

    final Map<int, Map<String, dynamic>> breakdown = {};

    for (final entry in monthlyEarnings.entries) {
      final summary = calculateSummary(entry.value);
      breakdown[entry.key] = {
        'totalEarnings': summary.totalEarnings,
        'netEarnings': summary.netEarnings,
        'totalRides': summary.totalRides,
        'totalDistance': summary.totalDistance,
        'totalHours': summary.totalTimeMinutes / 60,
      };
    }

    return breakdown;
  }
}

extension EarningsSummaryExtension on EarningsSummary {
  EarningsSummary copyWith({
    DateTime? date,
    double? totalEarnings,
    double? netEarnings,
    double? platformFees,
    double? tips,
    int? totalRides,
    double? totalDistance,
    int? totalTime,
    double? avgRating,
  }) {
    return EarningsSummary(
      date: date ?? this.date,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      netEarnings: netEarnings ?? this.netEarnings,
      platformFees: platformFees ?? this.platformFees,
      tips: tips ?? this.tips,
      totalRides: totalRides ?? this.totalRides,
      totalDistance: totalDistance ?? this.totalDistance,
      totalTime: totalTime ?? this.totalTime,
      avgRating: avgRating ?? this.avgRating,
    );
  }
}

class EarningsSummaryData {
  final double totalEarnings;
  final double netEarnings;
  final double platformFees;
  final double tips;
  final int totalRides;
  final double totalDistance;
  final int totalTimeMinutes;
  final double avgEarningsPerRide;
  final double avgEarningsPerKm;
  final double avgEarningsPerHour;

  EarningsSummaryData({
    required this.totalEarnings,
    required this.netEarnings,
    required this.platformFees,
    required this.tips,
    required this.totalRides,
    required this.totalDistance,
    required this.totalTimeMinutes,
    required this.avgEarningsPerRide,
    required this.avgEarningsPerKm,
    required this.avgEarningsPerHour,
  });
}
