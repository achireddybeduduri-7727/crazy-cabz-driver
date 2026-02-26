import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/safety_tips_card.dart';
import '../../../../shared/models/ride_model.dart';
import '../../../../shared/models/driver_model.dart';
import '../../../../core/theme/app_theme.dart';

import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class DashboardScreen extends StatefulWidget {
  final DriverModel driver;

  const DashboardScreen({super.key, required this.driver});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardBloc _dashboardBloc;

  @override
  void initState() {
    super.initState();
    _dashboardBloc = BlocProvider.of<DashboardBloc>(context);
    // Temporarily disabled API calls to prevent errors while backend is unavailable
    // _dashboardBloc.add(LoadDashboardData(widget.driver.id));
    print(
      '✅ Dashboard loaded successfully for driver: ${widget.driver.fullName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.driver.profilePhotoUrl != null
                  ? NetworkImage(widget.driver.profilePhotoUrl!)
                  : null,
              child: widget.driver.profilePhotoUrl == null
                  ? Text(_getInitials())
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${_getFirstName()}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  _getGreeting(),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            onPressed: () {
              _dashboardBloc.add(RefreshDashboard(widget.driver.id));
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/profile',
                arguments: widget.driver,
              );
            },
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is DashboardStatusUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: state.isOnline ? Colors.green : Colors.orange,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const LoadingOverlay(
              isLoading: true,
              child: SizedBox.expand(),
            );
          }

          if (state is DashboardStatusUpdating) {
            return LoadingOverlay(
              isLoading: true,
              loadingText: state.isGoingOnline
                  ? 'Going online...'
                  : 'Going offline...',
              child: const SizedBox.expand(),
            );
          }

          if (state is DashboardLoaded) {
            return _buildDashboard(state);
          }

          return _buildWelcomeScreen();
        },
      ),
    );
  }

  Widget _buildDashboard(DashboardLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        _dashboardBloc.add(RefreshDashboard(widget.driver.id));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Online Status Toggle
            _buildOnlineStatusCard(state),
            const SizedBox(height: 16),

            // Active Ride Card (if any)
            if (state.activeRide != null) ...[
              _buildActiveRideCard(state.activeRide!),
              const SizedBox(height: 16),
            ],

            // Today's Stats
            _buildTodayStatsCards(state.stats),
            const SizedBox(height: 16),

            // Quick Actions
            _buildQuickActions(state.activeRide != null),
            const SizedBox(height: 16),

            // Recent Rides
            _buildRecentRides(state.recentRides),
            const SizedBox(height: 16),

            // Performance Summary
            _buildPerformanceSummary(state.stats),
            const SizedBox(height: 16),

            // Safety Tips
            const SafetyTipsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineStatusCard(DashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: state.isDriverOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.isDriverOnline ? 'You\'re Online' : 'You\'re Offline',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    state.isDriverOnline
                        ? 'Available for rides'
                        : 'Not accepting rides',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Switch(
              value: state.isDriverOnline,
              onChanged: (value) {
                if (value) {
                  _dashboardBloc.add(
                    UpdateDriverStatusOnline(widget.driver.id),
                  );
                } else {
                  _dashboardBloc.add(
                    UpdateDriverStatusOffline(widget.driver.id),
                  );
                }
              },
              activeThumbColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRideCard(RideModel ride) {
    return Card(
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Active Ride',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ride.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(ride.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Customer: ${ride.employeeName}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Pickup: ${ride.pickupLocation.address}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Go to Ride',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/rides',
                  arguments: widget.driver.id,
                );
              },
              height: 40,
              backgroundColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatsCards(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Summary',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Rides',
                value: stats.todayRides.toString(),
                icon: Icons.directions_car,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Earnings',
                value: '\$${stats.todayEarnings.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Online Time',
                value: _formatOnlineTime(stats.onlineTime),
                icon: Icons.access_time,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Rating',
                value: stats.rating.toStringAsFixed(1),
                icon: Icons.star,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool hasActiveRide) {
    final actions = hasActiveRide
        ? [
            {
              'title': 'Current Ride',
              'icon': Icons.car_rental,
              'route': '/rides',
              'color': Colors.green,
            },
            {
              'title': 'Navigation',
              'icon': Icons.navigation,
              'route': '/navigation',
              'color': Colors.blue,
            },
            {
              'title': 'Emergency',
              'icon': Icons.emergency,
              'route': '/emergency',
              'color': Colors.red,
            },
          ]
        : [
            {
              'title': 'Communication',
              'icon': Icons.chat,
              'route': '/communication',
              'color': Colors.blue,
            },
            {
              'title': 'Activities',
              'icon': Icons.history,
              'route': '/history',
              'color': Colors.purple,
            },
            {
              'title': 'Earnings',
              'icon': Icons.account_balance_wallet,
              'route': '/earnings',
              'color': Colors.green,
            },
            {
              'title': 'Support',
              'icon': Icons.support_agent,
              'route': '/support',
              'color': Colors.orange,
            },
            {
              'title': 'Settings',
              'icon': Icons.settings,
              'route': '/settings',
              'color': Colors.grey,
            },
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: hasActiveRide ? 3 : 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              title: action['title'] as String,
              icon: action['icon'] as IconData,
              color: action['color'] as Color,
              onTap: () {
                final route = action['route'] as String;
                if (route == '/rides') {
                  Navigator.pushNamed(
                    context,
                    route,
                    arguments: widget.driver.id,
                  );
                } else {
                  Navigator.pushNamed(context, route);
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRides(List<RideModel> rides) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Rides',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/history');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (rides.isEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No recent rides',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return _buildRideListItem(ride);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRideListItem(RideModel ride) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(ride.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.directions_car,
            color: _getStatusColor(ride.status),
            size: 20,
          ),
        ),
        title: Text(ride.employeeName),
        subtitle: Text(
          ride.pickupLocation.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${ride.fare.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              _formatTime(ride.createdAt),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary(DashboardStats stats) {
    final completionRate = _calculateCompletionRate(
      stats.completedRides,
      stats.totalRides,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${completionRate.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                      const Text('Completion Rate'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        stats.totalRides.toString(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                      ),
                      const Text('Total Rides'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '\$${stats.totalEarnings.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                      ),
                      const Text('Total Earnings'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getPerformanceMessage(completionRate),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Welcome to Dashboard',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Your driver dashboard is ready',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getFirstName() {
    // Safe method to get first name avoiding range errors
    if (widget.driver.fullName.isEmpty) {
      return 'Driver';
    }
    final nameParts = widget.driver.fullName.split(' ');
    return nameParts.isNotEmpty ? nameParts[0] : 'Driver';
  }

  String _getInitials() {
    // Safe method to get initials avoiding range errors
    if (widget.driver.fullName.isEmpty) {
      return 'D';
    }
    return widget.driver.fullName[0].toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'enRoute':
        return Colors.orange;
      case 'arrived':
        return Colors.purple;
      case 'inProgress':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'assigned':
        return 'ASSIGNED';
      case 'enRoute':
        return 'EN ROUTE';
      case 'arrived':
        return 'ARRIVED';
      case 'inProgress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatOnlineTime(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  double _calculateCompletionRate(int completed, int total) {
    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }

  String _getPerformanceMessage(double completionRate) {
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
}
