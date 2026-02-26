import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/services/earnings_service.dart';
import '../../../../shared/models/earnings_model.dart';
import '../../../../shared/models/driver_model.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class EarningsScreen extends StatefulWidget {
  final DriverModel? driver;

  const EarningsScreen({super.key, this.driver});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final EarningsService _earningsService = EarningsService();

  String _selectedPeriod = 'Today';
  List<EarningsModel> _currentEarnings = [];
  EarningsSummaryData? _currentSummary;
  bool _isLoading = true;

  final String _driverId = 'current_driver'; // This should come from auth

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEarningsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEarningsData() async {
    setState(() => _isLoading = true);

    try {
      List<EarningsModel> earnings;
      switch (_selectedPeriod) {
        case 'Today':
          earnings = _earningsService.getTodayEarnings(_driverId);
          break;
        case 'Week':
          earnings = _earningsService.getWeekEarnings(_driverId);
          break;
        case 'Month':
          earnings = _earningsService.getMonthEarnings(_driverId);
          break;
        default:
          earnings = _earningsService.getTodayEarnings(_driverId);
      }

      final summary = _earningsService.calculateSummary(earnings);

      setState(() {
        _currentEarnings = earnings;
        _currentSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to load earnings data');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.driver != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(
                kToolbarHeight + kTextTabBarHeight,
              ),
              child: Column(
                children: [
                  CustomAppBar(
                    title: '💰 Earnings',
                    driver: widget.driver!,
                    additionalActions: [
                      PopupMenuButton<String>(
                        onSelected: (period) {
                          setState(() => _selectedPeriod = period);
                          _loadEarningsData();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'Today',
                            child: Text('Today'),
                          ),
                          const PopupMenuItem(
                            value: 'Week',
                            child: Text('This Week'),
                          ),
                          const PopupMenuItem(
                            value: 'Month',
                            child: Text('This Month'),
                          ),
                          const PopupMenuItem(
                            value: 'Year',
                            child: Text('This Year'),
                          ),
                        ],
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedPeriod),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ],
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Analytics'),
                      Tab(text: 'History'),
                      Tab(text: 'Tax Report'),
                    ],
                  ),
                ],
              ),
            )
          : AppBar(
              title: const Text('💰 Earnings'),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'History'),
                  Tab(text: 'Tax Report'),
                ],
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (period) {
                    setState(() => _selectedPeriod = period);
                    _loadEarningsData();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Today', child: Text('Today')),
                    const PopupMenuItem(
                      value: 'Week',
                      child: Text('This Week'),
                    ),
                    const PopupMenuItem(
                      value: 'Month',
                      child: Text('This Month'),
                    ),
                    const PopupMenuItem(
                      value: 'Year',
                      child: Text('This Year'),
                    ),
                  ],
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedPeriod),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAnalyticsTab(),
                _buildHistoryTab(),
                _buildTaxReportTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadEarningsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100, // Extra padding to ensure content is not hidden by bottom nav
        ),
        child: Column(
          children: [
            _buildEarningsSummaryCard(),
            const SizedBox(height: 16),
            _buildQuickStatsGrid(),
            const SizedBox(height: 16),
            _buildRecentEarningsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSummaryCard() {
    if (_currentSummary == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No earnings data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Total Earnings ($_selectedPeriod)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${_currentSummary!.totalEarnings.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Net Earnings',
                  '\$${_currentSummary!.netEarnings.toStringAsFixed(2)}',
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Platform Fees',
                  '\$${_currentSummary!.platformFees.toStringAsFixed(2)}',
                  Colors.orange,
                ),
                _buildSummaryItem(
                  'Tips',
                  '\$${_currentSummary!.tips.toStringAsFixed(2)}',
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildQuickStatsGrid() {
    if (_currentSummary == null) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Rides',
          _currentSummary!.totalRides.toString(),
          Icons.directions_car,
          Colors.blue,
        ),
        _buildStatCard(
          'Distance',
          '${_currentSummary!.totalDistance.toStringAsFixed(1)} km',
          Icons.straighten,
          Colors.purple,
        ),
        _buildStatCard(
          'Time Online',
          '${(_currentSummary!.totalTimeMinutes / 60).toStringAsFixed(1)} hrs',
          Icons.access_time,
          Colors.orange,
        ),
        _buildStatCard(
          'Avg/Ride',
          '\$${_currentSummary!.avgEarningsPerRide.toStringAsFixed(2)}',
          Icons.monetization_on,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEarningsCard() {
    if (_currentEarnings.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No recent earnings')),
        ),
      );
    }

    final recentEarnings = _currentEarnings.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Rides',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...recentEarnings.map((earning) => _buildEarningItem(earning)),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningItem(EarningsModel earning) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor(
                earning.paymentStatus,
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPaymentStatusIcon(earning.paymentStatus),
              color: _getPaymentStatusColor(earning.paymentStatus),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earning.customerName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${earning.pickupAddress} → ${earning.dropAddress}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${earning.distance.toStringAsFixed(1)} km • ${earning.duration} min',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${earning.netEarnings.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                _formatDateTime(earning.earnedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100, // Extra padding to ensure content is not hidden by bottom nav
      ),
      child: Column(
        children: [
          _buildEarningsChart(),
          const SizedBox(height: 16),
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildEarningsChart() {
    final dailySummaries = _earningsService.getDailySummaries(_driverId, 7);

    if (dailySummaries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No earnings data available for the last 7 days'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Earnings (Last 7 Days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...dailySummaries.map((summary) => _buildDailySummaryRow(summary)),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryRow(EarningsSummary summary) {
    final dayName = _getDayName(summary.date.weekday);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              dayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: math.min(
                  summary.netEarnings / 200,
                  1.0,
                ), // Max $200 for scale
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '\$${summary.netEarnings.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Widget _buildPerformanceMetrics() {
    if (_currentSummary == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Earnings per Hour',
              '\$${_currentSummary!.avgEarningsPerHour.toStringAsFixed(2)}',
            ),
            _buildMetricRow(
              'Earnings per Kilometer',
              '\$${_currentSummary!.avgEarningsPerKm.toStringAsFixed(2)}',
            ),
            _buildMetricRow(
              'Earnings per Ride',
              '\$${_currentSummary!.avgEarningsPerRide.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _currentEarnings.length,
      itemBuilder: (context, index) {
        final earning = _currentEarnings[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      earning.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '\$${earning.netEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  earning.pickupAddress,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  earning.dropAddress,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${earning.distance.toStringAsFixed(1)} km'),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${earning.duration} min'),
                    const Spacer(),
                    Text(_formatDateTime(earning.earnedAt)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildEarningsBreakdown(earning),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEarningsBreakdown(EarningsModel earning) {
    return Column(
      children: [
        const Divider(),
        _buildBreakdownRow('Base Fare', earning.baseFare),
        _buildBreakdownRow('Distance Fare', earning.distanceFare),
        _buildBreakdownRow('Time Fare', earning.timeFare),
        if (earning.surgeFare > 0)
          _buildBreakdownRow('Surge', earning.surgeFare),
        if (earning.tips > 0) _buildBreakdownRow('Tips', earning.tips),
        if (earning.tolls > 0) _buildBreakdownRow('Tolls', earning.tolls),
        const Divider(),
        _buildBreakdownRow('Total Fare', earning.totalFare, isTotal: true),
        _buildBreakdownRow(
          'Platform Fee',
          -earning.platformFee,
          isNegative: true,
        ),
        const Divider(),
        _buildBreakdownRow(
          'Net Earnings',
          earning.netEarnings,
          isTotal: true,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isNegative = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isNegative ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100, // Extra padding to ensure content is not hidden by bottom nav
      ),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tax Year 2024',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildTaxSummary(),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Download Tax Report',
                    onPressed: _downloadTaxReport,
                    icon: Icons.download,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tax Tips',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildTaxTip('Keep track of vehicle expenses for deductions'),
                  _buildTaxTip('Record business miles driven'),
                  _buildTaxTip(
                    'Save receipts for gas, maintenance, and insurance',
                  ),
                  _buildTaxTip('Consider quarterly estimated tax payments'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxSummary() {
    final taxReport = _earningsService.generateTaxReport(
      _driverId,
      DateTime.now().year,
    );

    return Column(
      children: [
        _buildTaxRow(
          'Total Earnings',
          '\$${taxReport['totalEarnings'].toStringAsFixed(2)}',
        ),
        _buildTaxRow(
          'Net Earnings',
          '\$${taxReport['netEarnings'].toStringAsFixed(2)}',
        ),
        _buildTaxRow(
          'Platform Fees',
          '\$${taxReport['platformFees'].toStringAsFixed(2)}',
        ),
        _buildTaxRow('Total Rides', '${taxReport['totalRides']}'),
        _buildTaxRow(
          'Total Distance',
          '${taxReport['totalDistance'].toStringAsFixed(1)} km',
        ),
        _buildTaxRow(
          'Total Hours',
          '${taxReport['totalHours'].toStringAsFixed(1)}',
        ),
      ],
    );
  }

  Widget _buildTaxRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTaxTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }

  void _downloadTaxReport() {
    // Implement tax report download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tax report downloaded successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
